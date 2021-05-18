# Great post by SMSAgent (Trevor Jones is an SCCM architect based in the UK)
# https://smsagent.blog/tag/intune-powershell-scripts/

# Install the Microsoft.Graph.Intune module
Install-Module -Name Microsoft.Graph.Intune -Force
Import-Module Microsoft.Graph.Intune

# Connect to MS Graph and set the schema to beta
If ((Get-MSGraphEnvironment).SchemaVersion -ne "beta")
{
    $null = Update-MSGraphEnvironment -SchemaVersion beta
}
$Graph = Connect-MSGraph

# List the PowerShell scripts we have in Intune
$URI = "deviceManagement/deviceManagementScripts"
$IntuneScripts = Invoke-MSGraphRequest -HttpMethod GET -Url $URI
If ($IntuneScripts.value)
{
    $IntuneScripts = $IntuneScripts.value
}
$IntuneScripts | Select displayName

# Get a PowerShell script
Function Get-IntunePowerShellScript {
    Param($ScriptName)
    $URI = "deviceManagement/deviceManagementScripts"
    $IntuneScripts = Invoke-MSGraphRequest -HttpMethod GET -Url $URI
    If ($IntuneScripts.value)
    {
        $IntuneScripts = $IntuneScripts.value
    }
    $IntuneScript = $IntuneScripts | Where {$_.displayName -eq "$ScriptName"}
    Return $IntuneScript
}

# Get the script Id and then call Get again adding the script Id to the URL:
#$ScriptName = "Run MDT Task Sequence"
$ScriptName = "Tiny PowerShell Script"
$Script = Get-IntunePowerShellScript -ScriptName $ScriptName
$URI = "deviceManagement/deviceManagementScripts/$($Script.id)"
$IntuneScript = Invoke-MSGraphRequest -HttpMethod GET -Url $URI

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
$URI = "deviceManagement/deviceManagementScripts"
$Response = Invoke-MSGraphRequest -HttpMethod POST -Url $URI -Content $Json

# Update a Script
# To update an existing script, we follow a similar process to creating a new script, we create some JSON that contains the updated parameters then call the Patch method to update it. But first we need to get the Id of the script we want to update, using our previously created function:

$ScriptName = "Escrow Bitlocker Recovery Keys"
$IntuneScript = Get-IntunePowerShellScript -ScriptName $ScriptName

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
$URI = "deviceManagement/deviceManagementScripts/$($IntuneScript.id)"
$Response = Invoke-MSGraphRequest -HttpMethod PATCH -Url $URI -Content $Json

# Add an Assignment
# Before the script will execute anywhere it needs to be assigned to a group. To do that, we need the objectId of the AAD group we want to assign it to. To work with AAD groups I prefer to use the AzureAD module, so install that before continuing.
# We need to again get the script that we want to assign:

$ScriptName = "Escrow Bitlocker Recovery Keys"
$IntuneScript = Get-IntunePowerShellScript -ScriptName $ScriptName

# Then we prepare the necessary JSON and post the assignment

$Json = @"
{
    "deviceManagementScriptGroupAssignments": [
        {
          "@odata.type": "#microsoft.graph.deviceManagementScriptGroupAssignment",
          "id": "$($IntuneScript.Id)",
          "targetGroupId": "$($Group.ObjectId)"
        }
      ]
}
"@
$URI = "deviceManagement/deviceManagementScripts/$($IntuneScript.Id)/assign"
Invoke-MSGraphRequest -HttpMethod POST -Url $URI -Content $Json


# To replace the current assignment with a new assignment, simply change the group name and run the same code again. To add an additional assignment or multiple assignments, you’ll need to post all the assignments at the same time, for example:

$GroupNameA = "Intune - [Test] Bitlocker Key Escrow"
$GroupNameB = "Intune - [Test] Autopilot SelfDeploying Provisioning"
$GroupA = Get-AzureADGroup -SearchString $GroupNameA
$GroupB = Get-AzureADGroup -SearchString $GroupNameB
 
$Json = @"
{
    "deviceManagementScriptGroupAssignments": [
        {
          "@odata.type": "#microsoft.graph.deviceManagementScriptGroupAssignment",
          "id": "$($IntuneScript.Id)",
          "targetGroupId": "$($GroupA.ObjectId)"
        },
        {
          "@odata.type": "#microsoft.graph.deviceManagementScriptGroupAssignment",
          "id": "$($IntuneScript.Id)",
          "targetGroupId": "$($GroupB.ObjectId)"
        }
      ]
}
"@
$URI = "deviceManagement/deviceManagementScripts/$($IntuneScript.Id)/assign"
Invoke-MSGraphRequest -HttpMethod POST -Url $URI -Content $Json


# Delete an Assignment
# I haven’t yet figured out how to delete an assignment – the current documentation appears to be incorrect. If you can figure this out please let me know!

# Delete a Script
# To delete a script, we simply get the script Id and call the Delete method on it:

$ScriptName = "Escrow Bitlocker Recovery Keys"
$IntuneScript = Get-IntunePowerShellScript -ScriptName $ScriptName
$URI = "deviceManagement/deviceManagementScripts/$($IntuneScript.Id)"
Invoke-MSGraphRequest -HttpMethod DELETE -Url $URI