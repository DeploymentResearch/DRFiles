<#
.SYNOPSIS
    Forces license reprocessing for users in Entra ID.
.DESCRIPTION
    Connects with the Graph PowerShell Module and calls the license reprocessing action for the
    selected users, which is useful after changing group based licensing rules.
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
      1.0.0 - 2026-04-21 - Initial release
#>

# Install the module. (You need admin on the machine.)
# Install-Module Microsoft.Graph
Import-Module Microsoft.Graph.Authentication 
$TenantID = "<tenant-id>"

$Scopes = @(
    "User.ReadWrite.All",
    "Directory.ReadWrite.All"
)

# Connect to Graph
Connect-MgGraph -TenantId $TenantID -Scopes $Scopes

# Get all users 
$Users = Get-MgUser -All

# Get a single user
$Users = Get-MgUser -Filter "displayName eq 'Johan'"

# Invoke license processing for the user/users
foreach ($User in $Users) {
    try {
        Invoke-MgLicenseUser -UserId $User.Id
        Write-Host "Reprocessed: $($User.UserPrincipalName)" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed for $($User.UserPrincipalName): $_"
    }
}
