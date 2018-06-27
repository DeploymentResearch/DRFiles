# Note: 
# To service a newer version of WinPE than the OS you are servicing from.
# For example service WinPE v1709 from a Windows Server 2016 server, you need a newer DISM version.
# Solution: Simply install the latest Windows ADK 10, and use DISM from that version

# If your Windows OS already have a newer version of dism, uncomment the below line, and comment out line 10 and 11
# $DISMFile = 'dism.exe'

# Select DISM version to use
$DISMFile = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\DISM\dism.exe'
If (!(Test-Path $DISMFile)){ Write-Warning "DISM in Windows ADK not found, aborting..."; Break }

$ISO = "C:\Setup\ISO\Windows 10 Business Editions x64 v1709.iso"
$ServicingUpdate = "C:\Setup\Updates\windows10.0-kb4132650-x64_80c6e23ef266c2848e69946133cc800a5ab9d6b3.msu"
$AdobeFlashUpdate = "C:\Setup\Updates\windows10.0-kb4093110-x64_2422543693a0939d7f7113ac13d97a272a3770bb.msu"
$MonthlyCU = "C:\Setup\Updates\windows10.0-kb4103714-x64_97bad62ead2010977fa1e9b5226e77dd9e5a5cb7.msu"
$MountFolder = "C:\Mount"
$RefImage = "C:\Ref\REFWS10-X64-001.wim"

# Verify that the ISO and CU files existnote
if (!(Test-Path -path $ISO)) {Write-Warning "Could not find Windows 10 ISO file. Aborting...";Break}
if (!(Test-Path -path $ServicingUpdate)) {Write-Warning "Could not find Servicing Update for Windows 10. Aborting...";Break}
if (!(Test-Path -path $AdobeFLashUpdate)) {Write-Warning "Could not find Adobe Flash Update for Windows 10. Aborting...";Break}
if (!(Test-Path -path $MonthlyCU)) {Write-Warning "Could not find Monthly Update for Windows 10. Aborting...";Break}

# Mount the Windows Server 10 ISO
Mount-DiskImage -ImagePath $ISO
$ISOImage = Get-DiskImage -ImagePath $ISO | Get-Volume
$ISODrive = [string]$ISOImage.DriveLetter+":"

# Extract the Windows Server 10 Standard index to a new WIM
Export-WindowsImage -SourceImagePath "$ISODrive\Sources\install.wim" -SourceName "Windows 10 Enterprise" -DestinationImagePath $RefImage

# Mount the exported Windows 10 Enterprise image
if (!(Test-Path -path $MountFolder)) {New-Item -path $MountFolder -ItemType Directory}
Mount-WindowsImage -ImagePath $RefImage -Index 1 -Path $MountFolder

# Add .NET Framework 3.5.1 to the Windows 10 image 
& $DISMFile /Image:$MountFolder /Add-Package /PackagePath:$ISODrive\sources\sxs\microsoft-windows-netfx3-ondemand-package.cab 

# Add the Updates to the Windows 10 Enterprise image
& $DISMFile /Image:$MountFolder /Add-Package /PackagePath:$ServicingUpdate
& $DISMFile /Image:$MountFolder /Add-Package /PackagePath:$AdobeFlashUpdate
& $DISMFile /Image:$MountFolder /Add-Package /PackagePath:$MonthlyCU

# Dismount the Windows 10 image
DisMount-WindowsImage -Path $MountFolder -Save

# Dismount the Windows 10 ISO
Dismount-DiskImage -ImagePath $ISO
 