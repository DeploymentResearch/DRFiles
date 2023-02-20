# Get VMName and Serial Number
Get-WmiObject -Namespace root\virtualization\v2 -class Msvm_VirtualSystemSettingData | Select-Object elementname, BIOSSerialNumber| Sort-Object -Property elementname

# Get VMName, Serial Number, and GUID
Get-WmiObject -Namespace root\virtualization\v2 -class Msvm_VirtualSystemSettingData | Select-Object elementname, BIOSSerialNumber, BIOSGuid | Sort-Object -Property elementname

# Get all properties from all VMs
Get-WmiObject -Namespace root\virtualization\v2 -class Msvm_VirtualSystemSettingData | Select-Object * | Sort-Object -Property elementname

# Get all settings based on a serial number
Get-CimInstance -Namespace root\virtualization\v2 -class Msvm_VirtualSystemSettingData -Filter "BIOSSerialNumber = '0136-6478-0043-9282-3704-1377-54'" | Select-Object * | Sort-Object -Property elementname

# Get all settings based on a VM name
Get-CimInstance -Namespace root\virtualization\v2 -class Msvm_VirtualSystemSettingData -Filter "elementname = 'TEST01-ISO'"

# Get VMName, Serial Number, and GUID
$VMName = "TEST01-ISO"
Get-WmiObject -Namespace root\virtualization\v2 -class Msvm_VirtualSystemSettingData | 
    Where-Object { $_.elementname -eq $VMName } | 
    Select-Object elementname, BIOSSerialNumber, BIOSGuid | 
    Sort-Object -Property elementname

Get-VMNetworkAdapter -VMName $VMName 