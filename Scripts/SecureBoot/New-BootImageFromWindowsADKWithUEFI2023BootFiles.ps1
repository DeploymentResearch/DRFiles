<#
.SYNOPSIS
	Script to create a boot image from Windows ADK, and apply LCU to reach specific patch-level
	
.DESCRIPTION
    Script to create a boot image from Windows ADK, and apply LCU to reach specific patch-level

.EXAMPLE
	.\New-BootImageFromWindowsADKWithUEFI2023BootFiles.ps1

.NOTES
	Author:      Johan Arwidmark
    Contact:     @jarwidmark
    Created:     May 1, 2026
    Updated:     May 1, 2026
	
    Version history:
    1.0.0 - May 1, 2026 - Initital version
#>

# Settings
$CUVersion="2026-04"
$CUPath = "C:\Setup\Windows 11 24H2 Updates\$CUVersion"

$WinPE_BuildFolder = "C:\Setup\WinPE11_24H2"
$WinPE_MediaFolder = "$WinPE_BuildFolder\Media"
$WinPE_2023Bootbins = "$WinPE_BuildFolder\2023Bootbins"
$WinPE_Architecture = "amd64"
$WinPE_MountFolder = "$WinPE_BuildFolder\Mount"
$WinPE_ISOFolder = "C:\ISO"
$WinPE_ISOfile = "$WinPE_ISOFolder\$($CUVersion)_WinPE11_24H2_PowerShell_With_UEFI2023_BootFiles.iso"

$ScratchDir = "$WinPE_BuildFolder\ScratchDir"
$LogFolder = "$WinPE_BuildFolder\Logs"
$DISMLog = "$LogFolder\dism.log"
$DISMLoglevel = 4 

$ADK_Path = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit"
$WinPE_ADK_Path = $ADK_Path + "\Windows Preinstallation Environment"
$WinPE_OCs_Path = $WinPE_ADK_Path + "\$WinPE_Architecture\WinPE_OCs"
$DISM_Path = $ADK_Path + "\Deployment Tools" + "\$WinPE_Architecture\DISM"
$OSCDIMG_Path = $ADK_Path + "\Deployment Tools" + "\$WinPE_Architecture\Oscdimg"

# Validate locations
If (!(Test-path $OSCDIMG_Path)){ Write-Warning "OSCDIMG_Path path: $OSCDIMG_Path does not exist, aborting...";Break}
If (!(Test-path $CUPath)){ Write-Warning "CUPath path: $CUPath does not exist, aborting...";Break}
$CUFiles = Get-ChildItem "$CUPath\*.msu"
If (!($CUFiles)){ Write-Warning "CUPath path exist, but has no MSU files. aborting...";Break} 

# Delete existing WinPE build folder (if exist)
try 
{
if (Test-Path -path $WinPE_BuildFolder) {Remove-Item -Path $WinPE_BuildFolder -Recurse -ErrorAction Stop}
}
catch
{
    Write-Warning "Oupps, Error: $($_.Exception.Message)"
    Write-Warning "Most common reason is existing WIM still mounted, use DISM /Cleanup-Wim to clean up and run script again"
    Break
}

# Create Build folder structure
New-Item -Path $WinPE_BuildFolder -ItemType Directory -Force
New-Item -Path $WinPE_MediaFolder -ItemType Directory -Force
New-Item -Path $WinPE_2023Bootbins -ItemType Directory -Force
New-Item -Path $WinPE_MountFolder -ItemType Directory -Force
New-Item -Path $ScratchDir -ItemType Directory -Force
New-Item -Path $LogFolder -ItemType Directory -Force

# Create ISO folder
New-Item -Path $WinPE_ISOFolder -ItemType Directory -Force

# Make a copy of the WinPE boot image from Windows ADK
if (!(Test-Path -path "$WinPE_MediaFolder\Sources")) {New-Item "$WinPE_MediaFolder\Sources" -Type Directory}
Copy-Item "$WinPE_ADK_Path\$WinPE_Architecture\en-us\winpe.wim" "$WinPE_MediaFolder\Sources\boot.wim"

# Copy WinPE boot files
Copy-Item "$WinPE_ADK_Path\$WinPE_Architecture\Media\*" "$WinPE_MediaFolder" -Recurse

# Mount the WinPE image
$WimFile = "$WinPE_MediaFolder\Sources\boot.wim"
Mount-WindowsImage -ImagePath $WimFile -Path $WinPE_MountFolder -Index 1

# Copy 2023 signed efisys files for later use
# Fun fact, it's really a floppy disk image. More specifically, a 1.44 MB FAT12 filesystem image
Copy-Item -Path "$OSCDIMG_Path\efisys_EX.bin" -Destination "$WinPE_2023Bootbins"
Copy-Item -Path "$OSCDIMG_Path\efisys_noprompt_EX.bin" -Destination "$WinPE_2023Bootbins"

