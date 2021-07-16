# Remove iPerf3 firewall rules
Remove-NetFirewallRule -DisplayName "iPerf3 Server Inbound TCP Rule"
Remove-NetFirewallRule -DisplayName "iPerf3 Server Outbound TCP Rule"