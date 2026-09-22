#Requires -Version 5.1
<#
.SYNOPSIS
    Parses a 2Pint DeployR client log (DeployR.log) and reports deployment timing metrics.

.DESCRIPTION
    Get-DeployRMetrics reads a DeployR.log file (or a zipped log bundle containing one) and
    returns the timings that matter when benchmarking an OS deployment:

        OS content download time        Acquiring the OS content for the Apply OS step
        WIM applied to disk time        Execution time of the Apply OS step itself
        Driver package download time    Acquiring the driver content for the driver step
        Inject drivers time             Execution time of the driver step
        Enable BranchCache time         Execution time of the Enable BranchCache step
        Seed local cache time           The cache seeding window inside the BranchCache step
        Total WinPE time                Time in WinPE, from client start until the reboot out of WinPE
        Total deployment time           First log entry to task sequence completion

    Content acquisition is split into its two real parts. Download time is the figure the DeployR
    client reports itself ('Elapsed time' with its matching 'Speed'), and expand time is the WIM
    extraction that follows. The headline download metric is the sum of the two, because that is
    the wall clock the task sequence actually spends before the step can start.

    Step matching uses wildcards, so a task sequence that injects drivers with a step called
    'Inject driver pack' is picked up by the default pattern. When more than one matching step
    executes, their times are added together and the individual steps are listed in the output.

    Clock correction:
    WinPE often starts with the hardware clock read as UTC and then corrects itself once the
    network is up and time sync runs. That shows up as a jump of a whole timezone offset in the
    first seconds of the log, and it makes a one hour deployment look like a six hour deployment.
    The script detects a jump that lands within a few seconds of a whole 15 minute multiple before
    the task sequence starts, rebases the earlier entries, and reports what it did. Use
    -NoClockCorrection to disable this.

.PARAMETER Path
    One or more DeployR.log files, or .zip log bundles containing DeployR.log. Accepts pipeline
    input from Get-ChildItem.

.PARAMETER ApplyOSStep
    Name of the Apply OS step. Wildcards supported. Default: 'Apply OS'.

.PARAMETER InjectDriversStep
    Name of the driver step. Wildcards supported. Default: 'Inject driver*', which covers both
    'Inject drivers' and 'Inject driver pack'.

.PARAMETER BranchCacheStep
    Name of the BranchCache step. Wildcards supported. Default: 'Enable BranchCache'.

.PARAMETER ExtraStep
    Additional step names to time. Wildcards supported. Each match is reported separately.

.PARAMETER Summary
    Write a formatted report to the console in addition to emitting the metrics object.

.PARAMETER Detailed
    Also print every executed step and every content download, longest first.

.PARAMETER NoClockCorrection
    Do not attempt to detect and correct the WinPE clock jump.

.PARAMETER ClockToleranceSeconds
    How close a time jump must be to a whole 15 minute boundary to be treated as a clock
    correction rather than real elapsed time. Default: 5.

.PARAMETER CsvPath
    Append the metrics to a CSV file. Useful for benchmarking a batch of machines.

.PARAMETER JsonPath
    Write the full result, including all steps and downloads, to a JSON file.

.EXAMPLE
    .\Get-DeployRMetrics.ps1 -Path .\DeployR.log -Summary

.EXAMPLE
    .\Get-DeployRMetrics.ps1 -Path .\20260920_170006_2PS-R020-002.zip -Summary -Detailed

.EXAMPLE
    Get-ChildItem \\server\logs\*.zip | .\Get-DeployRMetrics.ps1 -CsvPath .\benchmark.csv

.EXAMPLE
    .\Get-DeployRMetrics.ps1 -Path .\DeployR.log -ExtraStep 'Install multiple applications' -Summary

.NOTES
    Author : Johan Arwidmark
    Works against DeployR client logs in CMTrace format. PowerShell 5.1 and later.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias('FullName', 'PSPath')]
    [string[]]$Path,

    [string]$ApplyOSStep = 'Apply OS',
    [string]$InjectDriversStep = 'Inject driver*',
    [string]$BranchCacheStep = 'Enable BranchCache',
    [string[]]$ExtraStep,

    [switch]$Summary,
    [switch]$Detailed,
    [switch]$NoClockCorrection,
    [int]$ClockToleranceSeconds = 5,

    [string]$CsvPath,
    [string]$JsonPath
)

