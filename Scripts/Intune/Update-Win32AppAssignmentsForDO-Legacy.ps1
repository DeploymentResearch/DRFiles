<#
.SYNOPSIS
    Updates Delivery Optimization settings on Intune Win32 app assignments, legacy version.
.DESCRIPTION
    Finds the matching applications and updates the assignment settings so content is
    downloaded in foreground or background mode as required.
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
      1.0.0 - 2023-11-26 - Initial release
#>

Connect-MSGraph -ForceInteractive
$Apps = Get-DeviceAppManagement_MobileApps -Filter "contains(displayName, 'P2P')"
($Apps | Measure-Object).Count
$Apps | select displayName

# Create settings array for DO Foreground setting
$settings = @{
    "@odata.type"                  = "#microsoft.graph.win32LobAppAssignmentSettings"
    "deliveryOptimizationPriority" = "Foreground"
}


foreach ($App in $Apps){

    $assignments = Get-DeviceAppManagement_MobileApps_Assignments -MobileAppId $App.id 
    Write-Output "Working on: $($App.displayName)"
    foreach ($assignment in $assignments) {
        # Show info from assignment: 
        $assignment | ConvertTo-Json -Depth 5
        #Update-DeviceAppManagement_MobileApps_Assignments -MobileAppId $App.id -mobileAppAssignmentId $assignment.mobileAppAssignmentId -settings $settings
    }
}

