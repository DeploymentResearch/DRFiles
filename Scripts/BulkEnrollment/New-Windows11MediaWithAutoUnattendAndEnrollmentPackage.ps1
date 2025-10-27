<#
.SYNOPSIS
    A sample script to generate an automated Windows 11 media 

.DESCRIPTION
    The script requires the Windows ADK to be installed. It creates a bootable Windows 11 ISO
    with an existing AutoUnattend.xml file, a sample PowerShell script, and a Provisioning package
    added to the $OEM$ folder structure for automatic execution during setup.

.NOTES
    Author: Johan Arwidmark / deploymentresearch.com
    Twitter (X): @jarwidmark
    LinkedIn: https://www.linkedin.com/in/jarwidmark
    License: MIT
    Source:  https://github.com/DeploymentResearch/DRFiles

.DISCLAIMER
    This script is provided "as is" without warranty of any kind, express or implied.
    Use at your own risk — the author and DeploymentResearch assume no responsibility for any
    issues, damages, or data loss resulting from its use or modification.

    This script is shared in the spirit of community learning and improvement.
    You are welcome to adapt and redistribute it under the terms of the MIT License.

.VERSION
    1.0.1
    Released: 2025-10-26
    Change history:
      1.0.1 - 2025-10-26 - Added more validation, script cleanup, and support for ARM64 media
      1.0.0 - 2025-08-18 - Initial release
#>
#Requires -RunAsAdministrator

$TempFolder = "C:\ISO\Temp"
$DestinationArchitecture = "arm64" # x64 or arm64
$WindowsVersion = "25H2"
$InputISO = "C:\ISO\Windows_11_$($DestinationArchitecture)_$($WindowsVersion).iso"
$OutputISO = "C:\ISO\Windows_11_$($DestinationArchitecture)_$($WindowsVersion)_Automated.iso"
$OSCDIMG_Path = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
# Purposely converting x64 to amd64 because I like naming my X64 ISO's X64, but in Windows ADK the folder is named amd64
If ($DestinationArchitecture -eq "arm64"){
    $EFIFiles = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\arm64\Oscdimg"
}
Else {
    $EFIFiles = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
}
$SampleScript = "E:\Demo\Intune\Scripts\Remove-AutologonSettings.ps1"
$SampleAutoUnattend = "E:\Demo\Intune\Scripts\AutoUnattend_for_Windows11_Enterprise_$($DestinationArchitecture)_With_ProvisioningPackage.xml"
$SamplePPKG = "E:\Demo\Intune\Bulk Enrollment Packages\BulkEnrollment-Expires-2026-02-12-08-33-32.ppkg"

# Basic Validations
If (!(Test-path $OSCDIMG_Path)){ Write-Warning "OSCDIMG Path does not exist, Windows ADK probably not installed, aborting...";Break}
If (!(Test-path $EFIFiles)){ Write-Warning "EFIFiles Path does not exist, Windows ADK probably not installed, aborting...";Break}
If (!(Test-path $SampleScript)){ Write-Warning "SampleScript does not exist, aborting...";Break}
If (!(Test-path $SampleAutoUnattend)){ Write-Warning "SampleAutoUnattend does not exist, aborting...";Break}
If (!(Test-path $SamplePPKG)){ Write-Warning "SamplePPKG does not exist, aborting...";Break}
If (!(Test-path $InputISO)){ Write-Warning "InputISO does not exist, aborting...";Break}

# Delete ISO Folder if exist, and create empty folder
If (Test-path $TempFolder){
    Remove-Item -Path $TempFolder -Recurse -Force
    New-Item -Path $TempFolder -ItemType Directory
}
Else{
    New-Item -Path $TempFolder -ItemType Directory
}

# Mount the ISO
Mount-DiskImage -ImagePath $InputISO
$ISOImage = Get-DiskImage -ImagePath $InputISO | Get-Volume
$ISODrive = [string]$ISOImage.DriveLetter+":"

# Copy content of ISO to ISO Source Folder
Copy-Item "$ISODrive\*" $TempFolder -Recurse

# Dismount the ISO 
Dismount-DiskImage -ImagePath $InputISO

# Prepare $OEM$ folder structure
# Note: The $OEM$\$$ is the C:\Windows folder
$WindowsFolder = "$TempFolder\Sources\`$OEM$\`$`$"
$ScriptsFolder = "$WindowsFolder\Setup\Scripts"
$ProvPackagesFolder = "$WindowsFolder\Provisioning\Packages"
New-Item -Path $ScriptsFolder -ItemType Directory -Force
New-Item -Path $ProvPackagesFolder -ItemType Directory -Force

# Add the AutoUnattend.xml file, a sample PowerShell script, and a Provisioning package
Copy-Item -Path $SampleAutoUnattend -Destination "$TempFolder\AutoUnattend.xml" -Force
Copy-Item -Path $SampleScript -Destination $ScriptsFolder -Force
Copy-Item -Path $SamplePPKG -Destination $ProvPackagesFolder -Force

# Create a new bootable ISO file
$BootData='2#p0,e,b"{0}"#pEF,e,b"{1}"' -f "$EFIFiles\etfsboot.com","$EFIFiles\efisys.bin"
   
$Proc = Start-Process -FilePath "$OSCDIMG_Path\oscdimg.exe" -ArgumentList @("-bootdata:$BootData",'-u2','-udfver102',"`"$TempFolder`"","`"$OutputISO`"") -PassThru -Wait -NoNewWindow
if($Proc.ExitCode -ne 0)
{
    Throw "Failed to generate ISO with exitcode: $($Proc.ExitCode)"
}