begin {

    #region Helpers

    function Format-Duration {
        param([object]$Duration)

        if ($null -eq $Duration) { return 'n/a' }
        $ts = [TimeSpan]$Duration

        # Floor, not cast. A PowerShell [int] cast rounds, which would turn 4m 37s into 5m 37s.
        if ($ts.TotalHours -ge 1) {
            return ('{0}h {1:00}m {2:00}s' -f [int][math]::Floor($ts.TotalHours), $ts.Minutes, $ts.Seconds)
        }
        if ($ts.TotalMinutes -ge 1) {
            return ('{0}m {1:00}s' -f [int][math]::Floor($ts.TotalMinutes), $ts.Seconds)
        }
        return ('{0:0.000}s' -f $ts.TotalSeconds)
    }

    function Format-Bytes {
        param([object]$Bytes)

        if ($null -eq $Bytes) { return 'n/a' }
        if ($Bytes -eq 0) { return '0 B' }
        $b = [double]$Bytes
        foreach ($unit in 'B', 'KB', 'MB', 'GB', 'TB') {
            if ($b -lt 1024 -or $unit -eq 'TB') { return ('{0:N2} {1}' -f $b, $unit) }
            $b = $b / 1024
        }
    }

    function Get-Guid36 {
        param([string]$Text)
        if ($Text -match '(?<id>[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
            return $Matches['id'].ToLower()
        }
        return $null
    }

    function ConvertFrom-CMTraceLog {
        <#  Turns a CMTrace formatted log into entry objects. #>
        param([string]$LogFile)

        $raw = Get-Content -LiteralPath $LogFile -Raw -ErrorAction Stop

        $pattern = '<!\[LOG\[(?<msg>.*?)\]LOG\]!><time="(?<time>\d{2}:\d{2}:\d{2}\.\d{3})(?<offset>[+-]\d+)"\s+date="(?<date>\d{2}-\d{2}-\d{4})"\s+component="(?<comp>[^"]*)"(?:\s+context="[^"]*")?(?:\s+type="(?<type>\d+)")?(?:\s+thread="(?<thread>\d+)")?(?:\s+file="(?<file>[^"]*)")?'
        $rx = New-Object System.Text.RegularExpressions.Regex(
            $pattern,
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )

        $entries = New-Object System.Collections.Generic.List[object]
        $index = 0

        foreach ($m in $rx.Matches($raw)) {
            $stamp = [datetime]::ParseExact(
                ('{0} {1}' -f $m.Groups['date'].Value, $m.Groups['time'].Value),
                'MM-dd-yyyy HH:mm:ss.fff',
                [System.Globalization.CultureInfo]::InvariantCulture
            )

            $entries.Add([pscustomobject]@{
                Index     = $index++
                Time      = $stamp
                RawTime   = $stamp
                Offset    = $m.Groups['offset'].Value
                Component = $m.Groups['comp'].Value
                Message   = $m.Groups['msg'].Value.Trim()
                File      = $m.Groups['file'].Value
                Type      = $(if ($m.Groups['type'].Success) { [int]$m.Groups['type'].Value } else { 1 })
                Phase     = 'Unknown'
                Session   = 0
            })
        }

        return $entries
    }

    function Repair-DeployRClockSkew {
        <#
            WinPE can log with an uncorrected hardware clock until time sync runs. The correction
            shows up as a jump of a whole timezone offset before the task sequence starts. Rebase
            everything before the jump so elapsed time is real.
        #>
        param(
            [System.Collections.Generic.List[object]]$Entries,
            [int]$ToleranceSeconds = 5
        )

        $info = [pscustomobject]@{
            Applied      = $false
            Offset       = [TimeSpan]::Zero
            DetectedAt   = $null
            AffectedRows = 0
        }

        if ($Entries.Count -lt 2) { return $info }

        # Only inspect the window before the task sequence starts. That is where time sync happens,
        # and it keeps a genuinely long step from being mistaken for a clock jump.
        $limit = $Entries.Count
        $tsStart = $Entries | Where-Object { $_.Message -like '*Task Sequence Start*' } | Select-Object -First 1
        if ($tsStart) { $limit = $tsStart.Index }

        for ($i = 1; $i -lt $limit; $i++) {
            $gap = ($Entries[$i].Time - $Entries[$i - 1].Time).TotalSeconds
            if ([math]::Abs($gap) -lt 60) { continue }

            # A timezone offset is always a whole 15 minute multiple. A human sitting at the UI is not.
            $remainder = [math]::Abs($gap) % 900
            if ($remainder -le $ToleranceSeconds -or (900 - $remainder) -le $ToleranceSeconds) {
                $skew = [math]::Round($gap / 900.0) * 900
                for ($j = 0; $j -lt $i; $j++) {
                    $Entries[$j].Time = $Entries[$j].Time.AddSeconds($skew)
                }
                $info.Applied      = $true
                $info.Offset       = [TimeSpan]::FromSeconds($skew)
                $info.DetectedAt   = $Entries[$i].Time
                $info.AffectedRows = $i
                break
            }
        }

        return $info
    }

    function Set-DeployRSession {
        <#  Tags each entry with a client session number and the phase it ran in. #>
        param([System.Collections.Generic.List[object]]$Entries)

        # A new client session starts when DEPLOYRROOT is set from an empty value, or when the
        # task sequence state is first evaluated.
        $anchors = New-Object System.Collections.Generic.List[int]
        $anchors.Add(0)

        foreach ($e in $Entries) {
            if ($e.Index -eq 0) { continue }
            if ($e.Message -match "^Setting DEPLOYRROOT = '[^']+' \(\w+\), was ''$" -or
                $e.Message -match '^(No existing|Existing) task sequence found') {
                # Collapse anchors that belong to the same startup burst.
                if ($anchors[$anchors.Count - 1] -lt ($e.Index - 10)) { $anchors.Add($e.Index) }
            }
        }

        for ($s = 0; $s -lt $anchors.Count; $s++) {
            $from = $anchors[$s]
            if ($s -lt $anchors.Count - 1) { $to = $anchors[$s + 1] - 1 } else { $to = $Entries.Count - 1 }

            $slice = $Entries[$from..$to]

            $isWinPE = $false
            foreach ($e in $slice) {
                if ($e.Message -match 'Windows PE version' -or
                    $e.Message -match 'Initializing networking in Windows PE' -or
                    $e.Message -match "^Setting DEPLOYRROOT = 'X:") {
                    $isWinPE = $true
                    break
                }
            }
            if (-not $isWinPE) {
                $logPath = $slice | Where-Object { $_.Message -match '^Log path:\s*(?<p>\S+)' } | Select-Object -First 1
                if ($logPath -and $logPath.Message -match '^Log path:\s*[Xx]:') { $isWinPE = $true }
            }

            foreach ($e in $slice) {
                $e.Session = $s + 1
                if ($isWinPE) { $e.Phase = 'WinPE' } else { $e.Phase = 'FullOS' }
            }
        }
    }

    function Get-ContentAcquisition {
        <#
            Builds one record per content item the client acquired, across the whole log.

            A single acquisition looks like this, and only some of the lines carry the content
            GUID, so the download detail is attached to the acquisition that is currently open:

                Requesting content <guid>:1
                Starting download to file ...\<guid>.wim
                  Source: Http  Segments: 42827  Total data: 3315778604
                Content downloaded 3315778604 bytes successfully.
                  From local cache: 0
                  From peers: 0
                  Efficiency: 0%
                  Elapsed time: 00:01:01.5194574
                  Speed: 411.2Mbs
                Content <guid>:1 downloaded to ...
                Content <guid>:1 extracted to ...
                Setting local variable _CONTENT-DriverPack to ...
        #>
        param([System.Collections.Generic.List[object]]$Entries)

        $all  = New-Object System.Collections.Generic.List[object]
        $open = @{}
        $openOrder = New-Object System.Collections.Generic.List[object]

        foreach ($e in $Entries) {
            $msg = $e.Message

            if ($msg -match '^Requesting content (?<id>[0-9a-fA-F-]{36}):(?<ver>\d+)') {
                $id = $Matches['id'].ToLower()
                if ($open.ContainsKey($id)) { continue }

                $rec = [pscustomobject]@{
                    ContentId       = $id
                    Version         = $Matches['ver']
                    Variable        = $null
                    Name            = $null
                    RequestTime     = $e.Time
                    DownloadStart   = $null
                    DownloadedTime  = $null
                    ExtractedTime   = $null
                    ResolvedTime    = $null
                    Bytes           = $null
                    DownloadElapsed = $null
                    SpeedMbps       = $null
                    FromLocalCache  = $null
                    FromPeers       = $null
                    EfficiencyPct   = $null
                    Sources         = @()
                    ServedFromCache = $false
                    AcquireTime     = $null
                    ExpandTime      = $null
                }
                $open[$id] = $rec
                $openOrder.Add($rec)
                $all.Add($rec)
                continue
            }

            if ($msg -match '^Cached content (?<id>[0-9a-fA-F-]{36}):(?<ver>\d+) found at local path') {
                $id = $Matches['id'].ToLower()
                if ($open.ContainsKey($id)) { $open[$id].ServedFromCache = $true }
                continue
            }

            if ($msg -match '^Starting download to file (?<p>.+)$') {
                $id = Get-Guid36 -Text $Matches['p']
                if ($id -and $open.ContainsKey($id)) { $open[$id].DownloadStart = $e.Time }
                continue
            }

            # The download summary block carries no GUID, so it belongs to the newest open request.
            if ($msg -match '^Content downloaded (?<b>\d+) bytes successfully') {
                $rec = $openOrder | Select-Object -Last 1
                if ($rec) { $rec.Bytes = [int64]$Matches['b'] }
                continue
            }
            if ($msg -match '^Elapsed time:\s*(?<el>[\d:.]+)$') {
                $rec = $openOrder | Select-Object -Last 1
                if ($rec) { $rec.DownloadElapsed = [TimeSpan]::Parse($Matches['el']) }
                continue
            }
            if ($msg -match '^Speed:\s*(?<s>[\d.]+)\s*Mbs') {
                $rec = $openOrder | Select-Object -Last 1
                if ($rec) { $rec.SpeedMbps = [double]$Matches['s'] }
                continue
            }
            if ($msg -match '^From local cache:\s*(?<v>\d+)$') {
                $rec = $openOrder | Select-Object -Last 1
                if ($rec) { $rec.FromLocalCache = [int64]$Matches['v'] }
                continue
            }
            if ($msg -match '^From peers:\s*(?<v>\d+)$') {
                $rec = $openOrder | Select-Object -Last 1
                if ($rec) { $rec.FromPeers = [int64]$Matches['v'] }
                continue
            }
            if ($msg -match '^Efficiency:\s*(?<v>\d+)%$') {
                $rec = $openOrder | Select-Object -Last 1
                if ($rec) { $rec.EfficiencyPct = [int]$Matches['v'] }
                continue
            }
            if ($e.Component -eq 'AvailabilityCompleteLog' -and
                $msg -match '^Source:\s*(?<src>\S+)\s+Segments:\s*(?<seg>\d+)\s+Total data:\s*(?<bytes>\d+)') {
                $rec = $openOrder | Select-Object -Last 1
                if ($rec) {
                    $rec.Sources += ('{0}: {1}' -f $Matches['src'], (Format-Bytes ([int64]$Matches['bytes'])))
                }
                continue
            }

            if ($msg -match '^Content (?<id>[0-9a-fA-F-]{36}):(?<ver>\d+) downloaded to') {
                $id = $Matches['id'].ToLower()
                if ($open.ContainsKey($id)) { $open[$id].DownloadedTime = $e.Time }
                continue
            }

            if ($msg -match '^Content (?<id>[0-9a-fA-F-]{36}):(?<ver>\d+) extracted to') {
                $id = $Matches['id'].ToLower()
                if ($open.ContainsKey($id)) {
                    $rec = $open[$id]
                    $rec.ExtractedTime = $e.Time
                    if ($rec.DownloadedTime) { $rec.ExpandTime = $rec.ExtractedTime - $rec.DownloadedTime }
                }
                continue
            }

            # Content bound to a task sequence variable closes the acquisition.
            if ($msg -match '^Setting local variable _CONTENT-(?<name>\S+) to (?<path>.+)$') {
                $varName = $Matches['name']
                $id = Get-Guid36 -Text $Matches['path']
                if ($id -and $open.ContainsKey($id)) {
                    $rec = $open[$id]
                    $rec.Variable     = $varName
                    $rec.ResolvedTime = $e.Time
                    $rec.AcquireTime  = $e.Time - $rec.RequestTime
                    $open.Remove($id)
                    [void]$openOrder.Remove($rec)
                }
                continue
            }

            # Friendly name from the content metadata, when DeployR emits it.
            if ($msg -match '^Setting _CONTENTMETADATA-(?<var>\S+) = ''\{"Id":"(?<id>[0-9a-fA-F-]{36})","Name":"(?<n>[^"]*)"') {
                $id = $Matches['id'].ToLower()
                $name = $Matches['n']
                $hit = $all | Where-Object { $_.ContentId -eq $id } | Select-Object -Last 1
                if ($hit -and -not $hit.Name) { $hit.Name = $name }
                continue
            }
        }

        # Acquisitions that never bound to a variable still finished when the content was extracted.
        foreach ($rec in $all) {
            if (-not $rec.AcquireTime) {
                $finish = $rec.ExtractedTime
                if (-not $finish) { $finish = $rec.DownloadedTime }
                if ($finish) { $rec.AcquireTime = $finish - $rec.RequestTime }
            }
        }

        return $all
    }

    function Get-DeployRStep {
        <#
            Walks the step markers and returns one object per step that actually executed.
            Steps that are only re-initialized after a reboot (already done, or skipped by a
            condition) never emit a Step Start, so they are dropped.
        #>
        param([System.Collections.Generic.List[object]]$Entries)

        $steps   = New-Object System.Collections.Generic.List[object]
        $current = $null

        foreach ($e in $Entries) {

            if ($e.Message -match '^Initializing step Name=(?<name>.+?) ID=(?<id>[0-9a-fA-F-]{36})\s*$') {
                $current = [pscustomobject]@{
                    Name            = $Matches['name']
                    Id              = $Matches['id']
                    FullPath        = $null
                    Phase           = $e.Phase
                    Session         = $e.Session
                    InitTime        = $e.Time
                    StartTime       = $null
                    ResultTime      = $null
                    EndTime         = $null
                    Result          = $null
                    ScriptName      = $null
                    ScriptElapsed   = $null
                    ExitCode        = $null
                    RequestedReboot = $false
                    PrepTime        = $null
                    ExecTime        = $null
                    TotalTime       = $null
                    Content         = @()
                }
                continue
            }

            if ($null -eq $current) { continue }

            if ($e.Component -eq 'ExecuteSteps' -and $e.Message -match '^Executing (?<full>.+)$') {
                $current.FullPath = $Matches['full']
                continue
            }

            if ($e.Message -match "^Setting SCRIPTNAME = '(?<s>[^']+)'") {
                $current.ScriptName = $Matches['s']
                continue
            }

            if ($e.Message -match '^-{4,}\s*Step Start\s*-{4,}$') {
                $current.StartTime = $e.Time
                continue
            }

            if ($e.Message -match '^Script executed, exit code = (?<rc>-?\d+), elapsed = (?<el>[\d:.]+)$') {
                if ($current.StartTime) {
                    $current.ExitCode = [int]$Matches['rc']
                    $current.ScriptElapsed = [TimeSpan]::Parse($Matches['el'])
                }
                continue
            }

            if ($e.Message -eq 'Step requested a reboot.') {
                if ($current.StartTime) { $current.RequestedReboot = $true }
                continue
            }

            if ($e.Message -match '^Step result: (?<r>\w+)$') {
                if ($current.StartTime -and -not $current.ResultTime) {
                    $current.Result = $Matches['r']
                    $current.ResultTime = $e.Time
                }
                continue
            }

            if ($e.Message -match '^-{4,}\s*Step End\s*-{4,}$') {
                if ($current.StartTime) {
                    $current.EndTime = $e.Time
                    $end = $current.ResultTime
                    if (-not $end) { $end = $current.EndTime }

                    $current.PrepTime  = $current.StartTime - $current.InitTime
                    $current.ExecTime  = $end - $current.StartTime
                    $current.TotalTime = $end - $current.InitTime

                    $steps.Add($current)
                    $current = $null
                }
                continue
            }
        }

        return $steps
    }

    function Add-StepContent {
        <#  Attaches each content acquisition to the step that requested it. #>
        param(
            [System.Collections.Generic.List[object]]$Steps,
            [System.Collections.Generic.List[object]]$Acquisitions
        )

        foreach ($step in $Steps) {
            $windowEnd = $step.ResultTime
            if (-not $windowEnd) { $windowEnd = $step.EndTime }
            if (-not $windowEnd) { continue }

            $step.Content = @(
                $Acquisitions | Where-Object {
                    $_.RequestTime -ge $step.InitTime -and $_.RequestTime -le $windowEnd
                }
            )
        }
    }

    function Select-StepContent {
        <#
            Picks the content acquisition that represents a step's real payload. Prefers a content
            variable matching the hint (_CONTENT-OS, _CONTENT-DriverPack), otherwise takes the
            slowest acquisition, which skips the tiny cached 'DeployR Windows content' every step
            touches.
        #>
        param(
            [object[]]$Steps,
            [string]$VariableHint
        )

        $candidates = @()
        foreach ($s in $Steps) {
            if ($s.Content) { $candidates += $s.Content }
        }
        if (-not $candidates) { return $null }

        if ($VariableHint) {
            $preferred = $candidates |
                Where-Object { $_.Variable -and $_.Variable -like $VariableHint } |
                Sort-Object -Property { $_.AcquireTime.Ticks } -Descending |
                Select-Object -First 1
            if ($preferred) { return $preferred }
        }

        return ($candidates |
            Where-Object { $_.AcquireTime } |
            Sort-Object -Property { $_.AcquireTime.Ticks } -Descending |
            Select-Object -First 1)
    }

    function Format-Acquisition {
        <#  One line of detail about how a content item was acquired. #>
        param([object]$Acquisition)

        if (-not $Acquisition) { return '' }

        $parts = @()
        if ($Acquisition.Bytes) { $parts += (Format-Bytes $Acquisition.Bytes) }
        if ($Acquisition.DownloadElapsed) {
            $bit = 'download {0}' -f (Format-Duration $Acquisition.DownloadElapsed)
            if ($Acquisition.ExpandTime -and $Acquisition.ExpandTime.TotalSeconds -ge 0.01) {
                $bit += ' + expand {0}' -f (Format-Duration $Acquisition.ExpandTime)
            }
            $parts += $bit
        }
        if ($Acquisition.SpeedMbps) { $parts += ('{0} Mbps' -f $Acquisition.SpeedMbps) }
        if ($Acquisition.ServedFromCache -and -not $Acquisition.Bytes) { $parts += 'already in local cache' }
        if ($Acquisition.Sources) { $parts += ('via {0}' -f ($Acquisition.Sources -join ', ')) }

        return ($parts -join ', ')
    }

    function Measure-StepSet {
        <#  Adds up execution time across every executed step matching a pattern. #>
        param([object[]]$Steps)

        if (-not $Steps -or $Steps.Count -eq 0) { return $null }
        $ticks = 0
        foreach ($s in $Steps) { if ($s.ExecTime) { $ticks += $s.ExecTime.Ticks } }
        return [TimeSpan]::FromTicks($ticks)
    }

    function Select-DeployRStep {
        param(
            [System.Collections.Generic.List[object]]$Steps,
            [string]$NamePattern
        )
        if ([string]::IsNullOrWhiteSpace($NamePattern)) { return @() }
        return @($Steps | Where-Object { $_.Name -like $NamePattern })
    }

    function Get-VariableValue {
        param(
            [System.Collections.Generic.List[object]]$Entries,
            [string]$Name
        )
        $hit = $Entries |
            Where-Object { $_.Component -eq 'SetValue' -and $_.Message -match ("^Setting {0} = '(?<v>[^']*)'" -f [regex]::Escape($Name)) } |
            Select-Object -First 1
        if ($hit -and $hit.Message -match ("^Setting {0} = '(?<v>[^']*)'" -f [regex]::Escape($Name))) {
            return $Matches['v']
        }
        return $null
    }

    function Resolve-LogFile {
        <#  Accepts a DeployR.log or a zipped log bundle and returns a usable log path. #>
        param([string]$InputPath)

        $resolved = Resolve-Path -LiteralPath $InputPath -ErrorAction Stop
        $file = Get-Item -LiteralPath $resolved.Path

        if ($file.Extension -eq '.zip') {
            $temp = Join-Path ([System.IO.Path]::GetTempPath()) ('DeployRMetrics_' + [guid]::NewGuid().ToString('N'))
            New-Item -Path $temp -ItemType Directory -Force | Out-Null
            Expand-Archive -LiteralPath $file.FullName -DestinationPath $temp -Force

            $log = Get-ChildItem -Path $temp -Filter 'DeployR.log' -Recurse -File | Select-Object -First 1
            if (-not $log) {
                Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
                throw "No DeployR.log found inside '$($file.FullName)'."
            }
            return [pscustomobject]@{ LogFile = $log.FullName; TempDir = $temp; Source = $file.FullName }
        }

        return [pscustomobject]@{ LogFile = $file.FullName; TempDir = $null; Source = $file.FullName }
    }

    #endregion Helpers

    $allResults = New-Object System.Collections.Generic.List[object]
}

