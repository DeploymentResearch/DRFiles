# Great post by SMSAgent (Trevor Jones is an SCCM architect based in the UK)
# https://smsagent.blog/tag/intune-powershell-scripts/

# Install the module. (You need admin on the machine.)
# Install-Module Microsoft.Graph.Beta
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Beta.DeviceManagement
Import-Module Microsoft.Graph.Beta.Groups

$TenantID = ""
$Scopes = @(
    "DeviceManagementApps.ReadWrite.All",
    "DeviceManagementConfiguration.ReadWrite.All"
    "Group.Read.All"
)
$Tenant = Connect-MgGraph -TenantId $TenantID -Scopes $Scopes

# List the PowerShell scripts we have in Intune
Get-MgBetaDeviceManagementScript

# Get a PowerShell script
$ScriptName = "Tiny PowerShell Script"
$Script = Get-MgBetaDeviceManagementScript -Filter "displayName eq '$ScriptName'"

# Get the script Id and then call Get again adding the script Id to the URL:
#$ScriptName = "Run MDT Task Sequence"
$ScriptName = "Tiny PowerShell Script"
$Script = Get-MgBetaDeviceManagementScript -Filter "displayName eq '$ScriptName'"
$URI = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$($Script.id)"
$IntuneScript = Invoke-MgGraphRequest -Uri $URI

# View script content
$Base64 =[Convert]::FromBase64String($IntuneScript.scriptContent)
[System.Text.Encoding]::UTF8.GetString($Base64)

# Create a Script

$ScriptPath = "C:\temp"
$ScriptName = "Escrow-BitlockerRecoveryKeys.ps1"
$Params = @{
    ScriptName = $ScriptName
    ScriptContent = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content -Path "$ScriptPath\$ScriptName" -Raw -Encoding UTF8)))
    DisplayName = "Escrow Bitlocker Recovery Keys"
    Description = "Backup Bitlocker Recovery key for OS volume to AAD"
    RunAsAccount = "system" # or user
    EnforceSignatureCheck = "false"
    RunAs32Bit = "false"
}
$Json = @"
{
    "@odata.type": "#microsoft.graph.deviceManagementScript",
    "displayName": "$($params.DisplayName)",
    "description": "$($Params.Description)",
    "scriptContent": "$($Params.ScriptContent)",
    "runAsAccount": "$($Params.RunAsAccount)",
    "enforceSignatureCheck": $($Params.EnforceSignatureCheck),
    "fileName": "$($Params.ScriptName)",
    "runAs32Bit": $($Params.RunAs32Bit)
}
"@
$URI = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts"
$Response = Invoke-MgGraphRequest -Uri $URI -Body $Json -Method POST -ContentType "application/json"

# Update a Script
# To update an existing script, we follow a similar process to creating a new script, we create some JSON that contains the updated parameters then call the Patch method to update it. But first we need to get the Id of the script we want to update, using our previously created function:

$ScriptName = "Escrow Bitlocker Recovery Keys"
$Script = Get-MgBetaDeviceManagementScript -Filter "displayName eq '$ScriptName'"

# In this example I have updated the content in the source script file so I need to read it in again, as well as updating the description of the script:

$ScriptPath = "C:\temp"
$ScriptName = "Escrow-BitlockerRecoveryKeys.ps1"
$Params = @{
    ScriptName = $ScriptName
    ScriptContent = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content -Path "$ScriptPath\$ScriptName" -Raw -Encoding UTF8)))
    DisplayName = "Escrow Bitlocker Recovery Keys"
    Description = "Backup Bitlocker Recovery key for OS volume to AAD (Updated 2020-03-19)"
    RunAsAccount = "system"
    EnforceSignatureCheck = "false"
    RunAs32Bit = "false"
}
$Json = @"
{
    "@odata.type": "#microsoft.graph.deviceManagementScript",
    "displayName": "$($params.DisplayName)",
    "description": "$($Params.Description)",
    "scriptContent": "$($Params.ScriptContent)",
    "runAsAccount": "$($Params.RunAsAccount)",
    "enforceSignatureCheck": $($Params.EnforceSignatureCheck),
    "fileName": "$($Params.ScriptName)",
    "runAs32Bit": $($Params.RunAs32Bit)
}
"@
$URI = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$($Script.id)"
$Response = Invoke-MgGraphRequest -Uri $URI -Body $Json -Method PATCH -ContentType "application/json"

