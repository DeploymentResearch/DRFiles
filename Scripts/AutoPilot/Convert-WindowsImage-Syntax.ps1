# Convert a WIM file to VHDX file using Convert-WindowsImage.ps1 fork from https://github.com/nerdile/convert-windowsimage 
$WimFile = "C:\Ref\REFW10-X64-20H2-March-2021-Enterprise.wim"
$Edition = "Windows 10 Enterprise"
$OutPutVHDXFile = "C:\VHDs\AP-20H2.vhdx"

# Create UEFI-based VHDX file
C:\Setup\Scripts\Convert-WindowsImage.ps1 -SourcePath $WimFile -Edition $Edition -VHDPath $OutPutVHDXFile -VHDFormat VHDX -VHDType Dynamic -VHDPartitionStyle GPT -SizeBytes 100GB