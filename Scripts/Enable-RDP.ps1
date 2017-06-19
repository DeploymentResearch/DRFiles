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
