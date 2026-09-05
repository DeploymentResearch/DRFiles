<#
.SYNOPSIS
    Retrieves Entra ID audit log entries using the Graph PowerShell Module.
.DESCRIPTION
    Connects with the AuditLog.Read.All and Directory.Read.All scopes and queries the directory
    audit logs within a date range.
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

# Install the module. (You need admin on the machine.)
# Install-Module Microsoft.Graph
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Reports
$TenantID = ""
$Scopes = @(
    "AuditLog.Read.All",
    "Directory.Read.All"
)

$Tenant = Connect-MgGraph -TenantId $TenantID -Scopes $Scopes

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
