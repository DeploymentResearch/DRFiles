<#
.SYNOPSIS
    Creates the Chicago1 Hyper-V virtual switch if it does not already exist.
.DESCRIPTION
    Checks for an existing switch with the same name first, so the script can be run repeatedly
    without error.
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
      1.0.0 - 2025-01-05 - Initial release
#>

# Create Hyper-V Virtual Switch 
$VMNetwork = "Chicago1"

Write-Host "Checking for Hyper-V Virtual Switch"
$VMSwitchNameCheck = Get-VMSwitch | Where-Object -Property Name -EQ $VMNetwork
if ($VMSwitchNameCheck.Name -eq $VMNetwork) {
    Write-Host "Hyper-V switch already exist, all ok..." -ForegroundColor Green
}
Else {
    Write-Host "Hyper-V switch does not exist, creating it"
    Write-host "Creating virtual switch..."
    New-VMSwitch -Name $VMNetwork -AllowManagementOS $true -NetAdapterName "Ethernet"
    Start-Sleep -Seconds 10
}

