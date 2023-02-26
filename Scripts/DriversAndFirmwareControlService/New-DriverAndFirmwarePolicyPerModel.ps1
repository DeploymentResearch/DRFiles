# Requirements:
# Permissions to connect to the Graph API with the following scope: WindowsUpdates.ReadWrite.All
# Permission to view DeviceIDs in Azure AD
$versionMinimum = [Version]'7.0'
if ($versionMinimum -ge $PSVersionTable.PSVersion) { 
    throw "You need Powershell Version $versionMinimum to run this script" 
}

#Install-Module Microsoft.Graph

# Import the Microsoft.Graph module
Import-Module Microsoft.Graph

# Connect to Microsoft Graph
Connect-MgGraph -Scopes DeviceManagementManagedDevices.Read.All, WindowsUpdates.ReadWrite.All -ContextScope Process

# Select the right Microsoft Graph Profile (typically fails on Windows PowerShell, but works on PowerShell 7)
Select-MgProfile -Name beta

# Get a list of devices From Intune
$uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices"
$devices = Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject

$devices = $devices.value
$alldevices = @()
foreach ($device in $devices) {
    # Get some of the device data, purposely selecting a bit more than needed for now.
    # Also skipping Microsoft VMs
    If (($device.manufacturer -eq "Microsoft Corporation") -and ($device.model -eq "Virtual Machine")){
        # Do nothing
    }
    Else{
        # Add the device to the array
        $alldevices += $device | select-object deviceName,azureADDeviceId, serialNumber,model,manufacturer
    }
}

# Create a list of unique Hardware Models
$devicetypes = $alldevices | Select-Object manufacturer, Model -Unique

# Create Drivers and Firmware policies per model
# NOTE: MSGraph API does not yet (but will soon) support naming of the policies so we need to write that info somewhere else for now.
foreach ($devicetype in $devicetypes){
    $manufacturer = $devicetype.manufacturer
    $model = $devicetype.model
    switch -Wildcard ($manufacturer) {
        "*Microsoft*" {
            $manufacturer_normalized = "Microsoft"
        }
        "*HP*" {
            $manufacturer_normalized = "HP"
        }
        "*Hewlett-Packard*" {
            $manufacturer_normalized = "HP"
        }
        "*Dell*" {
            $manufacturer_normalized = "Dell"
        }
        "*Lenovo*" {
            $manufacturer_normalized = "Lenovo"
        }
    }    
    
    # Strip out vendor name from models to avoid stupidly looking policy names, currently only for HP. We'll use these later
    If ($model -match "HP"){
        $model_normalized = $model.Replace("HP ","")
    }
    Else{
        $model_normalized = $Model
    }

    # Create Audience for specific model
    $uri = "https://graph.microsoft.com/beta/admin/windows/updates/deploymentAudiences"
    $daAudience = Invoke-MgGraphRequest -Uri $uri -Method POST -Body @{} -ContentType 'application/json'

    # Add devices to the model-specific audience
    # Figure out batching for later (up to 200 devices can be batched at a time)    
    $devicestoadd = $alldevices | Where-Object { $_.model -eq $Model}
    foreach ($devicetoadd in $devicestoadd){
        $addMembersPostBody = @{
            addMembers = @(
                @{
                    "@odata.type" = "#microsoft.graph.windowsUpdates.azureADDevice"
                    id            = $devicestoadd.azureADDeviceId
                }
            )
        }
        Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/admin/windows/updates/deploymentAudiences('$($daAudience.id)')/updateAudience" -Body $addMembersPostBody -ContentType 'application/json' 
    }

    # Set policy name, will be saved locally due to missing name option in Graph API (again, will be added soon)
    $PolicyName = "$manufacturer_normalized $model_normalized"

    $manualUpdatePolicyParams = @{
        "@odata.type" = "#microsoft.graph.windowsUpdates.updatePolicy"
        audience = @{
            id = $daAudience.id
        }
        autoEnrollmentUpdateCategories = @(
            "driver"
        )
        complianceChanges = @()
        deploymentSettings = @{
            schedule = $null
            monitoring = $null
            contentApplicability = $null
            userExperience = $null
            expedite = $null
        }
    }
    
    $daPolicy = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/admin/windows/updates/updatePolicies" -Method POST -Body $manualUpdatePolicyParams -ContentType 'application/json'

    # For now, save audience id to a local text file. Will replace this with code to set name in Graph once it becomes available
    $PolicyFolder = "C:\Setup\UpdatePolicies"
    If (!(test-path $PolicyFolder )){New-Item -Path $PolicyFolder -ItemType Directory -Force}
    $PolicyFile = "$PolicyFolder\$PolicyName.txt"
    $daPolicy.id | Out-File -FilePath $PolicyFile

}

# List All Update Policies
(Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/admin/windows/updates/updatePolicies").Value