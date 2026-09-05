<#
.SYNOPSIS
    Creates a Hyper-V virtual machine that boots from MDT Lite Touch media.
.DESCRIPTION
    Builds a Generation 2 virtual machine configured to boot from the LiteTouchMedia ISO, for
    demonstrating media based deployments.
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
      1.0.0 - 2022-12-15 - Initial release
#>

$VMLocation = "E:\VMs"
$VMISO = "D:\ISO\LiteTouchMedia.iso"
$VMNetwork = "Stockholm"

# Create VM
$VMName = "MDTMEDIA-001"
$VMMemory = 4096MB
$VMDiskSize = 250GB
New-VM -Name $VMName -Generation 2 -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD -Verbose
New-VHD -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize -Verbose
Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -Verbose
Set-VMProcessor -VMName $VMName -Count 2
Set-VMDvdDrive -VMName $VMName -Path $VMISO -Verbose
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false

# For Windows 10 or Windows 11 Hyper-V hosts, disable automatic checkpoints
$OSCaption = (Get-WmiObject win32_operatingsystem).caption
If (($OSCaption -like "Microsoft Windows 10*") -or ($OSCaption -like "Microsoft Windows 11*")){
    Set-VM -Name $VMName -AutomaticCheckpointsEnabled $false
}

# Start the VM
Start-VM -Name $VMName
VMConnect localhost $VMName

