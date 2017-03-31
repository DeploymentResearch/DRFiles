$ISO = "C:\Setup\ISO\Windows Server 2016.iso"
$CU = "C:\Setup\CU\windows10.0-kb3201845-x64_95e1e765344e1388fee3f7c0c143499e0b617d9f.msu"
$MountFolder = "C:\Mount"
$RefImage = "C:\Setup\REFWS2016-001.wim"
 
# Verify that the ISO and CU files existnote
if (!(Test-Path -path $ISO)) {Write-Warning "Could not find Windows Server 2016 ISO file. Aborting...";Break}
if (!(Test-Path -path $CU)) {Write-Warning "Could not find Cumulative Update for Windows Server 2016. Aborting...";Break}
 
# Mount the Windows Server 2016 ISO
Mount-DiskImage -ImagePath $ISO
$ISOImage = Get-DiskImage -ImagePath $ISO | Get-Volume
$ISODrive = [string]$ISOImage.DriveLetter+":"
 
# Extract the Windows Server 2016 Standard index to a new WIM
Export-WindowsImage -SourceImagePath "$ISODrive\Sources\install.wim" -SourceName "Windows Server 2016 SERVERSTANDARD" -DestinationImagePath $RefImage
 
# Add the KB3201845 CU to the Windows Server 2016 Standardimage
if (!(Test-Path -path $MountFolder)) {New-Item -path $MountFolder -ItemType Directory}
Mount-WindowsImage -ImagePath $RefImage -Index 1 -Path $MountFolder
Add-WindowsPackage -PackagePath $CU -Path $MountFolder
 
# Add .NET Framework 3.5.1 to the Windows Server 2016 Standard image
Add-WindowsPackage -PackagePath $ISODrive\sources\sxs\microsoft-windows-netfx3-ondemand-package.cab -Path $MountFolder
 
# Dismount the Windows Server 2016 Standard image
DisMount-WindowsImage -Path $MountFolder -Save
 
# Dismount the Windows Server 2016 ISO
Dismount-DiskImage -ImagePath $ISO
