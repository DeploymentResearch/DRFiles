#https://learn.microsoft.com/en-us/microsoft-365/enterprise/remove-licenses-from-user-accounts-with-microsoft-365-powershell?view=o365-worldwide
Connect-Graph -Scopes User.ReadWrite.All, Organization.Read.All

#Single users
$e5Sku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq 'DEVELOPERPACK_E5'
Set-MgUserLicense -UserId "johan@viamonstra.com" -RemoveLicenses @($e5Sku.SkuId) -AddLicenses @{}
Set-MgUserLicense -UserId "andrew@viamonstra.com" -RemoveLicenses @($e5Sku.SkuId) -AddLicenses @{}

#Multiple users with CSV
$usersList = Import-CSV -Path "C:\temp\DirectLicenseAccounts.csv"
$e5Sku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq 'DEVELOPERPACK_E5'
foreach($user in $usersList) {
  Set-MgUserLicense -UserId $user.UserPrincipalName -RemoveLicenses @($e5Sku.SkuId) -AddLicenses @{}
}

#Multiple users with graph query
$usersList = Get-MgUser -filter "startswith(userPrincipalName,'andrew') or startswith(userPrincipalName,'johan')"
$e5Sku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq 'DEVELOPERPACK_E5'
foreach($user in $usersList) {
  Set-MgUserLicense -UserId $user.UserPrincipalName -RemoveLicenses @($e5Sku.SkuId) -AddLicenses @{}
}