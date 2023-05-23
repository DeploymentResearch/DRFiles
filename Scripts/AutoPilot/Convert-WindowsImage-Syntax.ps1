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