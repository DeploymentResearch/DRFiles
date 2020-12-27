<#
.Synopsis
    This script uploads Autopilot into to a RestPS web service
    
.Description
    This script was written by Johan Arwidmark @jarwidmark

.LINK
    https://github.com/FriendsOfMDT/PSD

.NOTES
          FileName: PSDAutopilotDeviceRegistration.ps1
          Solution: PowerShell Deployment for MDT
          Author: PSD Development Team
          Contact: @jarwidmark
          Primary: @jarwidmark 
          Created: 2020-11-09
          Modified: 2020-11-18

          Version - 0.0.0.1 - () - Finalized functional version 1.

.EXAMPLE
	.\PSDAutopilotDeviceRegistration.ps1
#>

#Requires -RunAsAdministrator
[CmdletBinding()]
param (

)

# Load core modules
Import-Module Microsoft.BDD.TaskSequenceModule -Scope Global
Import-Module PSDUtility

# Check for debug in PowerShell and TSEnv
if($TSEnv:PSDDebug -eq "YES"){
    $Global:PSDDebug = $true
}
if($PSDDebug -eq $true)
{
    $verbosePreference = "Continue"
}

Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Starting..."

# Remove any unattend.xml files
Write-PSDLog -Message "Starting to remove existing unattend.xml files"
If (Test-Path "C:\Windows\Panther\unattend.xml" ){Remove-Item "C:\Windows\Panther\unattend.xml" -Force } 
If (Test-Path "C:\Windows\System32\Sysprep\unattend.xml" ){Remove-Item "C:\Windows\System32\Sysprep\unattend.xml" -Force } 

# Get the serial number and hardware hash from the device
# Also add the Intune group gathered from the PSDWizard (stored in the Roles variable)
$AutopilotOutputFile = "C:\Windows\Temp\AutoPilotInfo.csv"
$IntuneGroup = $tsenv:Roles
Write-PSDLog -Message "Intune group from PSD deployment wizard is $IntuneGroup"
Write-PSDLog -Message "Autopilot result will be saved in $AutopilotOutputFile"
Write-PSDLog -Message "Running Get-WindowsAutoPilotInfo.ps1"
Write-PSDLog -Message "Saving result to $AutopilotCSV"

$GetAutoPilotArguments = "$PSScriptRoot\Get-WindowsAutoPilotInfo.ps1 -GroupTag $IntuneGroup -OutputFile $AutopilotOutputFile"
Write-PSDLog -Message "About to run the command: $GetAutoPilotArguments"
$GetAutoPilotProcess = Start-Process PowerShell -ArgumentList $GetAutoPilotArguments -NoNewWindow -PassThru -Wait

# Log the result 
$AutopilotCSV = Import-Csv $AutopilotOutputFile
$SerialNumber = ($AutopilotCSV | Select -First 1)."Device Serial Number"
Write-PSDLog -Message "Device with $SerialNumber saved to $AutopilotCSV"
Write-PSDLog -Message "Device will be added to the Intune group: $IntuneGroup" 

# Convert the CSV file to JSON
Write-PSDLog -Message "Converting the CSV file to JSON"
$AutopilotJSON = $AutopilotCSV | ConvertTo-Json 
Write-PSDLog -Message "JSON object created for computer: $env:COMPUTERNAME, having serial number: $SerialNumber"

# Upload the JSON object to the Autopilot registration webservice script on your deployment server
# Max allowed time is 30 minutes
$DeployRoot = [System.Uri]"$($tsenv:DeployRoot)"
$RestPSServer = $DeployRoot.Host
$RestPSMethod = "PSDAutopilotRegistration"
$RestPSPort = "8080"
$RestPSArgument = "OSDComputerName=$($tsenv:OSDComputerName)"
Write-PSDLog -Message "Connecting to $RestPSServer on port $RestPSPort, using method $RestPSMethod, adding argument: $RestPSArgument"
$Return = Invoke-RestMethod -Method POST -Uri "http://$RestPSServer`:$RestPSPort/$RestPSMethod`?$RestPSArgument" -Body $AutopilotJSON -TimeoutSec 1800

Write-PSDLog -Message "Webservice returned $Return" 

# Cleanup
Remove-item -Path $AutopilotOutputFile -Force 
