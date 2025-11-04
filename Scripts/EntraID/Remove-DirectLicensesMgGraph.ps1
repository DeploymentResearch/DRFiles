#Based on https://learn.microsoft.com/en-us/microsoft-365/enterprise/remove-licenses-from-user-accounts-with-microsoft-365-powershell?view=o365-worldwide
# Install the module. (You need admin on the machine.)
# Install-Module Microsoft.Graph
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users
$TenantID = ""

$Scopes = @(
    "User.ReadWrite.All",
    "Organization.Read.All"
)

$Tenant = Connect-MgGraph -TenantId $TenantID -Scopes $Scopes

#Single users
#Set $M365Sku to the SKU you want to remove. Run Get-MgSubscribedSku to see all available SKUs.
$M365Sku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq 'DEVELOPERPACK_E5'
Set-MgUserLicense -UserId "johan@viamonstra.com" -RemoveLicenses @($M365Sku.SkuId) -AddLicenses @{}
Set-MgUserLicense -UserId "andrew@viamonstra.com" -RemoveLicenses @($M365Sku.SkuId) -AddLicenses @{}

#Multiple users with CSV
#Set $M365Sku to the SKU you want to remove. Run Get-MgSubscribedSku to see all available SKUs.
$usersList = Import-CSV -Path "C:\temp\DirectLicenseAccounts.csv"
$M365Sku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq 'DEVELOPERPACK_E5'
foreach($user in $usersList) {
  Set-MgUserLicense -UserId $user.UserPrincipalName -RemoveLicenses @($M365Sku.SkuId) -AddLicenses @{}
}

#Multiple users with Graph query
#Set $M365Sku to the SKU you want to remove. Run Get-MgSubscribedSku to see all available SKUs.
$usersList = Get-MgUser -filter "startswith(userPrincipalName,'andrew') or startswith(userPrincipalName,'johan')"
$M365Sku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq 'DEVELOPERPACK_E5'
foreach($user in $usersList) {
  Set-MgUserLicense -UserId $user.UserPrincipalName -RemoveLicenses @($M365Sku.SkuId) -AddLicenses @{}
}
