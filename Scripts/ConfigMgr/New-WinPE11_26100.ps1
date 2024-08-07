# Requires the script to be run under an administrative account context.
#Requires -RunAsAdministrator

# Location for updated optional components for WinPE
$OCPath = "E:\Setup\WinPE 11 WinPE_OCs from ADK 24H2\amd64"

# Set other parameters
$BootMedia = "E:\Sources\OSD\Boot\WinPE 11 24H2 x64\winpe.wim"
$BootIndex = "1"
$SiteCode = "PS1"
$BootImageName = "Test 24H2"

# Mount the boot image
$MountPath = "E:\Mount"
New-Item -Path $MountPath -ItemType Directory -Force
Mount-WindowsImage -ImagePath $BootMedia -Index 1 -Path $MountPath

# Add Optional Components
# Configuration Manager boot image required components
# Scripting (WinPE-Scripting)
Add-WindowsPackage -PackagePath "$OCPath\WinPE-Scripting.cab" -Path $MountPath -Verbose
Add-WindowsPackage -PackagePath "$OCPath\en-us\WinPE-Scripting_en-us.cab" -Path $MountPath -Verbose

# Scripting (WinPE-WMI)
Add-WindowsPackage -PackagePath "$OCPath\WinPE-WMI.cab" -Path $MountPath -Verbose
Add-WindowsPackage -PackagePath "$OCPath\en-us\WinPE-WMI_en-us.cab" -Path $MountPath -Verbose

# Network (WinPE-WDS-Tools) 
Add-WindowsPackage -PackagePath "$OCPath\WinPE-WDS-Tools.cab" -Path $MountPath -Verbose
Add-WindowsPackage -PackagePath "$OCPath\en-us\WinPE-WDS-Tools_en-us.cab" -Path $MountPath -Verbose

# Startup (WinPE-SecureStartup) Requires WinPE-WMI
Add-WindowsPackage -PackagePath "$OCPath\WinPE-SecureStartup.cab" -Path $MountPath -Verbose
Add-WindowsPackage -PackagePath "$OCPath\en-us\WinPE-SecureStartup_en-us.cab" -Path $MountPath -Verbose

# Configuration Manager boot image additional components
# Microsoft .NET (WinPE-NetFx) Requires WinPE-WMI
Add-WindowsPackage -PackagePath "$OCPath\WinPE-NetFx.cab" -Path $MountPath -Verbose
Add-WindowsPackage -PackagePath "$OCPath\en-us\WinPE-NetFx_en-us.cab" -Path $MountPath -Verbose

# Windows PowerShell (WinPE-PowerShell) Requires WinPE-WMI, WinPE-NetFx, WinPE-Scripting
Add-WindowsPackage -PackagePath "$OCPath\WinPE-PowerShell.cab" -Path $MountPath -Verbose
Add-WindowsPackage -PackagePath "$OCPath\en-us\WinPE-PowerShell_en-us.cab" -Path $MountPath -Verbose

# Windows PowerShell (WinPE-DismCmdlets) Requires WinPE-WMI, WinPE-NetFx, WinPE-Scripting, WinPE-PowerShell
Add-WindowsPackage -PackagePath "$OCPath\WinPE-DismCmdlets.cab" -Path $MountPath -Verbose
Add-WindowsPackage -PackagePath "$OCPath\en-us\WinPE-DismCmdlets_en-us.cab" -Path $MountPath -Verbose

# Microsoft Secure Boot Cmdlets (WinPE-SecureBootCmdlets) Requires WinPE-WMI, WinPE-NetFx, WinPE-Scripting, WinPE-PowerShell
Add-WindowsPackage -PackagePath "$OCPath\WinPE-SecureBootCmdlets.cab" -Path $MountPath -Verbose

# Windows PowerShell (WinPE-StorageWMI) Requires WinPE-WMI, WinPE-NetFx, WinPE-Scripting, WinPE-PowerShell
Add-WindowsPackage -PackagePath "$OCPath\WinPE-StorageWMI.cab" -Path $MountPath -Verbose
Add-WindowsPackage -PackagePath "$OCPath\en-us\WinPE-StorageWMI_en-us.cab" -Path $MountPath -Verbose

# Storage (WinPE-EnhancedStorage) 
Add-WindowsPackage -PackagePath "$OCPath\WinPE-EnhancedStorage.cab" -Path $MountPath -Verbose
Add-WindowsPackage -PackagePath "$OCPath\en-us\WinPE-EnhancedStorage_en-us.cab" -Path $MountPath -Verbose

# HTML (WinPE-HTA) Requires WinPE-Scripting
Add-WindowsPackage -PackagePath "$OCPath\WinPE-HTA.cab" -Path $MountPath -Verbose
Add-WindowsPackage -PackagePath "$OCPath\en-us\WinPE-HTA_en-us.cab" -Path $MountPath -Verbose

# Perform component cleanup
Start-Process "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\DISM\dism.exe" -ArgumentList " /Image:$MountPath /Cleanup-image /StartComponentCleanup /Resetbase" -Wait -LoadUserProfile

# Dismount the boot image
Dismount-WindowsImage -Path $MountPath -Save


# Customize the boot image

# Get the boot image 
$CMBootImage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_BootImagePackage -Filter "Name like '%$($BootImageName)%'"
$BootImage = [wmi]"$($CMBootImage.__PATH)"

# Add F8 Support in ConfigMgr (needed when ADK version installed is different from Boot Image)
$BootImage.EnableLabShell = $true
$BootImage.Put()

# Add custom background image
$BackgroundUNCPath = "\\cm01\Sources\OSD\Branding\2PintNewLogoWinPEBackground.bmp"
$BootImage.BackgroundBitmapPath = $BackgroundUNCPath 
$BootImage.Put()


