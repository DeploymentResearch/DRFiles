# Requires the script to be run under an administrative account context.
#Requires -RunAsAdministrator

# Set variables
$SiteCode = "PS1"
$DPName = "dp01.corp.viamonstra.com"
$MPName = "cm01.corp.viamonstra.com"
$ISOFile = "E:\Setup\Bootimage.iso"
$BootImageName = "WinPE 11 X64 22H2 - OSDTKIT - Stifler 2.10"

# Import ConfigMgr Module
Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
Set-Location "$SiteCode`:"

# Get objects for bootable media
$BootImage = Get-CMBootImage -Name $BootImageName
$DP = Get-CMDistributionPoint -SiteSystemServerName $DPName
$MP = Get-CMManagementPoint -SiteSystemServerName $MPName

# Configure settings for Bootable media
$BootableMedia_Params = @{
    MediaMode             = "SiteBased"
    MediaType             = "CdDvd"
    Path                  = $ISOFile
    AllowUnknownMachine   = $true
    BootImage             = $BootImage
    DistributionPoint     = $DP
    ManagementPoint       = $MP
    AllowUnattended       = $true
    Force                 = $true
}

# Create bootable media
New-CMBootableMedia @BootableMedia_Params

