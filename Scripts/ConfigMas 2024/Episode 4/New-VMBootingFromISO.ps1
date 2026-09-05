<#
.SYNOPSIS
    Creates a Hyper-V virtual machine that boots from a specified ISO.
.DESCRIPTION
    Builds a Generation 2 virtual machine with a fixed MAC address, so the machine can be
    pre-imported into ConfigMgr before it is started.
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

# Prereqs: 
# Hyper-V Console and PowerShell cmdlets

# VM Settings
$VMName = "W11-LAB-001"
$MacAddress = "00:15:5D:40:51:CD"
$VMMemory = 16384MB
$VMDiskSize = 240GB
$vCPUCount = 4
$VMNetwork = "Chicago1"
$VMISO = "C:\ISO\Bootimage_NoPrompt.iso"
$VMLocation = "C:\VMs"

# Create Gen 2 VM, booting from ISO file
New-VM -Name $VMName -Generation 2 -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD
    
New-VHD -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize
Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx"
$CD = Set-VMDvdDrive -VMName $VMName -Path $VMISO
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false
  
Set-VMProcessor -VMName $VMName -Count $vCPUCount
Set-VMNetworkAdapter -VMName $VMName -StaticMacAddress $MacAddress
$Disk = Get-VMHardDiskDrive -VMName $VMName
$Network = Get-VMNetworkAdapter -VMName $VMName

# When booting from ISO with prompt disabled, set boot order to disk first
Set-VMFirmware -VMName $VMName -FirstBootDevice $Disk

# Start the VM 
Start-VM $VMName 

# Connect to the virtual machine
VMConnect localhost $VMName

