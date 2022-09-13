#
# Written by Johan Arwidmark, @jarwidmark on Twitter
#

# Global Settings
$SiteCode = "PS1"
$PackagePrefix = "P2P Test Package" 
$CMPackageFolder = "$($SiteCode):\Package\P2P Testing"
$Collection = "All Workstations"
$DPGroup = "HQ DPs"
$RootSourceFolderForPackages = "\\CM01\Sources\P2P Test Packages" # Will create one application for each first level subfolder

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName 
}

Set-Location "C:"

# Check for source folder
If (!(Test-Path -Path $RootSourceFolderForPackages)){
    Write-Warning "Specified source folder: $RootSourceFolderForPackages, does not exist, aborting..."
    Break
}

# Get first level folders (only)
$DataSources = Get-ChildItem $RootSourceFolderForPackages -directory
If (!($DataSources | Measure-Object).count -gt 0) {
    Write-Warning "No subfolders found in source folder: $RootSourceFolderForPackages, aborting..."
    Break
}


Set-Location "$($SiteCode):\" 

# Check for DP Group
If (!(Get-CMDistributionPointGroup -Name $DPGroup)){
    Write-Warning "Specified DP Group: $DPGroup, does not exist, aborting..."
    Break
}

# Create package folder in console if missing
If (!(Test-path $CMPackageFolder)){
    New-Item $CMPackageFolder
}

# Create All Workstations collection if missing
If (!(Get-CMCollection -Name $Collection)){

    New-CMCollection -CollectionType Device -Name $Collection -LimitingCollectionName "All Systems"
    $Query = @"
Select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.OperatingSystemNameandVersion like "%Workstation%"
"@
    Add-CMDeviceCollectionQueryMembershipRule -CollectionName $Collection -RuleName $Collection -QueryExpression $Query 
}


# Create P2P Test packages based on folder names
foreach ($Folder in $DataSources){
    
    $PackageName = "$PackagePrefix - $($Folder.Name)"
    $DataSource = $Folder.FullName
    $CommandLine = "cmd /c echo . > C:\Windows\Temp\$($Folder.Name).txt"

    Write-Host "Working on: $($Folder.Name)"
    # Create package
    $Package = New-CMPackage -Name $PackageName -Path $DataSource 
    $Package | Set-CMPackage -DistributionPriority Normal 

    # Move package to correct ConfigMgr folder
    Move-CMObject -FolderPath $CMPackageFolder -InputObject $Package

    # Create program
    $Program = New-CMProgram -PackageName "$PackageName" -StandardProgramName "$PackageName" -CommandLine $CommandLine -ProgramRunType WhetherOrNotUserIsLoggedOn -RunMode RunWithAdministrativeRights

    # Distribute the package
    Start-CMContentDistribution -PackageId $Package.PackageID -DistributionPointGroupName $DPGroup

    # Deploy the program as available
    New-CMPackageDeployment -StandardProgram -PackageId $Package.PackageID -ProgramName "$($Program.PackageName)" -CollectionName $Collection -DeployPurpose Available -FastNetworkOption DownloadContentFromDistributionPointAndRunLocally -SlowNetworkOption DoNotRunProgram
}



