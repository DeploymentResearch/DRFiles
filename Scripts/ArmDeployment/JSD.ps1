# Jurassic Deployment Start Script 
$OSImage = "W11-ARM64-22H2-Enterprise.wim"
$DriverPackage = "WindowsDevKit2023.wim"
$LocalCache = "W:\Cache"

# Run diskpart script for UEFI partitioning
$DPScriptContent = @(
    "SELECT DISK 0"
    "CLEAN"
    "CONVERT GPT NOERR"

    "CREATE PARTITION EFI Size=500"
    "Assign letter=S:"
    "FORMAT QUICK FS=FAT32 LABEL=System"

    "CREATE PARTITION MSR Size=128"

    "CREATE PARTITION Primary"
    "Assign letter=W:"
    "FORMAT QUICK FS=NTFS LABEL=Windows"

    "SHRINK MINIMUM=1024"

    "CREATE PARTITION Primary"
    "Assign letter=R:"
    "FORMAT QUICK FS=NTFS LABEL=Recovery"
    "SET ID = de94bba4-06d1-4d40-a16a-bfd50179d6ac"
    "GPT ATTRIBUTES = 0x8000000000000000"
) 

$DPScript = "$env:TEMP\Diskpart.txt"
$DPScriptContent | Out-File $DPScript
$Diskpart = Start-Process diskpart.exe "/s $DPScript" -NoNewWindow -Wait 

# Download and apply the WIM image
New-Item -Path $LocalCache -ItemType Directory -Force
Copy-Item -Path Z:\OS\$OSImage -Destination $LocalCache
DISM.exe /Apply-Image /ImageFile:$LocalCache\$OSImage /Index:1 /ApplyDir:W:\

# Prepare Boot Partition
BCDBoot.exe W:\windows /l en-US
bcdedit.exe /timeout 0

# Add drivers
Copy-Item -Path Z:\Drivers\$DriverPackage -Destination $LocalCache
New-Item -Path W:\Drivers -ItemType Directory
DISM.exe /Apply-Image /ImageFile:$LocalCache\$DriverPackage /Index:1 /ApplyDir:W:\Drivers

# Copy and Apply the Unattend.xml
New-Item -Path W:\Windows\Panther -ItemType Directory
Copy-Item -Path Z:\Unattend.xml -Destination W:\Windows\Panther
New-Item -Path W:\ScratchSpace -ItemType Directory
dism.exe /Image:W:\ /Apply-Unattend:W:\Windows\Panther\Unattend.xml /ScratchDir:W:\ScratchSpace
Remove-Item W:\ScratchSpace -Recurse -Force
Remove-Item W:\Drivers -Recurse -Force

# Reboot to Windows 
wpeutil reboot