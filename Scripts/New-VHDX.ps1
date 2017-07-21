<#
Created:	 2013-12-16
Version:	 1.0
Author       Mikael Nystrom and Johan Arwidmark       
Homepage:    http://www.deploymentfundamentals.com

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and 
is not supported by the authors or DeploymentArtist.

Author - Mikael Nystrom
    Twitter: @mikael_nystrom
    Blog   : http://deploymentbunny.com

Author - Johan Arwidmark
    Twitter: @jarwidmark
    Blog   : http://deploymentresearch.com
#>

Param(
[Parameter(mandatory=$True,HelpMessage="Name and path of WIM file.")]
[ValidateNotNullOrEmpty()]
$WIMfile,

[parameter(mandatory=$True,HelpMessage="Name and path of VHDx file.")]
[ValidateNotNullOrEmpty()]
$VHDXFile
)

# Set values
$SizeinGB = 60
$Size = $SizeinGB*1024*1024*1024

# Check if WIM file exist
$WIMfileCheck = Test-Path $WIMfile
if ($WIMfileCheck -like $False){
    Write-Host "There seems to be a problem accessing $WIMfile."
    Write-Host "Verify that $WIMfile exist."
    Exit
}else{
    Write-host "Access to $WIMfile seems to be ok"
}

#Check for VHD file
$VHDFileCheck = Test-Path $VHDXFile
if ($VHDFileCheck -like $True){
    Write-Host "File already exists"
    Exit
}
else
{
}


# Create VHDX
New-VHD -Path $VHDXFile -Dynamic -SizeBytes $size 
Mount-DiskImage -ImagePath $VHDXFile 
$VHDXDisk = Get-DiskImage -ImagePath $VHDXFile | Get-Disk 
$VHDXDiskNumber = [string]$VHDXDisk.Number

# Format VHDx
Initialize-Disk -Number $VHDXDiskNumber –PartitionStyle GPT 
$VHDXDrive1 = New-Partition -DiskNumber $VHDXDiskNumber -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' -Size 499MB  
$VHDXDrive1 | Format-Volume -FileSystem FAT32 -NewFileSystemLabel System -Confirm:$false 
$VHDXDrive2 = New-Partition -DiskNumber $VHDXDiskNumber -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' -Size 128MB
$VHDXDrive3 = New-Partition -DiskNumber $VHDXDiskNumber -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' -UseMaximumSize 
$VHDXDrive3 | Format-Volume -FileSystem NTFS -NewFileSystemLabel OSDisk -Confirm:$false 
Add-PartitionAccessPath -DiskNumber $VHDXDiskNumber -PartitionNumber $VHDXDrive1.PartitionNumber -AssignDriveLetter
$VHDXDrive1 = Get-Partition -DiskNumber $VHDXDiskNumber -PartitionNumber $VHDXDrive1.PartitionNumber
Add-PartitionAccessPath -DiskNumber $VHDXDiskNumber -PartitionNumber $VHDXDrive3.PartitionNumber -AssignDriveLetter
$VHDXDrive3 = Get-Partition -DiskNumber $VHDXDiskNumber -PartitionNumber $VHDXDrive3.PartitionNumber
$VHDXVolume1 = [string]$VHDXDrive1.DriveLetter+":"
$VHDXVolume3 = [string]$VHDXDrive3.DriveLetter+":"

# Apply Image
$LogPath = split-path -parent $MyInvocation.MyCommand.Path
Expand-WindowsImage -ImagePath $WIMfile -Index 1 -ApplyPath $VHDXVolume3\ -LogPath $LogPath\dismlog.txt 

# Apply BootFiles
cmd /c "$VHDXVolume3\Windows\system32\bcdboot $VHDXVolume3\Windows /s $VHDXVolume1 /f UEFI"

# Change ID on FAT32 Partition
$DiskPartTextFile = New-Item "diskpart.txt" -type File -Force
Set-Content $DiskPartTextFile "select disk $VHDXDiskNumber" 
Add-Content $DiskPartTextFile "Select Partition 2" 
Add-Content $DiskPartTextFile "Set ID=c12a7328-f81f-11d2-ba4b-00a0c93ec93b OVERRIDE" 
Add-Content $DiskPartTextFile "GPT Attributes=0x8000000000000000" 
$DiskPartTextFile
cmd /c "diskpart.exe /s .\diskpart.txt"

# Dismount VHDX
Dismount-DiskImage -ImagePath $VHDXFile 
