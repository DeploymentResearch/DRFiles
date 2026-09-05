<#
.SYNOPSIS
    Enables Remote Desktop and the matching firewall rules.
.DESCRIPTION
    Sets the terminal server registry value and enables the Remote Desktop firewall group. Can
    be called from an MDT task sequence using the SCRIPTROOT variable.
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

# When used in a MDT task sequence, copy the script to deployment share / scripts folder,
# and use the below command line:
# Powershell.exe -ExecutionPolicy ByPass -File "%SCRIPTROOT%\Enable-RDP.ps1"

## Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0
##
## Enable Firewall Rule
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
##
## Enable RDP Authentication
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 0
