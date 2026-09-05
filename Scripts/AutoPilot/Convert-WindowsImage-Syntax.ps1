<#
.SYNOPSIS
    Syntax example for converting a WIM file to VHDX with Convert-WindowsImage.
.DESCRIPTION
    Reference snippet showing the parameters used against the Convert-WindowsImage.ps1 fork,
    for building VHDX files used by Autopilot test virtual machines.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark / deploymentresearch.com
    Credits: Convert-WindowsImage.ps1 fork by https://github.com/nerdile/convert-windowsimage
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2023-05-22 - Initial release
#>

# Convert a Windows 10 WIM file to VHDX file using Convert-WindowsImage.ps1 fork from https://github.com/nerdile/convert-windowsimage 
$WimFile = "C:\WIM\W10-X64-22H2-Enterprise.wim"
$Edition = "Windows 10 Enterprise"
$OutPutVHDXFile = "C:\VHD\W10-X64-22H2-Enterprise.vhdx"

# Create UEFI-based VHDX file
C:\Setup\Scripts\Convert-WindowsImage.ps1 -SourcePath $WimFile -Edition $Edition -VHDPath $OutPutVHDXFile -VHDFormat VHDX -VHDType Dynamic -VHDPartitionStyle GPT -SizeBytes 240GB


# Convert a Windows 11 WIM file to VHDX file using Convert-WindowsImage.ps1 fork from https://github.com/nerdile/convert-windowsimage 
$WimFile = "C:\WIM\W11-X64-22H2-Enterprise.wim"
$Edition = "Windows 11 Enterprise"
$OutPutVHDXFile = "C:\VHD\W11-X64-22H2-Enterprise.vhdx"

# Create UEFI-based VHDX file
C:\Setup\Scripts\Convert-WindowsImage.ps1 -SourcePath $WimFile -Edition $Edition -VHDPath $OutPutVHDXFile -VHDFormat VHDX -VHDType Dynamic -VHDPartitionStyle GPT -SizeBytes 240GB
