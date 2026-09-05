<#
.SYNOPSIS
    Removes PSD deployment traces before handing a device over to Autopilot.
.DESCRIPTION
    Cleans up the folders, files, and registry values left behind by a PowerShell Deployment
    for MDT deployment so the device can complete Autopilot enrollment cleanly.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark / deploymentresearch.com
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2023-10-05 - Initial release
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param (

)

$LogFile = "C:\Windows\Temp\PSDAutopilotCleanup.log"

# Delete any existing logfile if it exists
If (Test-Path $Logfile){Remove-Item $Logfile -Force -ErrorAction SilentlyContinue -Confirm:$false}

Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
   )

   $TimeGenerated = $(Get-Date -UFormat "%D %T")
   $Line = "$TimeGenerated $Message"
   Add-Content -Value $Line -Path $LogFile -Encoding Ascii

}

# Remove any unattend.xml files
Write-Log -Message "Starting to remove existing unattend.xml files"
If (Test-Path "C:\Windows\Panther\unattend.xml" ){Remove-Item "C:\Windows\Panther\unattend.xml" -Force } 
If (Test-Path "C:\Windows\System32\Sysprep\unattend.xml" ){Remove-Item "C:\Windows\System32\Sysprep\unattend.xml" -Force } 

