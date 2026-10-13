# Enable ManageEngine Services after ugrade

# Script Settings
$TempPath    = "C:\Windows\Temp"
$LogFile     = Join-Path $TempPath "EnableManageEngineServices.log"
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

# Enable and start ManageEngine Services
Write-Log "Restoring UEMS1Svc to running state"
sc.exe config $UEMS1Svc start=auto | Out-Null
sc.exe start  $UEMS1Svc            | Out-Null

# Enable and start ManageEngine Services
Write-Log "Restoring UEMS1Svc to running state"
sc.exe config $UEMS2Svc start=auto | Out-Null
sc.exe start  $UEMS2Svc   
Start-Sleep -Seconds 5
