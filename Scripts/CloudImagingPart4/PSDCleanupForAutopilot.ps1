<#
.SYNOPSIS
    Client-Side script for Cloud OS Deployment, Part 4

.DESCRIPTION
    This script removes any PSD references from a device. 

.NOTES
    Author: Johan Arwidmark / deploymentresearch.com
    Twitter (X): @jarwidmark
    LinkedIn: https://www.linkedin.com/in/jarwidmark
    License: MIT
    Source:  https://github.com/DeploymentResearch/DRFiles

.DISCLAIMER
    This script is provided "as is" without warranty of any kind, express or implied.
    Use at your own risk — the author and DeploymentResearch assume no responsibility for any
    issues, damages, or data loss resulting from its use or modification.

    This script is shared in the spirit of community learning and improvement.
    You are welcome to adapt and redistribute it under the terms of the MIT License.

.VERSION
    1.0.2
    Released: 2025-10-01
    Change history:
      1.0.2 - 2025-10-01 - Added Drivers cleanup
      1.0.1 - 2021-09-10 - Integration release for the PSD Cloud OS Deployment solution
      1.0.0 - 2020-05-12 - Initial release
#>

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
    "C:\Drivers"
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


