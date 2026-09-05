<#
.SYNOPSIS
    Creates, distributes, and deploys a ConfigMgr application end to end.
.DESCRIPTION
    Creates the application with an MSI deployment type, distributes the content, creates a
    collection, adds members, and deploys the application to it.
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
      1.0.0 - 2022-01-02 - Initial release
#>

$ApplicationName = "TechSmith Snagit 2021"
$ApplicationDescription = "Screen Capture Utility"
$CollectionName = "TechSmith Snagit 2021"
$MSILocation = "\\corp.viamonstra.com\fs1\sources\Software\Utilities\TechSmith Snagit 2021\snagit.msi"

# Create the application
New-CMApplication -Name $ApplicationName -Description $ApplicationDescription -AutoInstall $true -Verbose
Add-CMMsiDeploymentType -ApplicationName $ApplicationName  -ContentLocation $MSILocation -InstallationBehaviorType InstallForSystem -Verbose

# Distribute the content
Start-CMContentDistribution -ApplicationName $ApplicationName -DistributionPointGroupName "HQ DPs" -Verbose

# Create Collection
New-CMCollection -Name $CollectionName -CollectionType Device -LimitingCollectionName "All Workstations"

# Deploy the application
New-CMApplicationDeployment -CollectionName $CollectionName -Name $ApplicationName -DeployAction Install -DeployPurpose Available -UserNotification DisplayAll -AvailableDateTime (get-date) -TimeBaseOn LocalTime

# Add PC0008 to collection
$Machine = "PC0008"
Add-CMDeviceCollectionDirectMembershipRule -CollectionName $ApplicationName -ResourceID (Get-CMDevice -Name $Machine).ResourceID -Verbose
