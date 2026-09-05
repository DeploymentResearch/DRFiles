<#
.SYNOPSIS
    Removes the iPerf3 firewall rules.
.DESCRIPTION
    Deletes the inbound and outbound TCP rules created for iPerf3 server testing.
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

# Remove iPerf3 firewall rules
Remove-NetFirewallRule -DisplayName "iPerf3 Server Inbound TCP Rule"
Remove-NetFirewallRule -DisplayName "iPerf3 Server Outbound TCP Rule"
