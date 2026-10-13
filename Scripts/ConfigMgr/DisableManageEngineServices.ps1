# Disable ManageEngine Services interfering Windows 11 25H2 IPU

# Script Settings
$TempPath    = "C:\Windows\Temp"
$LogFile     = Join-Path $TempPath "BCMon_Discovery.log"
$UEMS1Svc  = "ManageEngine Unified Endpoint Security - Agent"
$UEMS2Svc = "ManageEngine UEMS - Agent"

# CMTrace format logging function
function Write-Log {
    [CmdletBinding()]
    Param (
        $Message,
        $ErrorMessage,
        $Component = "Discovery",
        [int]$Type
    )
    $Time = Get-Date -Format "HH:mm:ss.ffffff"
    $Date = Get-Date -Format "MM-dd-yyyy"
    if ($ErrorMessage -ne $null) { $Type = 3 }
    if ($Type -eq 0) { $Type = 1 }
    $LogMessage = "<![LOG[$Message $ErrorMessage" + "]LOG]!><time=`"$Time`" date=`"$Date`" component=`"$Component`" context=`"`" type=`"$Type`" thread=`"`" file=`"`">"
    $LogMessage.Replace("`0", "") | Out-File -Append -Encoding UTF8 -FilePath $LogFile -ErrorAction SilentlyContinue
}

# Reset the log each run
if (Test-Path $LogFile) { Remove-Item $LogFile -Force -ErrorAction SilentlyContinue }

# Stop and disable ManageEngine Services 
Write-Log "Stopping and disabling $UEMS1Svc"
sc.exe config $UEMS1Svc start=disabled | Out-Null
sc.exe stop   $UEMS1Svc                | Out-Null

Write-Log "Stopping and disabling $UEMS1Svc"
sc.exe config $UEMS2Svc start=disabled | Out-Null
sc.exe stop   $UEMS2Svc                | Out-Null
Start-Sleep -Seconds 5