process {

    foreach ($item in $Path) {

        $resolvedLog = $null

        try {
            $resolvedLog = Resolve-LogFile -InputPath $item
            Write-Verbose "Parsing $($resolvedLog.LogFile)"

            $entries = ConvertFrom-CMTraceLog -LogFile $resolvedLog.LogFile
            if ($entries.Count -eq 0) {
                Write-Warning "No CMTrace formatted entries found in '$($resolvedLog.LogFile)'. Skipping."
                continue
            }

            $skew = [pscustomobject]@{ Applied = $false; Offset = [TimeSpan]::Zero; DetectedAt = $null; AffectedRows = 0 }
            if (-not $NoClockCorrection) {
                $skew = Repair-DeployRClockSkew -Entries $entries -ToleranceSeconds $ClockToleranceSeconds
                if ($skew.Applied) {
                    Write-Verbose ("Clock correction of {0} applied to the first {1} entries." -f (Format-Duration $skew.Offset), $skew.AffectedRows)
                }
            }

            Set-DeployRSession -Entries $entries

            $acquisitions = Get-ContentAcquisition -Entries $entries
            $steps = Get-DeployRStep -Entries $entries
            Add-StepContent -Steps $steps -Acquisitions $acquisitions

            #region Named steps

            $stepsApplyOS = Select-DeployRStep -Steps $steps -NamePattern $ApplyOSStep
            $stepsDrivers = Select-DeployRStep -Steps $steps -NamePattern $InjectDriversStep
            $stepsBranchC = Select-DeployRStep -Steps $steps -NamePattern $BranchCacheStep

            $osContent     = Select-StepContent -Steps $stepsApplyOS -VariableHint '*OS*'
            $driverContent = Select-StepContent -Steps $stepsDrivers -VariableHint '*DRIVER*'

            # Headline download metric is request to ready, which is download plus expand. Fall back
            # to the step's own pre-execution window when the client logged no acquisition detail.
            $osDownload = $null
            if ($osContent) { $osDownload = $osContent.AcquireTime }
            elseif ($stepsApplyOS.Count -gt 0) { $osDownload = $stepsApplyOS[0].PrepTime }

            $driverDownload = $null
            if ($driverContent) { $driverDownload = $driverContent.AcquireTime }
            elseif ($stepsDrivers.Count -gt 0) {
                $ticks = 0
                foreach ($s in $stepsDrivers) { if ($s.PrepTime) { $ticks += $s.PrepTime.Ticks } }
                $driverDownload = [TimeSpan]::FromTicks($ticks)
            }

            # BranchCache local cache seeding, measured inside the step.
            $seedTime = $null
            $seedFailures = 0
            if ($stepsBranchC.Count -gt 0) {
                $bc = $stepsBranchC[0]
                $seedWindow = $entries | Where-Object { $_.Time -ge $bc.StartTime -and $_.Time -le $bc.ResultTime }

                $seedStart = $seedWindow |
                    Where-Object { $_.Message -match '^Storing data into BranchCache' } |
                    Select-Object -First 1

                # End on the last seeding event of any kind. Anchoring on 'Successfully added data'
                # alone would cut the window short whenever an add fails, which makes the metric
                # depend on whether seeding worked rather than on how long it took.
                $seedEnd = $seedWindow |
                    Where-Object {
                        $_.Message -match 'added data (to|from).*BranchCache' -or
                        $_.Message -match 'Adding downloaded data to BranchCache' -or
                        $_.Message -match 'Unexpected result adding data to BranchCache' -or
                        $_.Message -match '^Setting _CONTENT-WINPE'
                    } |
                    Select-Object -Last 1

                if ($seedStart -and $seedEnd) { $seedTime = $seedEnd.Time - $seedStart.Time }

                $seedFailures = @(
                    $seedWindow | Where-Object { $_.Message -match 'Unexpected result adding data to BranchCache' }
                ).Count
            }

            #endregion Named steps

            #region Phase and totals

            $winPeEntries = $entries | Where-Object { $_.Phase -eq 'WinPE' }
            $winPeTotal = $null
            $winPeSessions = @()

            if ($winPeEntries) {
                foreach ($grp in ($winPeEntries | Group-Object -Property Session)) {
                    $first = $grp.Group | Select-Object -First 1
                    $last  = $grp.Group | Select-Object -Last 1
                    $winPeSessions += [pscustomobject]@{
                        Session  = [int]$grp.Name
                        Start    = $first.Time
                        End      = $last.Time
                        Duration = $last.Time - $first.Time
                    }
                }
                $ticks = 0
                foreach ($ws in $winPeSessions) { $ticks += $ws.Duration.Ticks }
                $winPeTotal = [TimeSpan]::FromTicks($ticks)
            }

            $deployStart = ($entries | Select-Object -First 1).Time
            $completion = $entries | Where-Object { $_.Message -match '^Task sequence completed' } | Select-Object -Last 1
            if ($completion) {
                $deployEnd = $completion.Time
                $outcome = $completion.Message
            } else {
                $lastEntry = $entries | Select-Object -Last 1
                $deployEnd = $lastEntry.Time
                $outcome = 'Incomplete (no task sequence completion entry found)'
            }

            # Time the machine spent rebooting, which is wall clock the task sequence does not control.
            $rebootTime = [TimeSpan]::Zero
            $rebootCount = 0
            $sessionBounds = @()
            foreach ($grp in ($entries | Group-Object -Property Session)) {
                $sessionBounds += [pscustomobject]@{
                    Session = [int]$grp.Name
                    Start   = ($grp.Group | Select-Object -First 1).Time
                    End     = ($grp.Group | Select-Object -Last 1).Time
                }
            }
            $sessionBounds = $sessionBounds | Sort-Object Session
            for ($i = 1; $i -lt $sessionBounds.Count; $i++) {
                $rebootTime += ($sessionBounds[$i].Start - $sessionBounds[$i - 1].End)
                $rebootCount++
            }

            # Content totals as reported by the task sequence itself.
            $totalBytes = $null; $fromCache = $null; $fromPeers = $null; $efficiency = $null
            $sumEntry = $entries | Where-Object { $_.Message -match '^Content download total bytes: (?<b>\d+)' } | Select-Object -Last 1
            if ($sumEntry) {
                if ($sumEntry.Message -match '^Content download total bytes: (?<b>\d+)') { $totalBytes = [int64]$Matches['b'] }
                $idx = $sumEntry.Index
                foreach ($e in $entries[$idx..([math]::Min($idx + 5, $entries.Count - 1))]) {
                    if ($e.Message -match '^From local cache:\s*(?<v>\d+)') { $fromCache = [int64]$Matches['v'] }
                    elseif ($e.Message -match '^From peers:\s*(?<v>\d+)') { $fromPeers = [int64]$Matches['v'] }
                    elseif ($e.Message -match '^Efficiency:\s*(?<v>\d+)%') { $efficiency = [int]$Matches['v'] }
                }
            }

            #endregion Phase and totals

            $extraSteps = @()
            if ($ExtraStep) {
                foreach ($pattern in $ExtraStep) {
                    $extraSteps += (Select-DeployRStep -Steps $steps -NamePattern $pattern)
                }
            }

            $problems = @(
                $entries | Where-Object { $_.Type -ge 2 } | Select-Object Time, Type, Component, Message
            )

            $result = [pscustomobject]@{
                PSTypeName                 = 'DeployR.DeploymentMetrics'
                ComputerName               = (Get-VariableValue -Entries $entries -Name 'COMPUTERNAME')
                TaskSequence               = (Get-VariableValue -Entries $entries -Name 'DEPLOYRTASKSEQUENCENAME')
                OSImage                    = (Get-VariableValue -Entries $entries -Name 'OSIMAGENAME')
                LogFile                    = $resolvedLog.Source

                DeploymentStart            = $deployStart
                DeploymentEnd              = $deployEnd
                TotalDeploymentTime        = $deployEnd - $deployStart

                OSContentDownloadTime      = $osDownload
                WimAppliedToDiskTime       = (Measure-StepSet -Steps $stepsApplyOS)
                DriverPackageDownloadTime  = $driverDownload
                InjectDriversTime          = (Measure-StepSet -Steps $stepsDrivers)
                EnableBranchCacheTime      = (Measure-StepSet -Steps $stepsBranchC)
                SeedLocalCacheTime         = $seedTime
                SeedCacheFailures          = $seedFailures
                TotalWinPETime             = $winPeTotal

                OSContentName              = $(if ($osContent) { $osContent.Name } else { $null })
                OSContentBytes             = $(if ($osContent) { $osContent.Bytes } else { $null })
                OSContentDownloadOnly      = $(if ($osContent) { $osContent.DownloadElapsed } else { $null })
                OSContentExpandTime        = $(if ($osContent) { $osContent.ExpandTime } else { $null })
                OSContentSpeedMbps         = $(if ($osContent) { $osContent.SpeedMbps } else { $null })

                DriverContentName          = $(if ($driverContent) { $driverContent.Name } else { $null })
                DriverContentBytes         = $(if ($driverContent) { $driverContent.Bytes } else { $null })
                DriverPackageDownloadOnly  = $(if ($driverContent) { $driverContent.DownloadElapsed } else { $null })
                DriverPackageExpandTime    = $(if ($driverContent) { $driverContent.ExpandTime } else { $null })
                DriverContentSpeedMbps     = $(if ($driverContent) { $driverContent.SpeedMbps } else { $null })

                ContentTotalBytes          = $totalBytes
                ContentFromLocalCache      = $fromCache
                ContentFromPeers           = $fromPeers
                ContentEfficiencyPercent   = $efficiency

                RebootCount                = $rebootCount
                RebootTime                 = $rebootTime
                Outcome                    = $outcome
                ClockCorrectionApplied     = $skew.Applied
                ClockCorrection            = $skew.Offset

                WarningCount               = @($problems | Where-Object { $_.Type -eq 2 }).Count
                ErrorCount                 = @($problems | Where-Object { $_.Type -ge 3 }).Count
                Problems                   = $problems

                ApplyOSSteps               = $stepsApplyOS
                DriverSteps                = $stepsDrivers
                BranchCacheSteps           = $stepsBranchC
                ExtraSteps                 = $extraSteps
                WinPESessions              = $winPeSessions
                Downloads                  = $acquisitions
                Steps                      = $steps
            }

            $allResults.Add($result)

            #region Console summary

            if ($Summary) {
                $line = '-' * 100
                Write-Host ''
                Write-Host $line -ForegroundColor DarkGray
                Write-Host (' DeployR deployment metrics: {0}' -f $result.ComputerName) -ForegroundColor Cyan
                Write-Host $line -ForegroundColor DarkGray
                Write-Host (' Task sequence : {0}' -f $result.TaskSequence)
                Write-Host (' Log file      : {0}' -f $result.LogFile)
                Write-Host (' Started       : {0:yyyy-MM-dd HH:mm:ss}' -f $result.DeploymentStart)
                Write-Host (' Finished      : {0:yyyy-MM-dd HH:mm:ss}' -f $result.DeploymentEnd)
                Write-Host (' Outcome       : {0}' -f $result.Outcome)
                if ($result.ClockCorrectionApplied) {
                    Write-Host (' Note          : clock correction of {0} detected in WinPE and compensated for' -f (Format-Duration $result.ClockCorrection)) -ForegroundColor Yellow
                }
                Write-Host $line -ForegroundColor DarkGray

                $driverStepNames = ($stepsDrivers | ForEach-Object { $_.Name }) -join ', '
                $applyStepNames  = ($stepsApplyOS | ForEach-Object { $_.Name }) -join ', '

                $rows = @(
                    [pscustomobject]@{ Metric = 'OS content download';     Duration = (Format-Duration $result.OSContentDownloadTime);     Detail = (Format-Acquisition $osContent) }
                    [pscustomobject]@{ Metric = 'WIM applied to disk';     Duration = (Format-Duration $result.WimAppliedToDiskTime);      Detail = $applyStepNames }
                    [pscustomobject]@{ Metric = 'Driver package download'; Duration = (Format-Duration $result.DriverPackageDownloadTime); Detail = (Format-Acquisition $driverContent) }
                    [pscustomobject]@{ Metric = 'Inject drivers';          Duration = (Format-Duration $result.InjectDriversTime);         Detail = $driverStepNames }
                    [pscustomobject]@{ Metric = 'Enable BranchCache';      Duration = (Format-Duration $result.EnableBranchCacheTime);     Detail = '' }
                    [pscustomobject]@{ Metric = 'Seed local cache';        Duration = (Format-Duration $result.SeedLocalCacheTime);        Detail = $(if ($result.SeedCacheFailures -gt 0) { '{0} item(s) FAILED to seed' -f $result.SeedCacheFailures } else { '' }) }
                    [pscustomobject]@{ Metric = 'Total WinPE time';        Duration = (Format-Duration $result.TotalWinPETime);            Detail = '' }
                    [pscustomobject]@{ Metric = 'Reboot time';             Duration = (Format-Duration $result.RebootTime);                Detail = ('{0} reboot(s)' -f $result.RebootCount) }
                    [pscustomobject]@{ Metric = 'TOTAL DEPLOYMENT TIME';   Duration = (Format-Duration $result.TotalDeploymentTime);       Detail = '' }
                )
                foreach ($x in $result.ExtraSteps) {
                    $rows += [pscustomobject]@{ Metric = ('Step: {0}' -f $x.Name); Duration = (Format-Duration $x.TotalTime); Detail = '' }
                }
                $rows | Format-Table -AutoSize | Out-String -Width 200 | Write-Host

                if ($result.ContentTotalBytes) {
                    Write-Host (' All content   : {0} total, {1} from local cache, {2} from peers, {3}% efficiency' -f `
                        (Format-Bytes $result.ContentTotalBytes), (Format-Bytes $result.ContentFromLocalCache), (Format-Bytes $result.ContentFromPeers), $result.ContentEfficiencyPercent)
                }

                if ($result.WarningCount -gt 0 -or $result.ErrorCount -gt 0) {
                    Write-Host (' Logged        : {0} warning(s), {1} error(s){2}' -f `
                        $result.WarningCount, $result.ErrorCount, $(if (-not $Detailed) { ' (use -Detailed to list them)' } else { '' })) -ForegroundColor Yellow
                }

                if ($Detailed) {
                    if ($result.Problems.Count -gt 0) {
                        Write-Host ''
                        Write-Host ' Warnings and errors:' -ForegroundColor Yellow
                        $result.Problems |
                            Select-Object @{N = 'Time'; E = { '{0:HH:mm:ss}' -f $_.Time } },
                                          @{N = 'Level'; E = { if ($_.Type -ge 3) { 'Error' } else { 'Warning' } } },
                                          @{N = 'Component'; E = { $_.Component } },
                                          @{N = 'Message'; E = { $_.Message } } |
                            Format-Table -AutoSize | Out-String -Width 200 | Write-Host
                    }

                    Write-Host ''
                    Write-Host ' Content downloads, slowest first:' -ForegroundColor Cyan
                    $result.Downloads |
                        Where-Object { $_.AcquireTime -and ($null -ne $_.Bytes -or $_.AcquireTime.TotalSeconds -ge 0.1) } |
                        Sort-Object -Property { $_.AcquireTime.Ticks } -Descending |
                        Select-Object @{N = 'Content'; E = { if ($_.Name) { $_.Name } else { $_.ContentId } } },
                                      @{N = 'Variable'; E = { $_.Variable } },
                                      @{N = 'Size'; E = { Format-Bytes $_.Bytes } },
                                      @{N = 'Download'; E = { Format-Duration $_.DownloadElapsed } },
                                      @{N = 'Expand'; E = { Format-Duration $_.ExpandTime } },
                                      @{N = 'Total'; E = { Format-Duration $_.AcquireTime } },
                                      @{N = 'Mbps'; E = { $_.SpeedMbps } } |
                        Format-Table -AutoSize | Out-String -Width 200 | Write-Host

                    Write-Host ' All executed steps, longest first:' -ForegroundColor Cyan
                    $result.Steps |
                        Sort-Object -Property { $_.TotalTime.Ticks } -Descending |
                        Select-Object @{N = 'Phase'; E = { $_.Phase } },
                                      @{N = 'Step'; E = { $_.Name } },
                                      @{N = 'Started'; E = { '{0:HH:mm:ss}' -f $_.InitTime } },
                                      @{N = 'Content'; E = { Format-Duration $_.PrepTime } },
                                      @{N = 'Execute'; E = { Format-Duration $_.ExecTime } },
                                      @{N = 'Total'; E = { Format-Duration $_.TotalTime } },
                                      @{N = 'Result'; E = { $_.Result } } |
                        Format-Table -AutoSize | Out-String -Width 200 | Write-Host
                }
                Write-Host $line -ForegroundColor DarkGray
            }

            #endregion Console summary
        }
        catch {
            Write-Error ("Failed to process '{0}': {1}" -f $item, $_.Exception.Message)
        }
        finally {
            if ($resolvedLog -and $resolvedLog.TempDir -and (Test-Path -LiteralPath $resolvedLog.TempDir)) {
                Remove-Item -LiteralPath $resolvedLog.TempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

end {

    if ($CsvPath -and $allResults.Count -gt 0) {
        $flat = $allResults | Select-Object ComputerName, TaskSequence, OSImage,
            @{N = 'DeploymentStart'; E = { '{0:yyyy-MM-dd HH:mm:ss}' -f $_.DeploymentStart } },
            @{N = 'DeploymentEnd'; E = { '{0:yyyy-MM-dd HH:mm:ss}' -f $_.DeploymentEnd } },
            @{N = 'TotalDeploymentSeconds'; E = { [math]::Round($_.TotalDeploymentTime.TotalSeconds, 3) } },
            @{N = 'OSContentDownloadSeconds'; E = { if ($_.OSContentDownloadTime) { [math]::Round($_.OSContentDownloadTime.TotalSeconds, 3) } } },
            @{N = 'OSContentDownloadOnlySeconds'; E = { if ($_.OSContentDownloadOnly) { [math]::Round($_.OSContentDownloadOnly.TotalSeconds, 3) } } },
            @{N = 'WimAppliedToDiskSeconds'; E = { if ($_.WimAppliedToDiskTime) { [math]::Round($_.WimAppliedToDiskTime.TotalSeconds, 3) } } },
            @{N = 'DriverPackageDownloadSeconds'; E = { if ($_.DriverPackageDownloadTime) { [math]::Round($_.DriverPackageDownloadTime.TotalSeconds, 3) } } },
            @{N = 'DriverPackageDownloadOnlySeconds'; E = { if ($_.DriverPackageDownloadOnly) { [math]::Round($_.DriverPackageDownloadOnly.TotalSeconds, 3) } } },
            @{N = 'InjectDriversSeconds'; E = { if ($_.InjectDriversTime) { [math]::Round($_.InjectDriversTime.TotalSeconds, 3) } } },
            @{N = 'EnableBranchCacheSeconds'; E = { if ($_.EnableBranchCacheTime) { [math]::Round($_.EnableBranchCacheTime.TotalSeconds, 3) } } },
            @{N = 'SeedLocalCacheSeconds'; E = { if ($_.SeedLocalCacheTime) { [math]::Round($_.SeedLocalCacheTime.TotalSeconds, 3) } } },
            SeedCacheFailures, WarningCount, ErrorCount,
            @{N = 'TotalWinPESeconds'; E = { if ($_.TotalWinPETime) { [math]::Round($_.TotalWinPETime.TotalSeconds, 3) } } },
            @{N = 'RebootSeconds'; E = { [math]::Round($_.RebootTime.TotalSeconds, 3) } },
            OSContentBytes, OSContentSpeedMbps, DriverContentBytes, DriverContentSpeedMbps,
            ContentTotalBytes, ContentFromLocalCache, ContentFromPeers, ContentEfficiencyPercent,
            RebootCount, Outcome, ClockCorrectionApplied, LogFile

        if (Test-Path -LiteralPath $CsvPath) {
            $flat | Export-Csv -LiteralPath $CsvPath -NoTypeInformation -Append
        } else {
            $flat | Export-Csv -LiteralPath $CsvPath -NoTypeInformation
        }
        Write-Verbose "Metrics written to $CsvPath"
    }

    if ($JsonPath -and $allResults.Count -gt 0) {
        $allResults | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $JsonPath -Encoding UTF8
        Write-Verbose "Metrics written to $JsonPath"
    }

    $allResults
}