# Add native WinPE optional components (using ADK version of dism.exe instead of Add-WindowsPackage)
# Install WinPE-WMI before you install WinPE-NetFX (dependency)

# VBScript (WinPE-Scripting)
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-Scripting.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-Scripting_en-us.cab

# WMI (WinPE-WMI)
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-WMI.cab 
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-WMI_en-us.cab

# Startup (WinPE-SecureStartup) Requires WinPE-WMI
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-SecureStartup.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-SecureStartup_en-us.cab

# Microsoft .NET (WinPE-NetFx) Requires WinPE-WMI
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-NetFx.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-NetFx_en-us.cab

# Windows PowerShell (WinPE-PowerShell) Requires WinPE-WMI and WinPE-NetFx
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-PowerShell.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-PowerShell_en-us.cab

# DISM Cmdlets (WinPE-DismCmdlets) Requires WinPE-WMI, WinPE-NetFx, and WinPE-PowerShell
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-DismCmdlets.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-DismCmdlets_en-us.cab

# Secure Boot Cmdlets (WinPE-SecureBootCmdlets) Requires WinPE-WMI, WinPE-NetFx, and WinPE-PowerShell
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-SecureBootCmdlets.cab

# # Windows PowerShell (WinPE-StorageWMI) Requires WinPE-WMI, WinPE-NetFx, and WinPE-PowerShell
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-StorageWMI.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-StorageWMI_en-us.cab

# Storage (WinPE-EnhancedStorage) 
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-EnhancedStorage.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-EnhancedStorage_en-us.cab

# HTML (WinPE-HTA) Requires WinPE-Scripting
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-HTA.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-HTA_en-us.cab

# Adding updates using ADK version of dism.exe instead of Add-WindowsPackage (Add-WindowsPackage may be older depending on host OS)
# - Selecting only the latest file by name (again, it will look for other files in that folder)
# - Loglevel 4 is debug, useful for troubleshooting
#
# Notes about update files...
#
# When applying updates for WinPE, the script only applies the larger file. The update process will find the other file automatically.
# Example: The 2025-10 cumulative update for Windows 11 24H2 has two files in it
# - windows11.0-kb5043080-x64_953449672073f8fb99badb4cc6d5d7849b9c83e8.msu, 0.5 GB
# - windows11.0-kb5067036-x64_78c6126284e496eec36b70537a69c5f76eb07322.msu, 3.67 GB
If ($CUPath) {
    Get-ChildItem "$CUPath\*.msu" | Sort-Object -Property Name | Select-Object -Last 1 | ForEach-Object {
        Write-Host "Applying file: $($_.Name)"
        & $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$($_.FullName) /ScratchDir:$ScratchDir /LogPath:$DISMLog /LogLevel:$DISMLoglevel
    }
}

# Cleanup the image
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Cleanup-image /StartComponentCleanup /Resetbase

# Copy updated 2023 signed boot files for later use
Copy-Item -Path "$WinPE_MountFolder\Windows\Boot\EFI_EX\bootmgfw_EX.efi" -Destination "$WinPE_2023Bootbins"
Copy-Item -Path "$WinPE_MountFolder\Windows\Boot\EFI_EX\bootmgr_EX.efi" -Destination "$WinPE_2023Bootbins"

# Unmount the WinPE image and save changes
Dismount-WindowsImage -Path $WinPE_MountFolder -Save

# Copy the UEFI 2023 files from the 2023Bootbins folder (Yes, bootmgfw_EX.efi is copied to two locations and renamed in the process)
Copy-Item -Path "$WinPE_2023Bootbins\bootmgfw_EX.efi" -Destination "$WinPE_MediaFolder\EFI\BOOT\bootx64.efi"
Copy-Item -Path "$WinPE_2023Bootbins\bootmgfw_EX.efi" -Destination "$WinPE_MediaFolder\EFI\MICROSOFT\BOOT\bootmgfw.efi"
Copy-Item -Path "$WinPE_2023Bootbins\bootmgr_EX.efi" -Destination "$WinPE_MediaFolder\bootmgr.efi" 

# Create a bootable WinPE ISO file for UEFI (only) using a single entry syntax (comment out if you don't need the ISO)
$BootData='1#pEF,e,b"{0}"' -f "$WinPE_2023Bootbins\efisys_EX.bin"
  
$Proc = Start-Process -FilePath "$OSCDIMG_Path\oscdimg.exe" -ArgumentList @("-bootdata:$BootData",'-u2','-udfver102',"$WinPE_MediaFolder","$WinPE_ISOfile") -PassThru -Wait -NoNewWindow
if($Proc.ExitCode -ne 0)
{
    Throw "Failed to generate ISO with exitcode: $($Proc.ExitCode)"
}
