<#
.SYNOPSIS
    Reads the serial number and SMBIOS GUID of a Hyper-V virtual machine.
.DESCRIPTION
    Queries the Hyper-V virtualization WMI namespace on the host, which returns the values
    needed to pre-stage a machine for PXE boot without starting the guest.
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
      1.0.0 - 2022-12-08 - Initial release
#>

$VMName = "DEMO-OSD-PC0014 (Liverpool)"

# Get VMName, Serial Number, and GUID
Get-WmiObject -Namespace root\virtualization\v2 -class Msvm_VirtualSystemSettingData | 
    Where-Object { $_.elementname -eq $VMName } | 
    Select-Object elementname, BIOSSerialNumber, BIOSGuid | 
    Sort-Object -Property elementname

# Get network card info
Get-VMNetworkAdapter -VMName $VMName
