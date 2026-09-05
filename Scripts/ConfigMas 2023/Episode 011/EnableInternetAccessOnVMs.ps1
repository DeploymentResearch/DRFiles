<#
.SYNOPSIS
    Configures Hyper-V NAT so lab virtual machines get internet access.
.DESCRIPTION
    Creates the gateway IP address on the internal virtual switch and adds a NAT network for
    the lab subnet.
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
      1.0.0 - 2024-01-05 - Initial release
#>

# Get-NetNat | Remove-NetNat -Confirm:$false

New-NetIPAddress –IPAddress 192.168.1.1 -PrefixLength 24 -InterfaceAlias "vEthernet (Internal)" 
New-NetNat –Name ViaMonstraNATNetwork –InternalIPInterfaceAddressPrefix 192.168.1.0/24
