<#
.SYNOPSIS
    Enables promiscuous mode on a Hyper-V external virtual switch.
.DESCRIPTION
    Sets the port security extension feature so a virtual machine can capture traffic for other
    machines on the same switch, which is needed for network tracing in a lab.
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
      1.0.0 - 2022-01-02 - Initial release
#>

# Enable Promiscuous Mode for an external virtual switch in Hyper-V
$VMSwitch = "Chicago1"
$portFeature = Get-VMSystemSwitchExtensionPortFeature -FeatureName "Ethernet Switch Port Security Settings"
# None = 0, Destination = 1, Source = 2
$portFeature.SettingData.MonitorMode = 2
Add-VMSwitchExtensionPortFeature -ExternalPort -SwitchName $VMSwitch -VMSwitchExtensionFeature $portFeature

# Show settings
Get-VMSwitchExtensionPortFeature -ExternalPort -SwitchName $VMSwitch –FeatureName "Ethernet Switch Port Security Settings"
Get-VMSwitchExtensionPortFeature -ExternalPort -SwitchName $VMSwitch | select -ExpandProperty SettingData
