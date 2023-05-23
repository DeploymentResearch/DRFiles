# Convert a Windows 10 WIM file to VHDX file using Convert-WindowsImage.ps1 fork from https://github.com/nerdile/convert-windowsimage 
$WimFile = "C:\WIM\REFW10-X64-22H2-Enterprise.wim"
$Edition = "Windows 10 Enterprise"
$OutPutVHDXFile = "C:\VHDs\AP-W10-22H2.vhdx"

# Create UEFI-based VHDX file
C:\Setup\Scripts\Convert-WindowsImage.ps1 -SourcePath $WimFile -Edition $Edition -VHDPath $OutPutVHDXFile -VHDFormat VHDX -VHDType Dynamic -VHDPartitionStyle GPT -SizeBytes 240GB


# Convert a Windows 11 WIM file to VHDX file using Convert-WindowsImage.ps1 fork from https://github.com/nerdile/convert-windowsimage 
$WimFile = "C:\WIM\REFW11-X64-22H2-Enterprise.wim"
$Edition = "Windows 11 Enterprise"
$OutPutVHDXFile = "C:\VHDs\AP-W11-22H2.vhdx"

# Create UEFI-based VHDX file
C:\Setup\Scripts\Convert-WindowsImage.ps1 -SourcePath $WimFile -Edition $Edition -VHDPath $OutPutVHDXFile -VHDFormat VHDX -VHDType Dynamic -VHDPartitionStyle GPT -SizeBytes 240GB