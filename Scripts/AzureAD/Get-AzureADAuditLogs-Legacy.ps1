#Azure AD PowerShell cmdlets for reporting - https://docs.microsoft.com/en-us/azure/active-directory/reports-monitoring/reference-powershell-reporting
#Azure AD Preview module needed for the following commands
Install-module AzureADPreview -AllowClobber -force
Import-Module AzureADPreview

#Connect to Azure AD
Connect-AzureAD

#Get all device logs
Get-AzureADAuditDirectoryLogs -Filter "category eq 'Device'"

#Get all device logs in the past 14 days. Date must be properly formatted
[dateTime]$Past14Days = (get-date).addDays(-14)
$Past14DaysFormatted = Get-Date $Past14Days -Format yyyy-MM-dd
Get-AzureADAuditDirectoryLogs -Filter "category eq 'Device' and activityDateTime gt $Past14DaysFormatted"

#All actions initiated by Intune
Get-AzureADAuditDirectoryLogs -Filter "initiatedBy/app/displayName eq 'Microsoft Intune'"

#Get failed device creation
Get-AzureADAuditDirectoryLogs -Filter "activitydisplayname eq 'Add device' and result eq 'Failure'"
#Why did the device creation fail?
Get-AzureADAuditDirectoryLogs -Filter "activitydisplayname eq 'Add device' and result eq 'Failure'" | 
Select-Object activitydisplayname,@{Name = 'Devicename'; Expression = {$_.targetresources.displayname}},result,resultreason
