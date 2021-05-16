# Script to create a VM for Autopilot testing
# Requirements: VHDX file of sysprepped Windows 10 setup (can be default from Microsoft)
#
# TIP: To convert an existing WIM image to VHDX file, use Convert-WindowsImage.ps1 from https://github.com/nerdile/convert-windowsimage 
# For example syntax, see  https://github.com/DeploymentResearch/DRFiles/blob/master/Scripts/AutoPilot/Convert-WindowsImage-Syntax.ps1
#
# Author: Johan Arwidmark
# Twitter: @jarwidmark
# LinkedIn: https://www.linkedin.com/in/jarwidmark

# Set some variables
$VMName = "APTEST14"
$VMLocation = "C:\VMs"
$VMNetwork = "External"
$VMMemory = 4096MB
$RefVHD = "C:\VHDs\AP-20H2.vhdx"
$DiffDisk = "$VMLocation\$VMName\$VMName-OSDisk.vhdx"
$Unattend = "C:\Setup\Scripts\Unattend_for_windows_autopilot_registration_scenario.xml"
# $SetupComplete = "C:\Setup\Scripts\SetupComplete.cmd" 
$APScript = "C:\Setup\Scripts\Get-WindowsAutoPilotInfo.ps1"
$RemoveUnattendScript = "C:\Setup\Scripts\Remove-APUnattend.ps1"

# Varify that specified files exist
If (!(Test-Path $APScript)){ Write-Warning "Autopilot script not found, aborting...";Break}
If (!(Test-Path $Unattend)){ Write-Warning "Unattend.xml file not found, aborting...";Break}
If (!(Test-Path $RefVHD)){ Write-Warning "Parent VHDX file not found, aborting...";Break}

# Cleanup existing VM (if it exist)
$VM = Get-VM $VMName -ErrorAction Ignore
If ($VM) {$VM | Remove-VM -Force}
If (Test-Path "$VMLocation\$VMName") { Remove-Item -Recurse "$VMLocation\$VMName" -Force  }

# Create a new VM
New-VHD -Path $DiffDisk -ParentPath $RefVHD -differencing
Mount-DiskImage -ImagePath $DiffDisk
$VHDXDisk = Get-DiskImage -ImagePath $DiffDisk | Get-Disk
$VHDXDiskNumber = [string]$VHDXDisk.Number
$VHDXDrive = Get-Partition -DiskNumber $VHDXDiskNumber -PartitionNumber 3
$VHDXVolume = [string]$VHDXDrive.DriveLetter+":"

# Copy unattend.xml and other files to differencing disk
Copy-Item -Path $Unattend -Destination "$VHDXVolume\Windows\system32\Sysprep\Unattend.xml"
Copy-Item -Path $APScript -Destination "$VHDXVolume\Windows"
Copy-Item -Path $RemoveUnattendScript -Destination "$VHDXVolume\Windows"

# Update ComputerName in unattend.xml
$UnattendFileToModify = "$VHDXVolume\Windows\system32\Sysprep\Unattend.xml"
[xml]$xml = get-content $UnattendFileToModify 
$xml.unattend.settings.component[1].computername = "$VMName"
$xml.save("$UnattendFileToModify")

# Dismount the differencing disk
Dismount-DiskImage -ImagePath $DiffDisk

# Create the virtual machine
New-VM -Name $VMName -Generation 2 -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -VHDPath $DiffDisk -Verbose 
Set-VMProcessor -VMName $VMName -Count 2

# Start the virtual machine
Start-VM -VMName $VMName
