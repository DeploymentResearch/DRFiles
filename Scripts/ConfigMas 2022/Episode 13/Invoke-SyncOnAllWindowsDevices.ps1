# Demo script for working with Intune managed devices
#
# Author: Johan Arwidmark
# Twitter: @jarwidmark
# LinkedIn: https://www.linkedin.com/in/jarwidmark

Import-Module Microsoft.Graph.Intune  
Connect-MSGraph -ForceInteractive

# Get all Windows Devices 
$Devices = Get-IntuneManagedDevice -Filter "contains(operatingsystem, 'Windows')" | Get-MSGraphAllPages

# Get all ViaMonstra Lab Machines from Device Category
$Devices = Get-IntuneManagedDevice -Filter "deviceCategoryDisplayName eq 'ViaMonstra Lab Machines'" 

# Get Single Devices
$Devices = Get-IntuneManagedDevice -Filter "deviceName eq 'DA-INTUNE-001'" 

# Get Devices from wildcard name
$Devices = Get-IntuneManagedDevice -Filter "contains(deviceName, 'DA-INTUNE')"
$Devices = Get-IntuneManagedDevice -Filter "contains(deviceName, 'PC')"

# Show Device Name(s)
$Devices | Select-Object deviceName

# Show Device Count
($Devices | Measure-Object).Count

# Report Last Sync, and force sync on each Device
Foreach ($Device in $Devices)
{
    $DeviceID = $Device.managedDeviceId
    $DeviceName = $Device.deviceName
    $lastSyncDateTime = $Device.lastSyncDateTime

    Write-Host "Last Sync Time for $DeviceName was: $lastSyncDateTime"
    # Force Sync
    Invoke-IntuneManagedDeviceSyncDevice -managedDeviceId $DeviceID 
    Write-Host "Sending Sync request to $DeviceName having device id: $DeviceID" -ForegroundColor Yellow
    Write-Host ""
}
