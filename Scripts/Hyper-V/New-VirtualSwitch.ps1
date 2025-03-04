# Create Internal Hyper-V Switch
New-VMSwitch -Name Internal -SwitchType Internal | Out-Null

# Create External Hyper-V Switch
$NetworkAdapter = Get-NetAdapter | Where-Object Status -eq "Up" 
New-VMSwitch -Name External -NetAdapterName ($NetworkAdapter.Name) -AllowManagementOs $true

 