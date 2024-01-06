# Settings
$WorkingFolder = "C:\ISO\DEMO-OSD-CM01"
$InputISO =  "C:\ISO\DEMO-OSD-CM01\Bootimage.iso"
$ISOSourceFolder = "$WorkingFolder\ISO"
$OutputISOfile = "$WorkingFolder\BootimageTest.iso"
$MountPath = "$WorkingFolder\Mount"
$OSCDIMG_Path = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"

# Validate locations
If (!(Test-path $OSCDIMG_Path)){ Write-Warning "OSCDIMG Path does not exist, aborting...";Break}

# Delete ISO Folder if exist, and create empty folder
If (Test-path $ISOSourceFolder){
    Remove-Item -Path $ISOSourceFolder -Recurse -Force
    New-Item -Path $ISOSourceFolder -ItemType Directory
}
Else{
    New-Item -Path $ISOSourceFolder -ItemType Directory
}

# Delete Mount Folder if exist, and create empty folder
If (Test-path $MountPath){
    Remove-Item -Path $MountPath -Recurse -Force
    New-Item -Path $MountPath -ItemType Directory
}
Else{
    New-Item -Path $MountPath -ItemType Directory
}

# Mount the Boot Image ISO
Mount-DiskImage -ImagePath $InputISO
$ISOImage = Get-DiskImage -ImagePath $InputISO | Get-Volume
$ISODrive = [string]$ISOImage.DriveLetter+":"

# Copy content of ISO to ISO Source Folder
Copy-Item "$ISODrive\*" $ISOSourceFolder -Recurse

# Dismount the ISO 
Dismount-DiskImage -ImagePath $InputISO

# Remove the readonly attribute, and mount the Boot Image WIM file
$WimFile = "$ISOSourceFolder\Sources\Boot.wim"
Set-ItemProperty -Path $WimFile -Name IsReadOnly -Value $false
Mount-WindowsImage -ImagePath $WimFile -Path $MountPath -Index 1

# Do Whatever


# Unmount the Boot Image WIM file and save the changes
Dismount-WindowsImage -Path $MountPath -Save 

# Create a bootable WinPE ISO file
$BootData='2#p0,e,b"{0}"#pEF,e,b"{1}"' -f "$OSCDIMG_Path\etfsboot.com","$OSCDIMG_Path\efisys.bin"
   
$Proc = Start-Process -FilePath "$OSCDIMG_Path\oscdimg.exe" -ArgumentList @("-bootdata:$BootData",'-u2','-udfver102',"`"$ISOSourceFolder`"","`"$OutputISOfile`"") -PassThru -Wait -NoNewWindow
if($Proc.ExitCode -ne 0)
{
    Throw "Failed to generate ISO with exitcode: $($Proc.ExitCode)"
}

