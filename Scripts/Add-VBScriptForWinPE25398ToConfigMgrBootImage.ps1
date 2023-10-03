<#
.SYNOPSIS
	Script to create add VBScript support to a ConfigMgr boot image based on WinPE build 25398
	
.DESCRIPTION
    This script will inject downloaded FODs for VBScript and add VBScript support to a ConfigMgr WinPE build 25398

.EXAMPLE
	.\New-AddVBScriptForWinPE25398ToConfigMgrBootImage.ps1 

.NOTES
    FileName:    New-AddVBScriptForWinPE25398ToConfigMgrBootImage.ps1
	Author:      Johan Arwidmark
    Contact:     @jarwidmarke
    Created:     September 29, 2023
    Updated:     September 30, 2023
	
    Version history:
    1.0.0 - September 29, 2023 - Script created
    1.0.1 - September 30, 2023 - Updated version info
#>

# Settings
#Requires -RunAsAdministrator

# Set some variables to resources
$BootImageName = "Zero Touch WinPE 11 x64"
$MountPath = "E:\Mount"
$VBSCRIPT_FOD = "E:\Setup\VBSCRIPT_FOD_25951"
$SiteServer = "CM01"
$SiteCode = "PS1"
$ADK_Path = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit"
$WinPE_ADK_Path = $ADK_Path + "\Windows Preinstallation Environment"
$DISM_Path = $ADK_Path + "\Deployment Tools" + "\amd64\DISM"

# Create Mount folder
New-Item -Path $MountPath -ItemType Directory -Force

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
if (!(Test-Path -Path "$VBSCRIPT_FOD")) {Write-Warning "Could not find VBSCRIPT_FOD path, aborting...";Break}

# Backup existing boot image
$BackupBootImagePath = $BootImagePath.Replace(".wim",".wim.bak")
Copy-Item -Path $BootImagePath -Destination $BackupBootImagePath -Force

# Mount the boot image
Mount-WindowsImage -ImagePath $BootImagePath -Index 1 -Path $MountPath  

# Add VBScript support from downloaded FODs
& $DISM_Path\dism.exe /Image:$MountPath /Add-Package /PackagePath:$VBSCRIPT_FOD\Microsoft-Windows-VBSCRIPT-FoD-Package~31bf3856ad364e35~amd64~~.cab
& $DISM_Path\dism.exe /Image:$MountPath /Add-Package /PackagePath:$VBSCRIPT_FOD\Microsoft-Windows-VBSCRIPT-FoD-Package~31bf3856ad364e35~amd64~en-us~.cab
& $DISM_Path\dism.exe /Image:$MountPath /Add-Package /PackagePath:$VBSCRIPT_FOD\Microsoft-Windows-VBSCRIPT-FoD-Package~31bf3856ad364e35~wow64~~.cab
& $DISM_Path\dism.exe /Image:$MountPath /Add-Package /PackagePath:$VBSCRIPT_FOD\Microsoft-Windows-VBSCRIPT-FoD-Package~31bf3856ad364e35~wow64~en-us~.cab

# Write unattend.xml file to change screen resolution
$UnattendPEx64 = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="arm64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <Display>
                <ColorDepth>32</ColorDepth>
                <HorizontalResolution>1280</HorizontalResolution>
                <RefreshRate>60</RefreshRate>
                <VerticalResolution>720</VerticalResolution>
            </Display>
        </component>
    </settings>
</unattend>
'@ | Out-File "$WinPE_MountFolder\Unattend.xml" -Encoding utf8 -Force

# Unmount the WinPE image and save changes
Dismount-WindowsImage -Path $MountPath -Save

# Update the boot image in ConfigMgr
Set-Location "$($SiteCode):\" 
$GetDistributionStatus = $BootImage | Get-CMDistributionStatus
$OriginalUpdateDate = $GetDistributionStatus.LastUpdateDate
Write-Output "Updating distribution points for the boot image..."
Write-Output "Last update date was: $OriginalUpdateDate"
$BootImage | Update-CMDistributionPoint
