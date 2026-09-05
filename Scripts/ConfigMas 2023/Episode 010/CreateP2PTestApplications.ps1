<#
.SYNOPSIS
    Creates peer to peer test applications in ConfigMgr.
.DESCRIPTION
    Creates one application per source subfolder, adds a script deployment type, moves them
    into a console folder, and distributes the content to a distribution point group.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark / deploymentresearch.com
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2024-01-03 - Initial release
#>

#
# Written by Johan Arwidmark, @jarwidmark on Twitter
#

# Global Settings
$SiteCode = "PS1"
$ApplicationPrefix = "P2P Test Application" 
$CMApplicationFolder = "$($SiteCode):\Application\P2P Testing"
$Collection = "All Workstations"
$DPGroup = "HQ DPs"

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName 
}

Set-Location "C:"

# Get first level folders (only)
$DataSources = Get-ChildItem "\\cm01\Sources\P2P Test Packages" -directory

Set-Location "$($SiteCode):\" 

# Create P2P Test packages based on folder names
foreach ($Folder in $DataSources){
    $ApplicationName = "$ApplicationPrefix - $($Folder.Name)"
    $DataSource = $Folder.FullName
    $CommandLine = "cmd /c echo . > C:\Windows\Temp\$($Folder.Name).txt"
    $DetectionScript =  @"
if (Test-Path "C:\Windows\Temp\$($Folder.Name).txt") {
        Write-Host "Installed"
} 
else {
}
"@

    # Create the application
    $Application = New-CMApplication -Name $ApplicationName -AutoInstall $true
    
    # Create deploymment type
    Add-CMScriptDeploymentType -DeploymentTypeName $ApplicationName -ApplicationName $ApplicationName -ContentLocation $DataSource `
        -InstallCommand $CommandLine -InstallationBehaviorType InstallForSystem -ScriptType PowerShell -ScriptText $DetectionScript `
        -LogonRequirementType WhetherOrNotUserLoggedOn 

    # Move application to correct ConfigMgr folder
    Move-CMObject -FolderPath $CMApplicationFolder -InputObject $Application

    # Distribute the content
    Start-CMContentDistribution -ApplicationName $ApplicationName -DistributionPointGroupName $DPGroup

    # Deploy the application
    New-CMApplicationDeployment -CollectionName $Collection -Name $ApplicationName -DeployAction Install -DeployPurpose Available -UserNotification DisplayAll -AvailableDateTime (get-date) -TimeBaseOn LocalTime

}



