<#
.SYNOPSIS
    Injects Microsoft Connected Cache settings into an offline registry hive.
.DESCRIPTION
    Loads the SOFTWARE hive from the applied operating system, writes the Delivery Optimization
    cache host value, and unloads the hive. Runs from WinPE during a task sequence.
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
      1.0.0 - 2023-01-29 - Initial release
#>

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
