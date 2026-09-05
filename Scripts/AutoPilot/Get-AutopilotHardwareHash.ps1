<#
.SYNOPSIS
    Downloads and runs Get-WindowsAutoPilotInfo to capture a hardware hash.
.DESCRIPTION
    Installs the NuGet package provider, saves the Get-WindowsAutoPilotInfo script from the
    PowerShell Gallery, and writes the hardware hash to a CSV file.
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

# Install Nuget
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Create working folder
$AutopilotFolder = "C:\AutoPilot"
If (!(Test-Path $AutopilotFolder)){ New-Item $AutopilotFolder -ItemType Directory -Force }

# Save Autopilot script
Save-Script -Name Get-WindowsAutoPilotInfo -Path $AutopilotFolder

# Get the hardware hash 
& "$AutopilotFolder\Get-WindowsAutoPilotInfo.ps1"-OutputFile "$AutopilotFolder\$($env:ComputerName)_HWID.csv"
