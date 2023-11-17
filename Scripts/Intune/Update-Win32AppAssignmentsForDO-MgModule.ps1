
# Install the module. (You need admin on the machine.)
# Install-Module Microsoft.Graph.Beta
# Uncomment line 38 to perform updates
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Beta.Devices.CorporateManagement
$TenantID = ""
$Scopes = @(
    "DeviceManagementApps.ReadWrite.All"
)
$Tenant = Connect-MgGraph -TenantId $TenantID -Scopes $Scopes

$Apps = Get-MgBetaDeviceAppManagementMobileApp -Filter "contains(displayName, 'P2P')"
($Apps | Measure-Object).Count
$Apps | Select-Object displayName

foreach ($App in $Apps) {

    $assignments = Get-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $App.id 
    Write-Output "Working on: $($App.displayName)"
    foreach ($assignment in $assignments) {
        # Show info from assignment: 
        $assignment | ConvertTo-Json -Depth 5 
        $body = @{
            "@odata.type" = "microsoft.graph.mobileAppAssignment"
            target = @{
                "@odata.type" = "microsoft.graph.allLicensedUsersAssignmentTarget"
            }
            # Create settings array for DO Foreground setting
            settings      = @{
                "@odata.type"                = "microsoft.graph.win32LobAppAssignmentSettings"
                deliveryOptimizationPriority = "Foreground"
            }
        }
        #Update-MgBetaDeviceAppMgtMobileAppAssignment -MobileAppId $App.id -mobileAppAssignmentId $assignment.Id -BodyParameter $body
    }
}

