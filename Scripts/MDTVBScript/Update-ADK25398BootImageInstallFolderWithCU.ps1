# Note #1: 
# To service a newer version of WinPE than the OS you are servicing from,you need a newer DISM version.
# Solution, simply install the latest Windows ADK, and use DISM from that version
#
# Note #2:
# If your Windows OS already have a newer version of dism, uncomment the below line, and comment out line 28
# $DISMFile = 'dism.exe'
#
# Note #3: If updating the ADK boot image in the ADK install folder, you need copy the the LiteTouchPE.xml template to
# your deployment share, the templates folder and remove the default components

# Configuring the script to use the Windows ADK 10 version of DISM

# Set path to the Windows Update for Windows Server, version 23H2 (used for ADK WinPE version 25398)
$WinPECU = "E:\Setup\Windows Server, version 23H2 Updates\2023-11\windows11.0-kb5032202-x64_4adcdf7b5de0c8498b4739583eb36f89b3865494.msu"

# Set architecture and mount folder
$WinPEArchitecture = "amd64"
$WinPEMountFolder = "C:\Mount"

# Get ADK folders
$InstalledRoots = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots'
$KitsRoot10 = Get-ItemPropertyValue -Path $InstalledRoots -Name 'KitsRoot10'
$AdkRoot = Join-Path $KitsRoot10 'Assessment and Deployment Kit'
$WinPERoot = Join-Path $AdkRoot 'Windows Preinstallation Environment'
$WinPEOCsRoot = Join-Path $WinPERoot\$WinPEArchitecture 'WinPE_OCs'
$DeploymentToolsRoot = Join-Path $AdkRoot (Join-Path 'Deployment Tools' $WinPEArchitecture)
$WinPERoot = Join-Path $WinPERoot $WinPEArchitecture

# Set path to dism.exe
$DISMFile = Join-Path $DeploymentToolsRoot 'DISM\Dism.exe'

# Set path to CU to the boot image
$BootImage = "$WinPERoot\en-us\winpe.wim"

# Verify that files and folder exist
If (!(Test-Path $DISMFile)){ Write-Warning "DISM in Windows ADK not found, aborting..."; Break }
if (!(Test-Path -path $WinPECU)) {Write-Warning "Could not find the Windows Server, version 23H2 update. Aborting...";Break}
if (!(Test-Path -path $BootImage)) {Write-Warning "Could not find Boot image. Aborting...";Break}

# Create Mount folder if it does not exist
if (!(Test-Path -path $WinPEMountFolder)) {New-Item -path $WinPEMountFolder -ItemType Directory}

# Backup the Boot image
Copy-Item -Path $BootImage -Destination "$($BootImage).bak"

# Mount the Boot image
Mount-WindowsImage -ImagePath $BootImage -Index 1 -Path $WinPEMountFolder

# Add native WinPE optional component required by MDT (the ones you commented out in the LiteTouchPE.xml file)
# winpe-hta
# winpe-scripting
# winpe-wmi
# winpe-securestartup
# winpe-fmapi
& $DISMFile /Image:$WinPEMountFolder /Add-Package /PackagePath:$WinPEOCsRoot\WinPE-HTA.cab
& $DISMFile /Image:$WinPEMountFolder /Add-Package /PackagePath:$WinPEOCsRoot\en-us\WinPE-HTA_en-us.cab

& $DISMFile /Image:$WinPEMountFolder /Add-Package /PackagePath:$WinPEOCsRoot\WinPE-Scripting.cab
& $DISMFile /Image:$WinPEMountFolder /Add-Package /PackagePath:$WinPEOCsRoot\en-us\WinPE-Scripting_en-us.cab

& $DISMFile /Image:$WinPEMountFolder /Add-Package /PackagePath:$WinPEOCsRoot\WinPE-WMI.cab 
& $DISMFile /Image:$WinPEMountFolder /Add-Package /PackagePath:$WinPEOCsRoot\en-us\WinPE-WMI_en-us.cab

& $DISMFile /Image:$WinPEMountFolder /Add-Package /PackagePath:$WinPEOCsRoot\WinPE-SecureStartup.cab 
& $DISMFile /Image:$WinPEMountFolder /Add-Package /PackagePath:$WinPEOCsRoot\en-us\WinPE-SecureStartup_en-us.cab

& $DISMFile /Image:$WinPEMountFolder /Add-Package /PackagePath:$WinPEOCsRoot\WinPE-FMAPI.cab # Does not have a language file

# Add MDAC optional component required if using the Database in MDT
& $DISMFile /Image:$WinPEMountFolder /Add-Package /PackagePath:$WinPEOCsRoot\WinPE-MDAC.cab 
& $DISMFile /Image:$WinPEMountFolder /Add-Package /PackagePath:$WinPEOCsRoot\en-us\WinPE-MDAC_en-us.cab

# Add the Windows Server, version 23H2 Update to the Boot image
& $DISMFile /Image:$WinPEMountFolder /Add-Package /PackagePath:$WinPECU

# Component cleanup 
& $DISMFile /Cleanup-Image /Image:$WinPEMountFolder /Startcomponentcleanup /Resetbase

# Dismount the Boot image
DisMount-WindowsImage -Path $WinPEMountFolder -Save

