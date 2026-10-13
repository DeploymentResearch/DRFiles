# Disable ManageEngine Services interfering Windows 11 25H2 IPU (the agent crashes, so the upgrade )
# Note: These services have tamper protection, so the process typically have to be killed

# Script Settings
$TempPath     = "C:\Windows\Temp"
$LogFile      = Join-Path $TempPath "DisableManageEngineServices.log"
$Services     = @(
    "ManageEngine Unified Endpoint Security - Agent"
    "ManageEngine UEMS - Agent"
)                       # Service name or display name, both work
$StopTimeout  = 60      # Seconds to wait for each service to stop
$KillIfStuck  = $true   # Kill the service process if it refuses to stop

# CMTrace format logging function
function Write-Log {
    [CmdletBinding()]
    Param (
        $Message,
        $ErrorMessage,
        $Component = "DisableManageEngine",
        [int]$Type
    )
    $Time = Get-Date -Format "HH:mm:ss.ffffff"
    $Date = Get-Date -Format "MM-dd-yyyy"
    if ($ErrorMessage -ne $null) { $Type = 3 }
    if ($Type -eq 0) { $Type = 1 }
    $LogMessage = "<![LOG[$Message $ErrorMessage" + "]LOG]!><time=`"$Time`" date=`"$Date`" component=`"$Component`" context=`"`" type=`"$Type`" thread=`"`" file=`"`">"
    $LogMessage.Replace("`0", "") | Out-File -Append -Encoding UTF8 -FilePath $LogFile -ErrorAction SilentlyContinue
}

# What the common sc.exe stop exit codes mean
$ScErrors = @{
    0    = "Stop requested"
    5    = "Access denied (agent tamper protection, or not running as admin/SYSTEM)"
    1051 = "Other running services depend on it"
    1052 = "Service does not accept a stop request"
    1060 = "Service not found"
    1061 = "Service cannot accept control messages right now"
    1062 = "Service was not running"
}

# Reset the log each run
if (Test-Path $LogFile) { Remove-Item $LogFile -Force -ErrorAction SilentlyContinue }

foreach ($Name in $Services) {

    # Resolve to the real service name, sc.exe stop does not reliably accept a display name
    $Svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $Svc) { $Svc = Get-Service -DisplayName $Name -ErrorAction SilentlyContinue }
    if (-not $Svc) {
        Write-Log "Service '$Name' not found, skipping" -Type 2
        continue
    }
    $SvcName = $Svc.Name
    Write-Log "Found '$($Svc.DisplayName)' (service name '$SvcName'), status: $($Svc.Status), can stop: $($Svc.CanStop)"

    # Disable first, so the service cannot be restarted by recovery actions or a watchdog
    $Output = sc.exe config "$SvcName" start= disabled 2>&1
    Write-Log "sc config start= disabled, exit code $LASTEXITCODE. $(($Output | Out-String).Trim())"

    if ($Svc.Status -eq 'Stopped') {
        Write-Log "'$SvcName' is already stopped"
        continue
    }

    # Request the stop and log why if it is refused
    $Output = sc.exe stop "$SvcName" 2>&1
    $Code = $LASTEXITCODE
    $Reason = $ScErrors[$Code]
    if ($Code -eq 0) {
        Write-Log "sc stop, exit code 0. $Reason"
    } else {
        Write-Log "sc stop, exit code $Code. $Reason. $(($Output | Out-String).Trim())" -Type 2
    }

    # sc.exe stop only sends the request, so wait for the service to actually stop
    try {
        $Svc.WaitForStatus('Stopped', [TimeSpan]::FromSeconds($StopTimeout))
        Write-Log "'$SvcName' stopped"
    }
    catch {
        $Svc.Refresh()
        Write-Log "'$SvcName' did not stop within $StopTimeout seconds, status: $($Svc.Status)" -Type 2

        if ($KillIfStuck) {
            $ProcessId = (Get-CimInstance -ClassName Win32_Service -Filter "Name='$($SvcName.Replace("'", "''"))'").ProcessId
            if ($ProcessId -gt 0) {
                try {
                    Stop-Process -Id $ProcessId -Force -ErrorAction Stop
                    Start-Sleep -Seconds 5
                    $Svc.Refresh()
                    Write-Log "Killed process $ProcessId for '$SvcName', status now: $($Svc.Status)"
                }
                catch {
                    Write-Log "Could not kill process $ProcessId for '$SvcName'." -ErrorMessage $_.Exception.Message
                }
            }
        }
    }
}
