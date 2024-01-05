# Script to create nested VM
# Author: Johan Arwidmark
# Twitter: @jarwidmark
# LinkedIn: https://www.linkedin.com/in/jarwidmark

# Set some variables
$VMName = "ROGUE-035"
$VMLocation = "F:\VMs"
$VMNetwork = "VOA-Lab"
$vCPUs = 8
$VMMemory = 64GB
$VMDiskSize = 512GB
$VMISO = "D:\ISO\VOA Lab TS-MDT01 MDT Production x64.iso"

# Quick Sanity Check

    # Check for Hyper-V Switch
    If (-not(Get-VMSwitch -Name $VMNetwork -ErrorAction SilentlyContinue)) {
        Write-Warning "Switch $VMNetwork does not exist, aborting..."
        Break
    }

    # Check for free disk space
    $DriveLetter = Split-Path -Path $VMLocation -Qualifier
    $Disk = Get-wmiObject Win32_LogicalDisk -Filter "DeviceID='$DriveLetter'" 
    if($Disk.FreeSpace  -lt $VMDiskSize){
        Write-Warning "Oupps, you need at least $($VMDiskSize/1GB) GB of free disk space, aborting..."
        Write-Warning "Available free space on $DriveLetter is $([MATH]::ROUND($Disk.FreeSpace/1GB)) GB"
        Write-Warning "Aborting script..."
        Break
    }

    # Check for Boot Media
    If (-not(Test-Path $VMISO)){ 
        Write-Warning "Boot Media not found in $VMISO, aborting..."
        Break
    }

# Create Gen 2 VM 
New-VM -Name $VMName -Generation 2 -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD
New-VHD -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize
Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx"
Set-VMDvdDrive -VMName $VMName -Path $VMISO
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false
  
# The ExposeVirtualizationExtensions switch enables Nested VMs
Set-VMProcessor -VMName $VMName -Count $vCPUs -ExposeVirtualizationExtensions $true
Set-VMNetworkAdapter -VMName $VMName
$Disk = Get-VMHardDiskDrive -VMName $VMName
$Network = Get-VMNetworkAdapter -VMName $VMName

# When booting from ISO without prompt, set boot order to disk first
Set-VMFirmware -VMName $VMName -FirstBootDevice $Disk

# Set Checkpoint Type to Standard
Set-VM -Name $VMName -CheckpointType Standard

# Start the virtual machine
Start-VM -VMName $VMName

# Connect to the virtual machine
VMConnect localhost $VMName
