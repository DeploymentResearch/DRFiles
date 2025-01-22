# Global Settings
$SiteCode = "PS1" 
$ProviderMachineName = "cm01.corp.viamonstra.com" 
#$CollectionName = "MassDeployment - iPXE Testing"
$CollectionName = "Windows Server 2019 - Hyper-V"
#$ImportFile = "E:\Demo\_LabEnvironment\ComputersForImport\Computers.csv"
#$ImportFile = "E:\Demo\_LabEnvironment\ComputersForImport\VOA Lab Hyper-V Hosts.csv"
#$ImportFile = "E:\Demo\_LabEnvironment\ComputersForImport\IPXE1 VMs on ROGUE-512.csv"
#$ImportFile = "E:\Demo\_LabEnvironment\ComputersForImport\ROGUE_824_Computers.csv"
#$ImportFile = "E:\Demo\_LabEnvironment\ComputersForImport\ROGUE_510_Computers.csv"
$ImportFile = "E:\Demo\_LabEnvironment\ComputersForImport\2PS-HyperV-Hosts.csv"

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName 
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" 

# Import the 
Import-CMComputerInformation -CollectionName $CollectionName -FileName $ImportFile -EnableColumnHeading $true -Verbose

# Update the ALL Systems collection. NOTE: DO NOT DO THIS IN PRODUCTION!!!
Invoke-CMCollectionUpdate -Name "All Systems" 
Start-Sleep -Seconds 90

# Update the target collection. 
Invoke-CMCollectionUpdate -Name $CollectionName
Start-Sleep -Seconds 60
