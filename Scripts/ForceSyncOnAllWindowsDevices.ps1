<#
.SYNOPSIS
    Triggers an Intune sync on every managed Windows device.
.DESCRIPTION
    Connects with the legacy Microsoft.Graph.Intune module, enumerates all Windows devices, and
    requests a sync on each one.
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

$Tenant = Connect-MSGraph -ForceInteractive

# Get all Windows Devices
$Devices = Get-IntuneManagedDevice -Filter "contains(operatingsystem, 'Windows')" | Get-MSGraphAllPages

# Show Device Count
($Devices | Measure-Object).Count

# Report Last Sync, and force sync on each Device
Foreach ($Device in $Devices)
{
    Write-Host "Last Sync Time was: $($Device.lastSyncDateTime)"
    # Force sync
    Invoke-IntuneManagedDeviceSyncDevice -managedDeviceId $Device.managedDeviceId 
    Write-Host "Sending Sync request to Device with DeviceID $($Device.managedDeviceId)" -ForegroundColor Yellow
    Write-Host ""
}


#
# Misc samples
#

# Get all devices
Get-IntuneManagedDevice | Get-MSGraphAllPages

# Get devices for a specific user
$Devices = Get-IntuneManagedDevice | Where-Object {$_.userDisplayName -eq "Johan Arwidmark"}
$Devices | Select deviceName

# Get Devices from wildcard 
$Devices = Get-IntuneManagedDevice -Filter "contains(deviceName, '001')"

# Get Single Device
$Devices = Get-IntuneManagedDevice -Filter "deviceName eq 'DA-INTUNE-001'"
