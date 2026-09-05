<#
.SYNOPSIS
    Installs the Windows ADK 10 version 1809 features needed for deployment.
.DESCRIPTION
    Checks for elevation, then runs the ADK setup silently with the deployment tools, WinPE,
    and USMT features selected.
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
      1.0.0 - 2022-01-02 - Initial release
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
