# Script to extract the Windows Server 2019 Standard index from a Windows Server 2019 media.
# Update line 4 and 5 to match your environment

$ISO = "F:\ISO\Windows Server 2019 (updated August 2021).iso" # Path to Windows Server 2019 media
$WIMPath = "C:\Ref" # Target folder for extracted WIM file containing Windows Server 2019 Standard only
$WIMFile = "$WIMPath\REFWS2019-001.wim"
$Edition = "Windows Server 2019 Standard (Desktop Experience)" 

Mount-DiskImage -ImagePath $ISO | Out-Null
$ISOImage = Get-DiskImage -ImagePath $ISO | Get-Volume
$ISODrive = [string]$ISOImage.DriveLetter+":"
If (!(Test-path $WIMPath)){ New-Item -Path $WIMPath -ItemType Directory -Force | Out-Null } # Create folder if needed
Export-WindowsImage -SourceImagePath "$ISODrive\sources\install.wim" -SourceName $Edition -DestinationImagePath $WIMFile
Dismount-DiskImage -ImagePath $ISO | Out-Null