<#
.SYNOPSIS
    Creates internal and external Hyper-V virtual switches.
.DESCRIPTION
    Creates an internal switch, then creates an external switch bound to the first network
    adapter that is up.
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
      1.0.0 - 2023-08-03 - Initial release
#>

# Create Internal Hyper-V Switch
New-VMSwitch -Name Internal -SwitchType Internal | Out-Null

# Create External Hyper-V Switch
$NetworkAdapter = Get-NetAdapter | Where-Object Status -eq "Up" 
New-VMSwitch -Name External -NetAdapterName ($NetworkAdapter.Name) -AllowManagementOs $true

 
