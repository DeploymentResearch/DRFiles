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