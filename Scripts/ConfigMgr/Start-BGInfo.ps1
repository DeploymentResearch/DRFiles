# Create TS environment object
$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment

$Null = New-Item -Path HKLM:\SOFTWARE\PSD -ItemType Directory -Force
$Null = New-ItemProperty -Path HKLM:\SOFTWARE\PSD -Name ComputerName -PropertyType String -Value $TSEnv.Value("_SMSTSMachineName") -Force

& X:\Windows\System32\bginfo.exe X:\Windows\System32\psd.bgi /timer:0 /NOLICPROMPT /SILENT