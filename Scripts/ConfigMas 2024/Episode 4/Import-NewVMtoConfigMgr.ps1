# Requires the script to be run under an administrative account context.
#Requires -RunAsAdministrator

# Set variables
$SiteCode = "PS1"
$CollectionName = "MassDeployment - Windows 11 Enterprise x64 23H2"
$VMName = "W11-LAB-001"
$MacAddress = "00:15:5D:40:51:CD"

# Import ConfigMgr Module
Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
Set-Location "$SiteCode`:"

# Import machine to ConfigMgr
Import-CMComputerInformation -ComputerName $VMName -MacAddress $MacAddress -CollectionName $CollectionName

# Wait until ConfigMgr created devices from the import in the All Systems collection
Start-Sleep -Seconds 300

# Save some time by updating the target collection
Invoke-CMCollectionUpdate -Name $CollectionName
Start-Sleep -Seconds 60

# Check for the VM in the target collection
Get-CMCollectionMember -CollectionName $CollectionName -Name $VMName | Select Name, ResourceID, MACAddress




