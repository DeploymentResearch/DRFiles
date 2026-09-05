<#
.SYNOPSIS
    Removes MDT deployment traces before handing a device over to Autopilot.
.DESCRIPTION
    Cleans up the MDT folders, files, and registry values left behind by a Lite Touch
    deployment so the device can complete Autopilot enrollment cleanly.
.EXAMPLE
    .\CleanupForAutopilot.ps1
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
      1.0.0 - 2023-10-22 - Initial release
#>

#Requires -RunAsAdministrator
[CmdletBinding()]
param (

)

# Specify log file location
$LogFile = "C:\Windows\Temp\CleanupForAutopilot.log"

# Delete any existing logfile if it exists
If (Test-Path $Logfile){Remove-Item $Logfile -Force -ErrorAction SilentlyContinue -Confirm:$false}

# Simple logging function
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

# Remove MDT Info
If (Test-Path "C:\MININT" ){Remove-Item "C:\MININT" -Recurse -Force } 
If (Test-Path "C:\_SMSTaskSequence" ){Remove-Item "C:\_SMSTaskSequence" -Recurse -Force } 
If (Test-Path "C:\LTIBootstrap.vbs" ){Remove-Item "C:\LTIBootstrap.vbs" -Force } 

