<#
.SYNOPSIS
    Creates the standard ConfigMgr content source folder structure.
.DESCRIPTION
    Creates the folder hierarchy used for applications, packages, drivers, and operating system
    images, and sets the share and NTFS permissions.
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
      1.0.0 - 2026-08-06 - Initial release
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

New-Item -Path "E:\MigData" -ItemType Directory -Force
New-Item -Path "E:\Logs" -ItemType Directory -Force
New-Item -Path "E:\Setup" -ItemType Directory -Force
New-Item -Path "E:\Sources" -ItemType Directory -Force
New-Item -Path "E:\Sources\OSD" -ItemType Directory -Force
New-Item -Path "E:\Sources\OSD\Boot" -ItemType Directory -Force
New-Item -Path "E:\Sources\OSD\Branding" -ItemType Directory -Force
New-Item -Path "E:\Sources\OSD\DriverPackages" -ItemType Directory -Force
New-Item -Path "E:\Sources\OSD\DriverSources" -ItemType Directory -Force
New-Item -Path "E:\Sources\OSD\OS" -ItemType Directory -Force
New-Item -Path "E:\Sources\OSD\Settings" -ItemType Directory -Force
New-Item -Path "E:\Sources\Software" -ItemType Directory -Force
New-Item -Path "E:\Sources\Software\Adobe" -ItemType Directory -Force
New-Item -Path "E:\Sources\Software\Microsoft" -ItemType Directory -Force

net share 'Logs$=E:\Logs' '/grant:EVERYONE,change'
icacls E:\Logs /grant '"VIAMONSTRA\CM_OSD":(OI)(CI)(M)'
net share 'Sources=E:\Sources' '/grant:EVERYONE,full'
