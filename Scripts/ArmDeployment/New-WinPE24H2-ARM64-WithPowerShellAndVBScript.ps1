<#
.SYNOPSIS
	Script to create a WinPE 24H2 incuding PowerShell and VBScript Support
	
.DESCRIPTION
    Script to create a WinPE 24H2 incuding PowerShell and VBScript Support

.EXAMPLE
	.\New-WinPE23H2WithPowerShellAndVBScript.ps1 

.NOTES
    FileName:    New-WinPE23H2WithPowerShellAndVBScript.ps1
	Author:      Johan Arwidmark
    Contact:     @jarwidmark
    Created:     September 29, 2023
    Updated:     September 29, 2023
	
    Version history:
    1.0.0 - September 29, 2023 - Script created
#>

# Settings
$WinPE_BuildFolder = "C:\Setup\WinPE11_24H2"
$WinPE_Architecture = "arm64"
$WinPE_MountFolder = "C:\Mount"
$WinPE_ISOFolder = "C:\ISO"
$WinPE_ISOfile = "C:\ISO\WinPE11_24H2_ARM64_PowerShell_VBScript.iso"

$ADK_Path = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit"
$WinPE_ADK_Path = $ADK_Path + "\Windows Preinstallation Environment"
$WinPE_OCs_Path = $WinPE_ADK_Path + "\$WinPE_Architecture\WinPE_OCs"
$DISM_Path = $ADK_Path + "\Deployment Tools" + "\amd64\DISM"
$OSCDIMG_Path = $ADK_Path + "\Deployment Tools" + "\amd64\Oscdimg"
$OSCDIMG_arm64_Path = $ADK_Path + "\Deployment Tools" + "\$WinPE_Architecture\Oscdimg"

# Validate locations
If (!(Test-path $OSCDIMG_Path)){ Write-Warning "OSCDIMG Path does not exist, aborting...";Break}

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

# Create Mount folder
New-Item -Path $WinPE_MountFolder -ItemType Directory -Force

# Create ISO folder
New-Item -Path $WinPE_ISOFolder -ItemType Directory -Force

# Make a copy of the WinPE boot image from Windows ADK
if (!(Test-Path -path "$WinPE_BuildFolder\Sources")) {New-Item "$WinPE_BuildFolder\Sources" -Type Directory}
Copy-Item "$WinPE_ADK_Path\$WinPE_Architecture\en-us\winpe.wim" "$WinPE_BuildFolder\Sources\boot.wim"

# Copy WinPE boot files
Copy-Item "$WinPE_ADK_Path\$WinPE_Architecture\Media\*" "$WinPE_BuildFolder" -Recurse
 
# Mount the WinPE image
$WimFile = "$WinPE_BuildFolder\Sources\boot.wim"
Mount-WindowsImage -ImagePath $WimFile -Path $WinPE_MountFolder -Index 1
 
# Add native WinPE optional components (using ADK version of dism.exe instead of Add-WindowsPackage)
# Install WinPE-WMI before you install WinPE-NetFX (dependency)
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-Scripting.cab 
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-Scripting_en-us.cab

& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-HTA.cab 
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-HTA_en-us.cab

& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-WMI.cab 
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-WMI_en-us.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-NetFx.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-NetFx_en-us.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-PowerShell.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-PowerShell_en-us.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-DismCmdlets.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-DismCmdlets_en-us.cab

# Add x64 Emulator
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-x64-Support.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\en-us\WinPE-x64-Support_en-us.cab

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
Dismount-WindowsImage -Path $WinPE_MountFolder -Save

# Create a bootable WinPE ISO file using a single entry syntax (comment out if you don't need the ISO)
$BootData='1#pEF,e,b"{0}"' -f "$OSCDIMG_arm64_Path\efisys_noprompt.bin"
  
$Proc = Start-Process -FilePath "$OSCDIMG_Path\oscdimg.exe" -ArgumentList @("-bootdata:$BootData",'-u2','-udfver102',"$WinPE_BuildFolder","$WinPE_ISOfile") -PassThru -Wait -NoNewWindow
if($Proc.ExitCode -ne 0)
{
    Throw "Failed to generate ISO with exitcode: $($Proc.ExitCode)"
}