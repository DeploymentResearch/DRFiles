# Single Export 20H2
$ISO = "E:\ISO\Windows 10 Business Editions x64 20H2 (updated March 2021).iso"
$WIM = "C:\Ref\REFW10-X64-20H2-March-2021-Enterprise.wim"
Mount-DiskImage -ImagePath $ISO
$ISOImage = Get-DiskImage -ImagePath $ISO | Get-Volume
$ISODrive = [string]$ISOImage.DriveLetter+":"
Export-WindowsImage -SourceImagePath "$ISODrive\sources\install.wim" -SourceName "Windows 10 Enterprise" -DestinationImagePath $WIM 
Dismount-DiskImage -ImagePath $ISO