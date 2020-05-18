# Enable Promiscuous Mode for an external virtual switch in Hyper-V
$VMSwitch = "Chicago1"
$portFeature = Get-VMSystemSwitchExtensionPortFeature -FeatureName "Ethernet Switch Port Security Settings"
# None = 0, Destination = 1, Source = 2
$portFeature.SettingData.MonitorMode = 2
Add-VMSwitchExtensionPortFeature -ExternalPort -SwitchName $VMSwitch -VMSwitchExtensionFeature $portFeature

# Show settings
Get-VMSwitchExtensionPortFeature -ExternalPort -SwitchName $VMSwitch –FeatureName "Ethernet Switch Port Security Settings"
Get-VMSwitchExtensionPortFeature -ExternalPort -SwitchName $VMSwitch | select -ExpandProperty SettingData
