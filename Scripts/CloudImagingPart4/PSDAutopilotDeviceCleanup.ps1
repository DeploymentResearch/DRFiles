<#
.Synopsis
    This script removes an Autopilot device from Intune
    
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
	.\PSDAutopilotDeviceCleanup.ps1
#> 

[CmdletBinding()]
param (

)

# Load core modules
Import-Module Microsoft.BDD.TaskSequenceModule -Scope Global
Import-Module PSDUtility

#Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Starting..."

# Upload the serial number to the Autopilot device cleanup webservice script on your deployment server
# Max allowed time is 5 minutes
$DeployRootUri = [System.Uri]"$DeployRoot)"
#$RestPSServer = $DeployRootUri.Host 
$RestPSServer = "mdt04.corp.viamonstra.com" 
$RestPSMethod = "RPSDAutopilotDeviceCleanup"
$RestPSPort = "8080"
#$RestPSArgument = "SerialNumber=$($tsenv:SerialNumber)"
$RestPSArgument = "SerialNumber=2D1WWZ2"
#Write-PSDLog -Message "Connecting to $RestPSServer on port $RestPSPort, using method $RestPSMethod, adding argument: $RestPSArgument"
$Return = Invoke-RestMethod -Method POST -Uri "http://$RestPSServer`:$RestPSPort/$RestPSMethod`?$RestPSArgument" -TimeoutSec 600

Write-Host "Webservice returned: $Return" 

