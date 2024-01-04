### Single Application
$AppDeploymentName = "P2P Test Application - 300 MB Single File"

### static List of machines

$RemoteComputers = @(
    "CHI-W10PEER-001"
    "CHI-W10PEER-002"
    "CHI-W10PEER-003"
)

foreach ($RemoteComputers in $RemoteComputers) {
    # Do things for each computer, for example
    Trigger-AppInstallation -AppName $AppDeploymentName -Computername $RemoteComputer -Method Install
}



##### Get active members from a collections

# Global Settings
$SiteCode = "PS1" 
$ProviderMachineName = "cm01.corp.viamonstra.com" 
$CollectionName = "DELL Client Computers"

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

# Get all active machines in a specific collection
$RemoteComputers = Get-CMCollectionMember -CollectionName $CollectionName | Where-Object { $_.ClientActiveStatus -eq 1 } | Select Name

# Copy the file to all clients
Set-Location C:
Foreach ($RemoteComputer in $RemoteComputers){
    # Do things for each computer, for example
    Trigger-AppInstallation -AppName $AppDeploymentName -Computername $RemoteComputer.Name -Method Install
}



#### Get Application Deployments from ConfigMgr

# Get list of application deployments
Set-Location $SiteCode`:
$AppsToInstall = Get-CMApplicationDeployment -Name "*P2P*"
#$AppsToInstall.Count
#$AppsToInstall | Select ApplicationName
foreach ($AppToInstall in $AppsToInstall){
    # Do things for each application deployment, for example
    $AppDeploymentName = $AppToInstall.ApplicationName
    Trigger-AppInstallation -AppName $AppDeploymentName -Computername $RemoteComputer -Method Install    
}

### Combine list of machines with list of applications
Foreach ($RemoteComputer in $RemoteComputers){
    # Do things for each computer, for example
    foreach ($AppToInstall in $AppsToInstall){
        # Do things for each application deployment, for example
        $AppDeploymentName = $AppToInstall.ApplicationName
        Trigger-AppInstallation -AppName $AppDeploymentName -Computername $RemoteComputer -Method Install    
    }
}
