$VMName = "DEMO-OSD-PC0014 (Liverpool)"

# Get VMName, Serial Number, and GUID
Get-WmiObject -Namespace root\virtualization\v2 -class Msvm_VirtualSystemSettingData | 
    Where-Object { $_.elementname -eq $VMName } | 
    Select-Object elementname, BIOSSerialNumber, BIOSGuid | 
    Sort-Object -Property elementname

# Get network card info
Get-VMNetworkAdapter -VMName $VMName