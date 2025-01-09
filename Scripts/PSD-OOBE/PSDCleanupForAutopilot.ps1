<#
.Synopsis
    This script removes any PSD references from a device. 
    
.Description
    This script removes any PSD references from a device, typically used for Autopilot scenarios.
    The script is intended to run in the specialize pass via unattend.xml

.LINK
    https://deploymentresearch.com

.NOTES
          FileName: PSDCleanupForAutopilot.ps1
          Author: @jarwidmark
          Version: Initial release

.EXAMPLE
	.\PSDCleanupForAutopilot.ps1
#>

#Requires -RunAsAdministrator
$LogFile = "C:\Windows\Temp\PSDCleanupForAutopilot.log"

# Delete any existing logfile if it exists
If (Test-Path $Logfile){Remove-Item $Logfile -Force -ErrorAction SilentlyContinue -Confirm:$false}

# Standalone logging function (no PSD dependencies)
function Write-Log {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        $Message,
        [Parameter(Mandatory=$false)]
        $ErrorMessage,
        [Parameter(Mandatory=$false)]
        $Component = "Script",
        [Parameter(Mandatory=$false)]
        [int]$Type
    )
    <#
    Type: 1 = Normal, 2 = Warning (yellow), 3 = Error (red)
    #>
   $Time = Get-Date -Format "HH:mm:ss.ffffff"
   $Date = Get-Date -Format "MM-dd-yyyy"
   if ($ErrorMessage -ne $null) {$Type = 3}
   if ($Component -eq $null) {$Component = " "}
   if ($Type -eq $null) {$Type = 1}
   $LogMessage = "<![LOG[$Message $ErrorMessage" + "]LOG]!><time=`"$Time`" date=`"$Date`" component=`"$Component`" context=`"`" type=`"$Type`" thread=`"`" file=`"`">"
   $LogMessage.Replace("`0","") | Out-File -Append -Encoding UTF8 -FilePath $LogFile
}

# Remove any unattend.xml files
$UnattendFiles = @(
    "C:\Windows\Panther\unattend.xml"
    "C:\Windows\System32\Sysprep\unattend.xml"
)

Write-Log "Removing existing unattend.xml files"
Foreach ($File in $UnattendFiles){
    If (Test-Path $File){
        Write-Log "$File file found, removing it"
        Remove-Item $File -Force
    }
    Else {
        Write-Log "$File file not found, continuing.."
    }
}

# Remove other PSD Folders
$PSDFolders = @(
    "C:\MININT"
    "C:\_SMSTaskSequence"
)

Write-Log "Removing existing PSD Folders"
Foreach ($Folder in $PSDFolders){
    If (Test-Path $Folder){
        Write-Log "$Folder folder found, removing it"
        Remove-Item $Folder -Recurse -Force
    }
    Else {
        Write-Log "$Folder folder not found, continuing.."
    }
}

# Remove other PSD Files
$PSDFiles = @(
    "C:\marker.psd"
)

Write-Log "Removing existing PSD files"
Foreach ($File in $PSDFiles){
    If (Test-Path $File){
        Write-Log "$File file found, removing it"
        Remove-Item $File -Force
    }
    Else {
        Write-Log "$File file not found, continuing.."
    }
}


