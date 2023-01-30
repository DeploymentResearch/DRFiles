# Generiuc
$MCCIPAddress = "192.168.0.5"

# Load the offline registry hive from the mounted disk
$HivePath = "$OSDriveLetter\Windows\System32\config\SOFTWARE"
reg load "HKLM\NewOS" $HivePath 
Start-Sleep -Seconds 5

# Updating offline registry to configure the machine to use a local cache server 
$RegistryKey = "HKLM:\NewOS\Policies\Microsoft\Windows\DeliveryOptimization" 
$Result = New-Item -Path $RegistryKey -ItemType Directory -Force
$Result.Handle.Close()

$RegistryValue = "DoCacheHost"
$RegistryValueType = "String"
$RegistryValueData = $MCCIPAddress
$Result = New-ItemProperty -Path $RegistryKey -Name $RegistryValue -PropertyType $RegistryValueType -Value $RegistryValueData -Force

# Cleanup (to prevent access denied issue unloading the registry hive)
Remove-Variable Result
Get-Variable Registry* | Remove-Variable
[gc]::collect()
Start-Sleep -Seconds 5

# Unload the registry hive
Set-Location C:\
reg unload "HKLM\NewOS"  
