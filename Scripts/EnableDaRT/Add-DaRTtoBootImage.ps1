# Check for elevation
Write-Host "Checking for elevation"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
    Write-Warning "Aborting script..."
    Break
}

# Set some variables to resources
$BootImageName = "Zero Touch WinPE 10 x64"
$MountPath = "E:\Mount"
$DartCab = "C:\Program Files\Microsoft DaRT\v10\Toolsx64.cab"
$MDTInstallationPath = "C:\Program Files\Microsoft Deployment Toolkit"
$SampleFiles = "C:\Setup\EnableDaRT"
$SiteServer = "CM01"
$SiteCode = "PS1"

# Connect to ConfigMgr
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
}
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
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
if (!(Test-Path -Path "$DartCab")) {Write-Warning "Could not find DaRT Toolsx64.cab, aborting...";Break}
if (!(Test-Path -Path "$MDTInstallationPath")) {Write-Warning "Could not find MDT, aborting...";Break}
if (!(Test-Path -Path "$SampleFiles\EnableDart.wsf")) {Write-Warning "Could not find EnableDart.wsf, aborting...";Break}
if (!(Test-Path -Path "$SampleFiles\Unattend.xml")) {Write-Warning "Could not find Unattend.xml, aborting...";Break}

# Mount the boot image
Mount-WindowsImage -ImagePath $BootImagePath -Index 1 -Path $MountPath  

# Add the needed files to the boot image
expand.exe $DartCab -F:* $MountPath
Remove-Item $MountPath\etfsboot.com -Force
Copy-Item $MDTInstallationPath\Templates\DartConfig8.dat $MountPath\Windows\System32\DartConfig.dat

if (!(Test-Path -Path "$MountPath\Deploy\Scripts")) {New-Item -ItemType directory $MountPath\Deploy\Scripts}
if (!(Test-Path -Path "$MountPath\Deploy\Scripts\x64")) {New-Item -ItemType directory $MountPath\Deploy\Scripts\x64}
Copy-Item $SampleFiles\EnableDart.wsf $MountPath\Deploy\Scripts
Copy-Item $SampleFiles\Unattend.xml $MountPath
Copy-Item "$MDTInstallationPath\Templates\Distribution\Scripts\ZTIDataAccess.vbs" $MountPath\Deploy\Scripts
Copy-Item "$MDTInstallationPath\Templates\Distribution\Scripts\ZTIUtility.vbs" $MountPath\Deploy\Scripts
Copy-Item "$MDTInstallationPath\Templates\Distribution\Scripts\ZTIGather.wsf" $MountPath\Deploy\Scripts
Copy-Item "$MDTInstallationPath\Templates\Distribution\Scripts\ZTIGather.xml" $MountPath\Deploy\Scripts
Copy-Item "$MDTInstallationPath\Templates\Distribution\Scripts\ztiRunCommandHidden.wsf" $MountPath\Deploy\Scripts
Copy-Item "$MDTInstallationPath\Templates\Distribution\Scripts\ZTIDiskUtility.vbs" $MountPath\Deploy\Scripts
Copy-Item "$MDTInstallationPath\Templates\Distribution\Tools\x64\Microsoft.BDD.Utility.dll" $MountPath\Deploy\Scripts\x64

# Save changes to the boot image
Dismount-WindowsImage -Path $MountPath -Save


# Update the boot image in ConfigMgr
Set-Location "$($SiteCode):\" 
$GetDistributionStatus = $BootImage | Get-CMDistributionStatus
$OriginalUpdateDate = $GetDistributionStatus.LastUpdateDate
Write-Output "Updating distribution points for the boot image..."
Write-Output "Last update date was: $OriginalUpdateDate"
$BootImage | Update-CMDistributionPoint

# Wait until distribution is done
Write-Output ""
Write-Output "Waiting for distribution status to update..."

Do { 
$GetDistributionStatus = $BootImage | Get-CMDistributionStatus
$NewUpdateDate = $GetDistributionStatus.LastUpdateDate
 if ($NewUpdateDate -gt $OriginalUpdateDate) {
  Write-Output ""
  Write-Output "Yay, boot image distribution status updated. New update date is: $NewUpdateDate"
  Write-Output "Happy Deployment!"
 } else {
  Write-Output "Boot image distribution status not yet updated, waiting 10 more seconds"
 }
 Start-Sleep -Seconds 10
}
Until ($NewUpdateDate -gt $OriginalUpdateDate)
