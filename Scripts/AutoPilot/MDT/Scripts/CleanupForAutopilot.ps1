<#
.Synopsis
    This script prepares for Windows Autopilot
    
.Description
    This script was written by Johan Arwidmark @jarwidmark

.NOTES
          FileName: CleanupForAutopilot.ps1
          Contact: @jarwidmark
          Created: October 21, 2023

          Version - 1.0 - Initial Version

.EXAMPLE
	.\CleanupForAutopilot.ps1
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

