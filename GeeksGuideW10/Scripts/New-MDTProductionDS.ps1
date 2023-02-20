<#
Script name: 
Created:	 2013-12-16
Version:	 1.2
Author       Mikael Nystrom and Johan Arwidmark       
Homepage:    http://www.deploymentfundamentals.com

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and 
is not supported by the authors or DeploymentArtist.

Author - Mikael Nystrom
    Twitter: @mikael_nystrom
    Blog   : http://deploymentbunny.com

Author - Johan Arwidmark
    Twitter: @jarwidmark
    Blog   : http://deploymentresearch.com
#>

# Check for elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
	Write-Warning "Aborting script..."
    Break
}

#Set Variables
$ComputerName = $Env:COMPUTERNAME
$RootDrive = "E:"
$MDTInstallDrive = "C:"

# Validation, verify that the deployment share doesnt exist already
$MDTProductionShareExist = Get-SmbShare | Where-Object -Property Name -Like -Value 'MDTProduction$'
If ($MDTProductionShareExist.Name -eq 'MDTProduction$'){Write-Warning "MDTProduction$ share already exist, aborting...";Break}
if (Test-Path -Path "$RootDrive\MDTProduction") {Write-Warning "$RootDrive\MDTProduction already exist, aborting...";Break}

# Validation, verify that the PSDrive doesnt exist already
if (Test-Path -Path "DS002:") {Write-Warning "DS002: PSDrive already exist, aborting...";Break}

# Create the MDT Production Deployment Share root folder
New-Item -Path $RootDrive\MDTProduction -ItemType directory

# Create the MDT Production Deployment Share
Import-Module "$MDTInstallDrive\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
new-PSDrive -Name "DS002" -PSProvider "MDTProvider" -Root "$RootDrive\MDTProduction" -Description "MDT Production" -NetworkPath "\\$ComputerName\MDTProduction$" | add-MDTPersistentDrive
New-SmbShare –Name MDTProduction$ –Path "$RootDrive\MDTProduction" –ChangeAccess EVERYONE

#Configure DeploymentShare
Set-ItemProperty -Path DS002: -Name SupportX86 -Value 'False'
Set-ItemProperty -Path DS002: -Name Boot.x64.ScratchSpace -Value '512'
Set-ItemProperty -Path DS002: -Name Boot.x64.IncludeAllDrivers -Value 'True'
Set-ItemProperty -Path DS002: -Name Boot.x64.SelectionProfile -Value 'WinPE x64'
Set-ItemProperty -Path DS002: -Name Boot.x64.LiteTouchWIMDescription -Value 'MDT Production x64'
Set-ItemProperty -Path DS002: -Name Boot.x64.LiteTouchISOName -Value 'MDT Production x64.iso'

