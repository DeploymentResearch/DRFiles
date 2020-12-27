# Import core PSD module
Import-Module PSDUtility -Force -Scope Global

# Load the offline registry hive from the OS volume
$HivePath = "$tsenv:OSVolume`:\Windows\System32\config\SOFTWARE"
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): About to load registry hive: $HivePath "
reg load "HKLM\NewOS" $HivePath 
Start-Sleep -Seconds 5


# Updating offline registry to disable Windows store updates
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Updating registry to disable Windows store updates"
$RegistryKey = "HKLM:\NewOS\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" 
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Creating registry key: $RegistryKey"
$Result = New-Item -Path $RegistryKey -ItemType Directory -Force
$Result.Handle.Close()

$RegistryValue = "AutoDownload"
$RegistryValueType = "DWord"
$RegistryValueData = 2
    # 2 = always off
    # 4 = always on
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Creating registry value: $RegistryValue, value type: $RegistryValueType, value data: $RegistryValueData"
$Result = New-ItemProperty -Path $RegistryKey -Name $RegistryValue -PropertyType $RegistryValueType -Value $RegistryValueData -Force


# Updating offline  registry to disable consumer updates
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Updating registry to disable Windows store updates"
$RegistryKey = "HKLM:\NewOS\Policies\Microsoft\Windows\CloudContent" 
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Creating registry key: $RegistryKey"
$Result = New-Item -Path $RegistryKey -ItemType Directory -Force
$Result.Handle.Close()

$RegistryValue = "DisableWindowsConsumerFeatures"
$RegistryValueType = "DWord"
$RegistryValueData = 1
    # 1 = Off (disabled)
    # 0 = On (enabled)
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

