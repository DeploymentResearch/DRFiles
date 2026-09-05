<#
.SYNOPSIS
    Triggers an Intune sync on every managed Windows device.
.DESCRIPTION
    The Graph PowerShell Module version. Connects with the device management scopes, enumerates
    all Windows devices, and requests a sync on each one.
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
      1.0.0 - 2024-06-11 - Initial release
#>

# Install the module. (You need admin on the machine.)
# Install-Module Microsoft.Graph
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.DeviceManagement
$TenantID = ""

$Scopes = @(
    "DeviceManagementManagedDevices.Read.All",
    "DeviceManagementManagedDevices.ReadWrite.All",
    "DeviceManagementManagedDevices.PrivilegedOperations.All"
)

$Tenant = Connect-MgGraph -TenantId $TenantID -Scopes $Scopes
# Get all Windows Devices
$Devices = Get-MgDeviceManagementManagedDevice -Filter "contains(operatingsystem, 'Windows')"

# Show Device Count
($Devices | Measure-Object).Count

# Report Last Sync, and force sync on each Device
Foreach ($Device in $Devices) {
    Write-Host "Last Sync Time was: $($Device.lastSyncDateTime)"
    # Force sync
    Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $Device.Id 
    Write-Host "Sending Sync request to Device with DeviceID $($Device.Id)" -ForegroundColor Yellow
    Write-Host ""
}


#
# Misc samples
#

# Get all devices
Get-MgDeviceManagementManagedDevice -All

# Get devices for a specific user
$Devices = Get-MgDeviceManagementManagedDevice | Where-Object { $_.userDisplayName -eq "Bob Smith" }
$Devices | Select-Object deviceName

# Get Devices from wildcard 
$Devices = Get-MgDeviceManagementManagedDevice -Filter "contains(deviceName, 'PC')"
$Devices | Select-Object deviceName

# Get Single Device
$Devices = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq 'PC001'"
