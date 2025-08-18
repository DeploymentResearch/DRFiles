# -------------------------------------------------------------------------------------------
# File: New-Windows11MediaWithAutoUnattendAndEnrollmentPackage.ps1
# Credits: Johan Arwidmark (@jarwidmark)
#
# Description:
# A sample script to generate an automated Windwos 11 media 
#
# Provided as-is with no support. See https://deploymentresearch.com for related information.
# -------------------------------------------------------------------------------------------

$TempFolder = "C:\ISO\Temp"
$InputISO = "C:\ISO\Windows_11_x64_24H2_2025_07.iso"
$OutputISO = "C:\ISO\Windows_11_x64_24H2_2025_07_Automated.iso"
$OSCDIMG_Path = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
$SampleScript = "E:\Demo\Intune\Scripts\Remove-AutologonSettings.ps1"
$SampleAutoUnattend = "E:\Demo\Intune\Scripts\AutoUnattend_for_Windows11_Enterprise_With_ProvisioningPackage.xml"
$SamplePPKG = "E:\Demo\Intune\Bulk Enrollment Packages\BulkEnrollment-Expires-2026-02-12-08-33-32.ppkg"

# Validate locations
If (!(Test-path $OSCDIMG_Path)){ Write-Warning "OSCDIMG Path does not exist, Windows ADK probably not installed, aborting...";Break}
If (!(Test-path $InputISO)){ Write-Warning "ISO does not exist, aborting...";Break}

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
$BootData='2#p0,e,b"{0}"#pEF,e,b"{1}"' -f "$OSCDIMG_Path\etfsboot.com","$OSCDIMG_Path\efisys.bin"
   
$Proc = Start-Process -FilePath "$OSCDIMG_Path\oscdimg.exe" -ArgumentList @("-bootdata:$BootData",'-u2','-udfver102',"`"$TempFolder`"","`"$OutputISO`"") -PassThru -Wait -NoNewWindow
if($Proc.ExitCode -ne 0)
{
    Throw "Failed to generate ISO with exitcode: $($Proc.ExitCode)"
}

# Copy ISO to ROGUE-510
Copy-Item -Path $OutputISO -Destination "\\192.168.50.10\d$\ISO" -Force
