# Script to create a VM for Intune and Autopilot testing
# Requirements: VHDX file of sysprepped Windows 10 or Windows 11 (can be default ISO from Microsoft)
#
# TIP: To convert an existing WIM image to VHDX file, use Convert-WindowsImage.ps1 from https://github.com/nerdile/convert-windowsimage 
# For example syntax, see  https://github.com/DeploymentResearch/DRFiles/blob/master/Scripts/AutoPilot/Convert-WindowsImage-Syntax.ps1
#
# Author: Johan Arwidmark
# Twitter: @jarwidmark
# LinkedIn: https://www.linkedin.com/in/jarwidmark

# Set some variables
$VMLocation = "E:\VMs"
$VMNetwork = "Chicago1"
$VMMemory = 4096MB
$RefVHD = "C:\VHDs\AP-W11-22H2.vhdx"
$Unattend = "E:\Demo\Windows Autopilot\Unattend_for_windows_only.xml"


$VMs = @(
    "APTEST205"
    "APTEST206"
    "APTEST207"
    "APTEST208"
    "APTEST209"
)

# Verify that specified files exist
If (!(Test-Path $Unattend)){ Write-Warning "Unattend.xml file not found, aborting...";Break}
If (!(Test-Path $RefVHD)){ Write-Warning "Parent VHDX file not found, aborting...";Break}

foreach ($VMName in $VMs){

    # Create a new VHDX file
    $VHDFileName = Split-Path $RefVHD -Leaf
    $TargetVHDPath = "$VMLocation\$VMName\Virtual Hard Disks"
    New-Item -Path $TargetVHDPath -ItemType Directory
    Copy-Item -Path $RefVHD -Destination $TargetVHDPath
    Mount-DiskImage -ImagePath "$TargetVHDPath\$VHDFileName"
    $VHDXDisk = Get-DiskImage -ImagePath "$TargetVHDPath\$VHDFileName" | Get-Disk
    $VHDXDiskNumber = [string]$VHDXDisk.Number
    $VHDXDrive = Get-Partition -DiskNumber $VHDXDiskNumber -PartitionNumber 3
    $VHDXVolume = [string]$VHDXDrive.DriveLetter+":"

    # Copy unattend.xml to the mounted disk
    Copy-Item -Path $Unattend -Destination "$VHDXVolume\Windows\system32\Sysprep\Unattend.xml"
    
    # Remove Convert-WindowsImageInfo.txt file
    If (Test-Path "$VHDXVolume\Convert-WindowsImageInfo.txt"){Remove-Item -Path "$VHDXVolume\Convert-WindowsImageInfo.txt" -Force}

    # Update ComputerName in unattend.xml
    $UnattendFileToModify = "$VHDXVolume\Windows\system32\Sysprep\Unattend.xml"
    [xml]$xml = get-content $UnattendFileToModify 
    $xml.unattend.settings.component[1].computername = "$VMName"
    $xml.save("$UnattendFileToModify")

    # Dismount the disk
    Dismount-DiskImage -ImagePath "$TargetVHDPath\$VHDFileName"

    # Create the VM
    New-VM -Name $VMName -Generation 2 -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -VHDPath "$TargetVHDPath\$VHDFileName" -Verbose 
    Set-VMProcessor -VMName $VMName -Count 2

    # Start the virtual machine
    Start-VM -VMName $VMName
}