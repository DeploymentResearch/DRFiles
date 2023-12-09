# Note #1: 
# To service a newer version of WinPE than the OS you are servicing from,you need a newer DISM version.
# Solution, simply install the latest Windows ADK, and use DISM from that version
#
# Note #2:
# If your Windows OS already have a newer version of dism, uncomment the below line, and comment out line 10
# $DISMFile = 'dism.exe'

# Configuring the script to use the Windows ADK 10 version of DISM
$DISMFile = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\DISM\dism.exe'
$WinPECU = "E:\Setup\Windows Update For Windows ADK SEP 2023 - Build 25398\windows11.0-kb5032202-x64_4adcdf7b5de0c8498b4739583eb36f89b3865494.msu"
$BootImageMountFolder = "C:\Mount_BootImage"
$BootImage = "E:\MDTProduction\Boot\LiteTouchPE_x64.wim"

# Verify that files and folder exist
If (!(Test-Path $DISMFile)){ Write-Warning "DISM in Windows ADK not found, aborting..."; Break }
if (!(Test-Path -path $WinPECU)) {Write-Warning "Could not find WiNpe Update. Aborting...";Break}
if (!(Test-Path -path $BootImage)) {Write-Warning "Could not find Boot image. Aborting...";Break}

# Create Mount folder if it does not exist
if (!(Test-Path -path $BootImageMountFolder)) {New-Item -path $BootImageMountFolder -ItemType Directory}

# Mount the Boot image
Mount-WindowsImage -ImagePath $BootImage -Index 1 -Path $BootImageMountFolder

# Add the Update to the Boot image
& $DISMFile /Image:$BootImageMountFolder /Add-Package /PackagePath:$WinPECU

# Optional - Cleanup the Boot image
# & $DISMFile /Image:$BootImageMountFolder /Cleanup-Image /StartComponentCleanup /ResetBase 
    
# Dismount the Boot image
DisMount-WindowsImage -Path $BootImageMountFolder -Save

