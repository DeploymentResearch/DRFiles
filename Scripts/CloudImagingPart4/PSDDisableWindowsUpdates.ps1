# Import core PSD module
Import-Module PSDUtility -Force -Scope Global

# Load the offline registry hive from the OS volume
$HivePath = "$tsenv:OSVolume`:\Windows\System32\config\SOFTWARE"
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): About to load registry hive: $HivePath "
reg load "HKLM\NewOS" $HivePath 
Start-Sleep -Seconds 5


# Updating offline registry to disable Windows updates
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Updating registry to disable Windows updates"
$RegistryKey = "HKLM:\NewOS\Policies\Microsoft\Windows\WindowsUpdate\AU" 
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Creating registry key: $RegistryKey"
$Result = New-Item -Path $RegistryKey -ItemType Directory -Force
$Result.Handle.Close()

$RegistryValue = "NoAutoUpdate"
$RegistryValueType = "DWord"
$RegistryValueData = 1
    # 0 = Updates Enabled
    # 1 = Updates Disabled
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Creating registry value: $RegistryValue, value type: $RegistryValueType, value data: $RegistryValueData"
$Result = New-ItemProperty -Path $RegistryKey -Name $RegistryValue -PropertyType $RegistryValueType -Value $RegistryValueData -Force


# Cleanup (to prevent access denied issue unloading the registry hive)
Remove-Variable Result
Get-Variable Registry* | Remove-Variable
[gc]::collect()
Start-Sleep -Seconds 5

# Unload the registry hive
Set-Location X:\
reg unload "HKLM\NewOS"  