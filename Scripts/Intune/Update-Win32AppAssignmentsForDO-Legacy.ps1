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

