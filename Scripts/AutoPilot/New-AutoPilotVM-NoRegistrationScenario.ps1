# Set some variables
$VMName = "APTEST01"
$VMLocation = "C:\VMs"
$VMNetwork = "New York"
$VMMemory = 2048MB
$RefVHD = "C:\VHDs\AP-1809.vhdx"
$DiffDisk = "$VMLocation\$VMName\$VMName-OSDisk.vhdx"
$Unattend = "C:\Setup\Scripts\Unattend_for_windows_autopilot_noregistration_scenario.xml"
# $SetupComplete = "C:\Setup\Scripts\SetupComplete.cmd"
$AutopilotProfile = "C:\Setup\Admin No Registration Autpilot Scenario.json"

# Cleanup existing VM (if it exist)
$VM = Get-VM $VMName -ErrorAction Ignore
If ($VM) {$VM | Remove-VM -Force}
If (Test-Path "$VMLocation\$VMName") { Remove-Item -Recurse "$VMLocation\$VMName" -Force  }

# Create a new VM
New-VHD -Path $DiffDisk -ParentPath $RefVHD -differencing
Mount-DiskImage -ImagePath $DiffDisk
$VHDXDisk = Get-DiskImage -ImagePath $DiffDisk | Get-Disk
$VHDXDiskNumber = [string]$VHDXDisk.Number
$VHDXDrive = Get-Partition -DiskNumber $VHDXDiskNumber 
$VHDXVolume = [string]$VHDXDrive.DriveLetter+":"

# Copy unattend.xml to differencing disk
Copy-Item $Unattend "$VHDXVolume\Windows\system32\Sysprep\Unattend.xml"

# Copy Windows Autopilot profile
If (!(Test-Path "$VHDXVolume\Windows\Provisioning\Autopilot")){ New-Item -ItemType Directory -Path "$VHDXVolume\Windows\Provisioning\Autopilot" }
Copy-Item $AutopilotProfile "$VHDXVolume\Windows\Provisioning\Autopilot\AutopilotConfigurationFile.json"

# Add SetupComplete command
# New-Item -Path "$VHDXVolume\Windows\Setup\Scripts" -ItemType Directory
# Copy-Item $SetupComplete "$VHDXVolume\Windows\Setup\Scripts"

# Dismount the differencing disk
Dismount-DiskImage -ImagePath $DiffDisk

# Create the virtual machine
New-VM -Name $VMName -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -VHDPath $DiffDisk -Verbose
Set-VMProcessor -VMName $VMName -Count 2

# Start the virtual machine
Start-VM -VMName $VMName


