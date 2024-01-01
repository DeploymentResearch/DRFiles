# Requires the script to be run under an administrative account context.
#Requires -RunAsAdministrator

$BootImageName = "Zero Touch WinPE 11 x64"
$MountPath = "E:\Mount"
$SiteServer = "CM01"
$SiteCode = "PS1"

# Connect to ConfigMgr
if($null -eq (Get-Module ConfigurationManager)) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
}
if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer 
}
Set-Location "$($SiteCode):\" 

# Get Boot image from ConfigMgr
$BootImage = Get-CMBootImage -Name $BootImageName
$BootImagePath = $BootImage.ImagePath

# Some basic sanity checks
Set-Location C:
if (!(Test-Path -Path "$BootImagePath")) {Write-Warning "Could not find boot image, aborting...";Break}
if (!(Test-Path -Path "$MountPath")) {Write-Warning "Could not find mount path, aborting...";Break}

# Mount the boot image
Mount-WindowsImage -ImagePath $BootImagePath -Index 1 -Path $MountPath  

# Add the desired Tools to the boot image
Copy-Item -Path "E:\Setup\SysinternalsSuite\Bginfo64.exe" -Destination "$MountPath\Windows\System32"
Copy-Item -Path "E:\Setup\BGInfo\PSD.bgi" -Destination "$MountPath\Windows\System32"

# Save changes to the boot image
Dismount-WindowsImage -Path $MountPath -Save

# Update the boot image in ConfigMgr
Set-Location "$($SiteCode):\" 
$BootImage | Update-CMDistributionPoint