# Add an Assignment
# Before the script will execute anywhere it needs to be assigned to a group. To do that, we need the objectId of the Entra (Azure AD) group we want to assign it to.
# We need to again get the script that we want to assign:

$ScriptName = "Escrow Bitlocker Recovery Keys"
$IntuneScript = Get-MgBetaDeviceManagementScript -Filter "displayName eq '$ScriptName'"
$GroupName = "sg-dept-Accounting"
$Group = Get-MgBetaGroup -Filter "DisplayName eq '$GroupName'"

# Then we prepare the necessary JSON and post the assignment

$Json = @"
{
    "deviceManagementScriptGroupAssignments": [
        {
          "@odata.type": "#microsoft.graph.deviceManagementScriptGroupAssignment",
          "id": "$($IntuneScript.Id)",
          "targetGroupId": "$($Group.Id)"
        }
      ]
}
"@
$URI = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$($IntuneScript.Id)/assign"
$Response = Invoke-MgGraphRequest -Uri $URI -Body $Json -Method POST -ContentType "application/json"


# To replace the current assignment with a new assignment, simply change the group name and run the same code again. To add an additional assignment or multiple assignments, you’ll need to post all the assignments at the same time, for example:

$GroupNameA = "Intune - [Test] Bitlocker Key Escrow"
$GroupNameB = "Intune - [Test] Autopilot SelfDeploying Provisioning"
$GroupA = Get-MgBetaGroup -Filter "DisplayName eq '$GroupNameA'"
$GroupB = Get-MgBetaGroup -Filter "DisplayName eq '$GroupNameB'"
 
$Json = @"
{
    "deviceManagementScriptGroupAssignments": [
        {
          "@odata.type": "#microsoft.graph.deviceManagementScriptGroupAssignment",
          "id": "$($IntuneScript.Id)",
          "targetGroupId": "$($GroupA.Id)"
        },
        {
          "@odata.type": "#microsoft.graph.deviceManagementScriptGroupAssignment",
          "id": "$($IntuneScript.Id)",
          "targetGroupId": "$($GroupB.Id)"
        }
      ]
}
"@
$URI = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$($IntuneScript.Id)/assign"
$Response = Invoke-MgGraphRequest -Uri $URI -Body $Json -Method POST -ContentType "application/json"


# Delete all Assignments
# Per @andrewjnet: Does not work as of 11/16/23. Filed issue on microsoftgraph repo https://github.com/microsoftgraph/msgraph-metadata/issues/504
<#
$ScriptName = "Escrow Bitlocker Recovery Keys"
$IntuneScript = Get-MgDeviceManagementScript -Filter "displayName eq '$ScriptName'"
# Management Scripts Assignments URI
$URI = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$($IntuneScript.Id)/groupAssignments"
$IntuneScriptAssignments = Invoke-MgGraphRequest -Uri $URI -Method GET
$intunescriptassignments.value.targetgroupid[0]| foreach {
    Remove-MgDeviceManagementScriptGroupAssignment -DeviceManagementScriptId $IntuneScript.Id -DeviceManagementScriptGroupAssignmentId $_ -Debug
}
#>


# Delete a Script
# To delete a script, we simply get the script Id and call the Delete method on it:

$ScriptName = "Escrow Bitlocker Recovery Keys"
$IntuneScript = Get-MgBetaDeviceManagementScript -Filter "displayName eq '$ScriptName'"
$URI = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$($IntuneScript.Id)"
$Response = Invoke-MgGraphRequest -Uri $URI -Method DELETE