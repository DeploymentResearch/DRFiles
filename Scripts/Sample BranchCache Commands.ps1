# List all BranchCache commands
Get-Command -Module BranchCache

# Some common get BranchCache info commands
Get-BCStatus | Select *
Get-BCNetworkConfiguration | Select *
Get-BCClientConfiguration | select *

# ContentServerConfiguration = Distributed Cached Mode
Get-BCContentServerConfiguration | select *

# Loop through the New York OU and clear BranchCache cache
$Computers = Get-ADComputer -Filter * -Searchbase 'OU=Workstations Peer Cache New York,OU=ViaMonstra,DC=corp,DC=viamonstra,DC=com' | Select-Object -expand Name 
Invoke-Command -command { Clear-BCCache -Force } -computerName $Computers

# Loop through the Chicago OU and clear BranchCache cache
$Computers = Get-ADComputer -Filter * -Searchbase 'OU=Workstations Peer Cache Chicago,OU=ViaMonstra,DC=corp,DC=viamonstra,DC=com' | Select-Object -expand Name 
Invoke-Command -command { Clear-BCCache -Force } -computerName $Computers

# Loop through the New York OU and report on BranchCache Port
$Computers = Get-ADComputer -Filter * -Searchbase 'OU=Workstations Peer Cache New York,OU=ViaMonstra,DC=corp,DC=viamonstra,DC=com' | Select-Object -expand Name 
Invoke-Command -command { Get-BCNetworkConfiguration | Select ContentDownloadConnectPort,ContentDownloadListenPort } -computerName $Computers

# Loop through the Chicago OU and report on BranchCache Port
$Computers = Get-ADComputer -Filter * -Searchbase 'OU=Workstations Peer Cache Chicago,OU=ViaMonstra,DC=corp,DC=viamonstra,DC=com' | Select-Object -expand Name 
Invoke-Command -command { Get-BCNetworkConfiguration | Select ContentDownloadConnectPort,ContentDownloadListenPort } -computerName $Computers

# Loop through the New York OU and retrieve the BranchCache data cache
$Computers = Get-ADComputer -Filter * -Searchbase 'OU=Workstations Peer Cache New York,OU=ViaMonstra,DC=corp,DC=viamonstra,DC=com' | Select-Object -expand Name 
Invoke-Command -command { Get-BCDataCache | Select CurrentSizeOnDiskAsNumberOfBytes, CurrentActiveCacheSize } -computerName $Computers

# Loop through the Chicago OU and retrieve the BranchCache data cache
$Computers = Get-ADComputer -Filter * -Searchbase 'OU=Workstations Peer Cache Chicago,OU=ViaMonstra,DC=corp,DC=viamonstra,DC=com' | Select-Object -expand Name 
Invoke-Command -command { Get-BCDataCache | Select CurrentSizeOnDiskAsNumberOfBytes, CurrentActiveCacheSize } -computerName $Computers

# Misc tests
$Computers = "W10PEER-0001"
Test-WSMan $Computers
$Computers = Get-ADComputer -Filter * -Searchbase 'OU=Workstations Peer Cache,OU=ViaMonstra,DC=corp,DC=viamonstra,DC=com' | Select-Object -expand Name 
Invoke-Command -command { Get-NetIPAddress -InterfaceAlias Ethernet | Select IPAddress } -computerName $Computers


# Deletes all data in all data and hash files.
Clear-BCCache

# Retrieves the BranchCache data cache.
Get-BCDataCache

# Retrieves the BranchCache hash cache.
Get-BCHashCache




