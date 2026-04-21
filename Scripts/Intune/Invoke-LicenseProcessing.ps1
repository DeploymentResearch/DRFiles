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
