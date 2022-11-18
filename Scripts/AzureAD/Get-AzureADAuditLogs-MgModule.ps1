#Requires -Modules Microsoft.Graph
# Install the module. (You need admin on the machine.)
# Install-Module Microsoft.Graph
$TenantID = ""

Select-MgProfile -Name "beta"
$Tenant = Connect-MgGraph -TenantId $TenantID -Scopes "AuditLog.Read.All","Directory.Read.All"

#Get all device logs
Get-MgAuditLogDirectoryAudit -Filter "category eq 'Device'"

#Get all device logs in the past 14 days. Date must be properly formatted
[dateTime]$Past14Days = (get-date).addDays(-14)
$Past14DaysFormatted = Get-Date $Past14Days -Format yyyy-MM-dd
Get-MgAuditLogDirectoryAudit -Filter "category eq 'Device' and activityDateTime gt $Past14DaysFormatted"

#All actions initiated by Intune
Get-MgAuditLogDirectoryAudit -Filter "initiatedBy/app/displayName eq 'Microsoft Intune'" | Select-Object activitydisplayname,@{Name = 'Devicename'; Expression = {$_.targetresources.displayname}},result,resultreason

#Get failed actions
Get-MgAuditLogDirectoryAudit -Filter "result eq 'Failure'" | 
Select-Object activitydisplayname,@{Name = 'Devicename'; Expression = {$_.targetresources.displayname}},result,resultreason

#Get failed device creation
Get-MgAuditLogDirectoryAudit -Filter "activitydisplayname eq 'Add device' and result eq 'Failure'"
#Why did the device creation fail?
Get-MgAuditLogDirectoryAudit -Filter "activitydisplayname eq 'Add device' and result eq 'Failure'" | 
Select-Object activitydisplayname,@{Name = 'Devicename'; Expression = {$_.targetresources.displayname}},result,resultreason
