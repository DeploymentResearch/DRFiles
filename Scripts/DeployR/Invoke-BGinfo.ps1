# Show BGInfo during DeployR
# Add x64 version of Bginfo.exe, and the BGI template to your boot image

If (${TSEnv:ComputerName}){
    $Null = New-Item -Path HKLM:\SOFTWARE\PSD -ItemType Directory -Force
    $Null = New-ItemProperty -Path HKLM:\SOFTWARE\PSD -Name ComputerName -PropertyType String -Value ${TSEnv:ComputerName} -Force
}

& X:\Windows\System32\Bginfo.exe X:\Windows\System32\psd.bgi /timer:0 /NOLICPROMPT /SILENT