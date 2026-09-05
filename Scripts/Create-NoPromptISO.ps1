<#
.SYNOPSIS
    Removes the press any key prompt from a WinPE boot ISO.
.DESCRIPTION
    Extracts the ISO, replaces the boot sector file with the no prompt variant from the Windows
    ADK, and rebuilds the ISO so unattended virtual machines boot without a keypress.
.EXAMPLE
    N/A
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark / deploymentresearch.com
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2022-01-02 - Initial release
#>

# Settings
$WinPE_Architecture = "amd64" # Or x86
$WinPE_InputISOfile = "C:\ISO\Zero Touch WinPE 10 x64.iso"
$WinPE_OutputISOfile = "C:\ISO\Zero Touch WinPE 10 x64 - NoPrompt.iso"
 
$ADK_Path = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit"
$WinPE_ADK_Path = $ADK_Path + "\Windows Preinstallation Environment"
$OSCDIMG_Path = $ADK_Path + "\Deployment Tools" + "\$WinPE_Architecture\Oscdimg"

# Validate locations
If (!(Test-path $WinPE_InputISOfile)){ Write-Warning "WinPE Input ISO file does not exist, aborting...";Break}
If (!(Test-path $ADK_Path)){ Write-Warning "ADK Path does not exist, aborting...";Break}
If (!(Test-path $WinPE_ADK_Path)){ Write-Warning "WinPE ADK Path does not exist, aborting...";Break}
If (!(Test-path $OSCDIMG_Path)){ Write-Warning "OSCDIMG Path does not exist, aborting...";Break}

# Mount the Original ISO (WinPE_InputISOfile) and figure out the drive-letter
Mount-DiskImage -ImagePath $WinPE_InputISOfile
$ISOImage = Get-DiskImage -ImagePath $WinPE_InputISOfile | Get-Volume
$ISODrive = [string]$ISOImage.DriveLetter+":"

# Create a new bootable WinPE ISO file, based on the Original ISO, but using efisys_noprompt.bin instead
$BootData='2#p0,e,b"{0}"#pEF,e,b"{1}"' -f "$OSCDIMG_Path\etfsboot.com","$OSCDIMG_Path\efisys_noprompt.bin"
   
$Proc = Start-Process -FilePath "$OSCDIMG_Path\oscdimg.exe" -ArgumentList @("-bootdata:$BootData",'-u2','-udfver102',"$ISODrive\","`"$WinPE_OutputISOfile`"") -PassThru -Wait -NoNewWindow
if($Proc.ExitCode -ne 0)
{
    Throw "Failed to generate ISO with exitcode: $($Proc.ExitCode)"
}

# Dismount the Original ISO
Dismount-DiskImage -ImagePath $WinPE_InputISOfile
