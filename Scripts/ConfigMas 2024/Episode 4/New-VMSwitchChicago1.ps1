# Create Hyper-V Virtual Switch 
$VMNetwork = "Chicago1"

Write-Host "Checking for Hyper-V Virtual Switch"
$VMSwitchNameCheck = Get-VMSwitch | Where-Object -Property Name -EQ $VMNetwork
if ($VMSwitchNameCheck.Name -eq $VMNetwork) {
    Write-Host "Hyper-V switch already exist, all ok..." -ForegroundColor Green
}
Else {
    Write-Host "Hyper-V switch does not exist, creating it"
    Write-host "Creating virtual switch..."
    New-VMSwitch -Name $VMNetwork -AllowManagementOS $true -NetAdapterName "Ethernet"
    Start-Sleep -Seconds 10
}

