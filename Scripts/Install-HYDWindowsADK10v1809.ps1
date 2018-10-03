<#

************************************************************************************************************************

Created:	October 2, 2018
Version:	1.0

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and 
is not supported by the author or DeploymentArtist.

Author - Johan Arwidmark
    Twitter: @jarwidmark
    Blog   : http://deploymentresearch.com

************************************************************************************************************************

#>

# Check for elevation
Write-Host "Checking for elevation"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
    Write-Warning "Aborting script..."
    Break
}

# Change these to match location of downloaded files
$ADKSetupFile = "C:\Setup\Windows ADK 10 v1809\adksetup.exe"
$WinPEAddonSetupFile = "C:\Setup\WinPE Addon for Windows ADK 10 v1809\adkwinpesetup.exe"

# Validation
if (!(Test-Path -path $ADKSetupFile)) {Write-Warning "Could not find Windows 10 ADK Setup files, aborting...";Break}
if (!(Test-Path -path $WinPEAddonSetupFile)) {Write-Warning "Could not find WinPE Addon Setup files, aborting...";Break}

# Install Windows ADK 10 with components for MDT and/or ConfigMgr
# For troubleshooting, check logs in %temp%\adk
$SetupName = "Windows ADK 10"
$SetupSwitches = "/Features OptionId.DeploymentTools OptionId.ImagingAndConfigurationDesigner OptionId.ICDConfigurationDesigner OptionId.UserStateMigrationTool /norestart /quiet /ceip off"
Write-Output "Starting install of $SetupName"
Write-Output "Command line to start is: $ADKSetupFile $SetupSwitches"
Start-Process -FilePath $ADKSetupFile -ArgumentList $SetupSwitches -NoNewWindow -Wait
Write-Output "Finished installing $SetupName"

# Install WinPE Addon for Windows ADK 10
# For troubleshooting, check logs in %temp%\adk
$SetupName = "WinPE Addon for Windows ADK 10"
$SetupSwitches = "/Features OptionId.WindowsPreinstallationEnvironment /norestart /quiet /ceip off"
Write-Output "Starting install of $SetupName"
Write-Output "Command line to start is: $WinPEAddonSetupFile $SetupSwitches"
Start-Process -FilePath $WinPEAddonSetupFile -ArgumentList $SetupSwitches -NoNewWindow -Wait
Write-Output "Finished installing $SetupName"