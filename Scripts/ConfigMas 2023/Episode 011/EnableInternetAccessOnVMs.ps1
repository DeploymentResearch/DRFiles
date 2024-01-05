# Get-NetNat | Remove-NetNat -Confirm:$false

New-NetIPAddress –IPAddress 192.168.1.1 -PrefixLength 24 -InterfaceAlias "vEthernet (Internal)" 
New-NetNat –Name ViaMonstraNATNetwork –InternalIPInterfaceAddressPrefix 192.168.1.0/24