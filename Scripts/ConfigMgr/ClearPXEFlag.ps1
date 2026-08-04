# Global Settings
$SiteCode = "PS1" 
$SiteServer = "cm01.corp.viamonstra.com" 

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer 
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" 

Function Get-DevicesWithActivePXEFlag {
    param (
        [String][Parameter(Mandatory=$true, Position=1)] $SiteServer,
        [String][Parameter(Mandatory=$true, Position=2)] $SiteCode
    )
    try {
        $return = @()
        $DeploymentCache = @{}
        $Devices = Get-WmiObject -Namespace "ROOT\SMS\site_$SiteCode" -ComputerName $SiteServer -Query "SELECT * FROM SMS_LastPXEAdvertisement"
        foreach ($Device in $Devices) {
            if ($DeploymentCache.ContainsKey($Device.AdvertisementID)) {
                $deployment = $DeploymentCache[$Device.AdvertisementID]
            } else {
                $deployment = Get-WmiObject -Namespace "ROOT\SMS\site_$SiteCode" -ComputerName $SiteServer -Query ("SELECT * FROM SMS_DeploymentInfo WHERE DeploymentID = '" + $Device.AdvertisementID + "'")
                $DeploymentCache.Add($deployment.DeploymentID, $deployment)
            }
            $return += [PSCustomObject]@{
                "ComputerName"=$Device.NetbiosName
                "LastPXEAdvertisement"=$Device.LastPXEAdvertisementTime
                "GUID"=$Device.SMBIOSGUID
                "DeploymentID"=$deployment.DeploymentID
                "Collection"=$deployment.CollectionName
                "Target"=$deployment.TargetName
            }
        }
        return $return
    } catch {
 
    }
}


$Devices = Get-DevicesWithActivePXEFlag -SiteServer $SiteServer -SiteCode "$SiteCode"
foreach ($Device in $Devices){
    Write-Host "Clearing PXE Flag for $($Device.ComputerName)"
    Clear-CMPxeDeployment -Device (Get-CMDevice -Name $Device.ComputerName) # -Verbose
}
