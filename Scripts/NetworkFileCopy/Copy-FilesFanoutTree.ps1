# Generate list of 10 lab machine names 
$LowNumber  = 1
$HighNumber = 10
$LabMachinePrefix = "ROGUE-" 

$Servers = $LowNumber..$HighNumber | ForEach-Object {
    "$LabMachinePrefix{0:D3}" -f $_
}

# Ask for credentials
$Cred = Get-Credential

# Function for copy files and folders in a fanout tree copy
function Invoke-FanoutTreeCopy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [pscredential]$Credential,

        [Parameter()]
        [string]$DestinationFolder = 'C:\Setup',

        # How many children each seeded server should feed
        [Parameter()]
        [ValidateRange(1,16)]
        [int]$Fanout = 2,

        [Parameter()]
        [switch]$CreateDestination
    )

    $ErrorActionPreference = 'Stop'

    if ($ComputerName.Count -lt 1) { throw "ComputerName must contain at least one server." }

    # Clean list, preserve order, unique
    $ComputerName = $ComputerName | Where-Object { $_ -and $_.Trim() } | ForEach-Object { $_.Trim() }
    $ComputerName = $ComputerName | Select-Object -Unique

    $fileName = [IO.Path]::GetFileName($SourcePath)

    # --- Helper: local -> server admin share using PSDrive+Cred ---
    function Copy-LocalToServer {
        param([string]$ToComputer)

        $root = "\\$ToComputer\C$"
        $drv  = "S_$([guid]::NewGuid().ToString('N').Substring(0,6))"

        try {
            New-PSDrive -Name $drv -PSProvider FileSystem -Root $root -Credential $Credential -ErrorAction Stop | Out-Null

            $remoteFolder = ($DestinationFolder -replace '^C:', "$drv`:")
            if ($CreateDestination -and -not (Test-Path -LiteralPath $remoteFolder)) {
                New-Item -ItemType Directory -Path $remoteFolder -Force | Out-Null
            }

            Copy-Item -LiteralPath $SourcePath -Destination (Join-Path $remoteFolder $fileName) -Force -ErrorAction Stop

            [pscustomobject]@{
                Source = $env:COMPUTERNAME
                Target = $ToComputer
                Status = 'OK'
                Error  = $null
            }
        }
        catch {
            [pscustomobject]@{
                Source = $env:COMPUTERNAME
                Target = $ToComputer
                Status = 'FAILED'
                Error  = $_.Exception.Message
            }
        }
        finally {
            if (Get-PSDrive -Name $drv -ErrorAction SilentlyContinue) {
                Remove-PSDrive -Name $drv -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # --- Remote hop script: src server copies its local file to target admin share ---
    $hopScript = {
        param($Target, $DestFolder, $FileName, $Cred, $CreateDest)

        $ErrorActionPreference = 'Stop'
        $localFile = Join-Path $DestFolder $FileName

        if (-not (Test-Path -LiteralPath $localFile)) {
            throw "Local file missing on $env:COMPUTERNAME: $localFile"
        }

        $root = "\\$Target\C$"
        $drv  = "T_$([guid]::NewGuid().ToString('N').Substring(0,6))"

        try {
            New-PSDrive -Name $drv -PSProvider FileSystem -Root $root -Credential $Cred -ErrorAction Stop | Out-Null

            $remoteFolder = ($DestFolder -replace '^C:', "$drv`:")
            if ($CreateDest -and -not (Test-Path -LiteralPath $remoteFolder)) {
                New-Item -ItemType Directory -Path $remoteFolder -Force | Out-Null
            }

            Copy-Item -LiteralPath $localFile -Destination (Join-Path $remoteFolder $FileName) -Force -ErrorAction Stop

            [pscustomobject]@{
                Source = $env:COMPUTERNAME
                Target = $Target
                Status = 'OK'
                Error  = $null
            }
        }
        catch {
            [pscustomobject]@{
                Source = $env:COMPUTERNAME
                Target = $Target
                Status = 'FAILED'
                Error  = $_.Exception.Message
            }
        }
        finally {
            if (Get-PSDrive -Name $drv -ErrorAction SilentlyContinue) {
                Remove-PSDrive -Name $drv -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # -------------------------
    # 1) Seed the root (Server1)
    # -------------------------
    $root = $ComputerName[0]
    Write-Verbose "Seeding root: $root"
    $results = New-Object System.Collections.Generic.List[object]

    $seed = Copy-LocalToServer -ToComputer $root
    $results.Add($seed)

    if ($seed.Status -ne 'OK') {
        return $results
    }

    # Remaining targets after root
    $remaining = New-Object System.Collections.Generic.Queue[string]
    foreach ($s in $ComputerName[1..($ComputerName.Count-1)]) { $remaining.Enqueue($s) }

    # BFS queue of seeders (tree expansion)
    $seederQueue = New-Object System.Collections.Generic.Queue[string]
    $seederQueue.Enqueue($root)

    # Track what we've successfully seeded so far
    $seeded = New-Object 'System.Collections.Generic.HashSet[string]'
    [void]$seeded.Add($root)

    # -------------------------
    # 2) Grow the tree in waves
    # -------------------------
    while ($remaining.Count -gt 0 -and $seederQueue.Count -gt 0) {

        # Take current seeders for this wave (everything currently in queue)
        $thisWaveSeeders = @()
        while ($seederQueue.Count -gt 0) {
            $thisWaveSeeders += $seederQueue.Dequeue()
        }

        # Schedule copies: each seeder -> up to Fanout targets
        $jobs = @()
        $pairs = @()

        foreach ($src in $thisWaveSeeders) {
            for ($i = 0; $i -lt $Fanout -and $remaining.Count -gt 0; $i++) {
                $tgt = $remaining.Dequeue()
                $pairs += [pscustomobject]@{ Source = $src; Target = $tgt }

                $jobs += Invoke-Command -ComputerName $src -Credential $Credential -AsJob `
                    -ScriptBlock $hopScript -ArgumentList $tgt, $DestinationFolder, $fileName, $Credential, ([bool]$CreateDestination)
            }
        }

        if (-not $jobs) { break }

        # Collect results
        $waveOut = $jobs | Wait-Job | Receive-Job
        $jobs | Remove-Job -Force

        foreach ($r in @($waveOut)) {
            $results.Add($r)

            # Only successful targets become new seeders
            if ($r.Status -eq 'OK' -and -not $seeded.Contains($r.Target)) {
                [void]$seeded.Add($r.Target)
                $seederQueue.Enqueue($r.Target)
            }
        }
    }

    return $results
}

# Copy files in a fanout tree
# Note: the Fanout parameter determines how many machines each parent machine should fan out to.
Invoke-FanoutTreeCopy -SourcePath "E:\ISO\pfsense-netgate-installer-v1.0-RC-amd64-20240919-1435.iso" `
    -ComputerName $servers `
    -Credential $Cred `
    -DestinationFolder "C:\ISO" `
    -CreateDestination `
    -Fanout 3 |
Format-Table -Auto

