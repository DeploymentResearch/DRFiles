# Note #1: 
# To service a newer version of WinPE than the OS you are servicing from, for example service Windows 10 v1709 
# from a Windows Server 2019 server, you need a newer DISM version.
# Solution, simply install the latest Windows ADK 10, and use DISM from that version
#
# Note #2:
# If your Windows OS already have a newer version of dism, uncomment the below line, and comment out line 11 and 12
# $DISMFile = 'dism.exe'

$DISMFile = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\DISM\dism.exe'
If (!(Test-Path $DISMFile)){ Write-Warning "DISM in Windows ADK not found, aborting..."; Break }

$ISO = "C:\Setup\en_windows_server_2019_x64_dvd_4cb967d8.iso"
$LCU = "C:\Setup\windows10.0-kb4480116-x64_4c8672ed7ce1d839421a36c681f9d3f64c31fe37.msu"
$SSU = "C:\Setup\windows10.0-kb4470788-x64_76f112f2b02b1716cdc0cab6c40f73764759cb0d.msu"
$MountFolder = "C:\Setup\Mount"
$RefImageFolder = "C:\Setup\RefImage"
$TmpImage = "$RefImageFolder\tmp_install.wim"
$RefImage = "$RefImageFolder\REFWS2019-001.wim"

# Verify that the ISO and CU files existnote
if (!(Test-Path -path $ISO)) {Write-Warning "Could not find Windows Server 2019 ISO file. Aborting...";Break}
if (!(Test-Path -path $SSU)) {Write-Warning "Could not find servicing stack Update for Windows Server 2019. Aborting...";Break}
if (!(Test-Path -path $LCU)) {Write-Warning "Could not find Cumulative Update for Windows Server 2019. Aborting...";Break}
if (!(Test-Path -path $MountFolder)) {New-Item -path $MountFolder -ItemType Directory}
if (!(Test-Path -path $RefImageFolder)) {New-Item -path $RefImageFolder -ItemType Directory}

# Mount the Windows Server 2019 ISO
Write-Output "Mounting the ISO."
Mount-DiskImage -ImagePath $ISO
$ISOImage = Get-DiskImage -ImagePath $ISO | Get-Volume
$ISODrive = [string]$ISOImage.DriveLetter+":"
 
# Export the Windows Server 2019 Standard index to a new WIM
Write-Output "Exporting the Server Standard image."
Export-WindowsImage -SourceImagePath "$ISODrive\Sources\install.wim" -SourceName "Windows Server 2019 SERVERSTANDARD" -DestinationImagePath $TmpImage

# Mount the image
Write-Output "Mounting the WIM."
Mount-WindowsImage -ImagePath $TmpImage -Index 1 -Path $MountFolder

# Add the latest SSU to the Windows Server 2019 Standard image
Write-Output "Installing the SSU."
Add-WindowsPackage -PackagePath $SSU -Path $MountFolder
 
# Add the latest CU (LCU) to the Windows Server 2019 Standard image
Write-Output "Installing the LCU."
Add-WindowsPackage -PackagePath $LCU -Path $MountFolder

# Cleanup the image BEFORE installing .NET to prevent errors
# Using the /ResetBase switch with the /StartComponentCleanup parameter of DISM.exe on a running version of Windows removes all superseded versions of every component in the component store.
# https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/clean-up-the-winsxs-folder#span-iddismexespanspan-iddismexespandismexe
Write-Output "Cleaning up the image."
& $DISMFile /Image:$MountFolder /Cleanup-Image /StartComponentCleanup /ResetBase

# Add .NET Framework 3.5.1 to the Windows Server 2019 Standard image
Write-Output "Installing .Net Framework 3.5."
Add-WindowsCapability -Name NetFx3~~~~ –Source $ISODrive\sources\sxs\ -Path $MountFolder

# Re-apply latest CU (LCU) because of .NET changes
Write-Output "Reapplying the LCU due to .NET changes."
Add-WindowsPackage -PackagePath $LCU -Path $MountFolder
 
# Dismount the Windows Server 2019 Standard image
Write-Output "Dismounting the WIM."
DisMount-WindowsImage -Path $MountFolder -Save

# Export the Windows Server 2019 index to a new WIM (the export operation reduces the WIM size with about 100 MB or so)
Write-Output "Exporting the new WIM."
Export-WindowsImage -SourceImagePath $TmpImage -SourceIndex "1" -DestinationImagePath $RefImage

# Remove the temporary WIM
Write-Output "Delete the temporary WIM."
if (Test-Path -path $TmpImage) {Remove-Item -Path $TmpImage -Force}

 
# Dismount the Windows Server 2019 ISO
Write-Output "Dismounting the ISO."
Dismount-DiskImage -ImagePath $ISO
