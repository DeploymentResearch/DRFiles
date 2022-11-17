#Requires -Modules Microsoft.Graph
# Install the module. (You need admin on the machine.)
# Install-Module Microsoft.Graph
$TenantID = ""

Select-MgProfile -Name "beta"
$Tenant = Connect-MgGraph -TenantId $TenantID -Scopes "DeviceManagementManagedDevices.Read.All","DeviceManagementManagedDevices.ReadWrite.All","DeviceManagementManagedDevices.PrivilegedOperations.All"
# Get all Windows Devices
$Devices = Get-MgDeviceManagementManagedDevice -Filter "contains(operatingsystem, 'Windows')" | Get-MSGraphAllPages

# Show Device Count
($Devices | Measure-Object).Count

# Report Last Sync, and force sync on each Device
Foreach ($Device in $Devices)
{
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
Get-MgDeviceManagementManagedDevice | Get-MSGraphAllPages

# Get devices for a specific user
$Devices = Get-MgDeviceManagementManagedDevice | Where-Object {$_.userDisplayName -eq "Bob Smith"}
$Devices | Select deviceName

# Get Devices from wildcard 
$Devices = Get-MgDeviceManagementManagedDevice -Filter "contains(deviceName, 'PC')"
$Devices | Select deviceName

# Get Single Device
$Devices = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq 'PC001'"
