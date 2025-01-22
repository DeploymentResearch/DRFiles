$TenantID = "79663c21-ce72-4ffd-a430-31ff82455bd4"

$Scopes = @(
    "DeviceManagementManagedDevices.Read.All"
)

Connect-MgGraph -TenantId $TenantID -Scopes $Scopes

# Windows 11 23H2 Readiness group
$GroupID = "3473f23f-3dea-409e-b64c-1e702693d5bf"


# Single Device
$Devices = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq 'DA-INTUNE-001'"

# Multiple Devices
$Devices = Get-MgDeviceManagementManagedDevice -Filter "Startswith(OSVersion, '10.0.19045')"




foreach ($Device in $Devices) {

$Result = Get-MgBetaDeviceManagementManagedDeviceHealthScriptState -ManagedDeviceId $Device.Id -All | Format-list

If ($result.PreRemediationDetectionScriptOutput -eq "Exiting with no remediation required"){

    # Add device to group
	try{
		New-MgGroupMember -GroupId $GroupID -DirectoryObjectId $ADDevice.Id
		Write-Output "New Member $($device.id) added to DeviceTargetGroup $($targetDeviceGroup)"
	}catch{
		Write-Error "Could not add new member $($device.id) to DeviceTargetGroup $($targetDeviceGroup)"
		Write-Error "Maybe the device is already member of the group"
	}
    }

}



#############################################


#Install-Module Microsoft.Graph 
#Install-Module Microsoft.Graph -Scope CurrentUser -Force -ErrorAction Stop -WarningAction SilentlyContinue
#Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser -Force -ErrorAction Stop -WarningAction SilentlyContinue
#Install-Module Microsoft.Graph.Beta.DeviceManagement -Scope CurrentUser -Force -ErrorAction Stop -WarningAction SilentlyContinue
#Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -ErrorAction Stop -WarningAction SilentlyContinue

# Intune-DG-Windows 11 23H2 Readiness Group 
$GroupId = "bf685586-889a-4a42-be3b-a4725022506b" # aka "Intune-DG-Windows 11 23H2 Readiness"

# Connect to Microsoft Graph using an App Registration
# $AppId is Application (client) ID
$AppId = 'NOPE'
$TenantID = "NOPE"
$AppSecret = "NOPE"
$SecuredAppSecret = ConvertTo-SecureString -String $AppSecret -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AppId, $SecuredAppSecret

try {
    Connect-MgGraph -TenantId $tenantID -ClientSecretCredential $ClientSecretCredential -NoWelcome -ErrorAction Stop
    Write-Host "Connection to Microsoft Graph successful"
}
catch {
    Write-Warning "Unable to connect to Microsoft Graph"
    Write-Warning "Error message: $($_.Exception.Message)"
    Return "Call failed, could not connect to Microsoft Graph"
}

#Alternate credential
<#
$Scopes = @(
    "Device.Read.All"
    "Device.ReadWrite.All"
    "DeviceManagementManagedDevices.Read.All"
    "Group.ReadWrite.All"
    "GroupMember.ReadWrite.All"
    "User.Read"
)

Connect-MgGraph -TenantId $TenantID -Scopes $Scopes
#>


# Disconnect from Graph
#Disconnect-MgGraph

# Get all Windows 10 Devices 
$Devices = Get-MgDeviceManagementManagedDevice -Filter "Startswith(OSVersion, '10.0.19045')" 



$Devices.Count

$Remediation = "Create SetupConfig.ini for Windows 11 23H2 Feature Update"

#next lines for testing 
#'W10SIG01L-1K5YG' - Win11
#'W10SIG01L-cm2fg' - win10
#$Devices = $Devices | Where-Object { $_.DeviceName -like  'W10SIG01L-cm2fg*' } | select -First 1 
#$Devices.count

<#
# Get all devices with remediation (successful or not)
$DevicesWithRemediation = Get-MgBetaDeviceManagementManagedDeviceHealthScriptState -ManagedDeviceId * -All | Where-Object { $_.PolicyName -eq $Remediation }| Select PolicyName, LastStateUpdateDateTime, DetectionState

$DevicesWithRemediation = Get-MgBetaDeviceManagementManagedDeviceHealthScriptState -Search "DeviceName:*" -All 
$DevicesWithRemediation.Count

$URL = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"

$URL = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts?`$expand=assignments,runSummary"

$Scripts = (Invoke-MgGraphRequest -Uri $URL -Method Get).value.assignments | select -ExpandProperty assignments
$Scripts.displayname
#>
$URL = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
$Scripts = (Invoke-MgGraphRequest -Uri $URL -Method Get).value.id
$Scripts | Select displayname,id




#Get-MgBetaDeviceManagementDeviceHealthScriptRunSummary -DeviceHealthScriptId $deviceHealthScriptId

$Date = Get-Date -date "2024-11-13 01:00 PM"

$deviceHealthScriptId = "51860593-393d-420b-9e04-fbe66da2a99e"
$URL = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$deviceHealthScriptId/deviceRunStates?$expand=managedDevice"
$ManagedDevicesWithSuccessfulRemediation = (Invoke-MgGraphRequest -Uri $URL -Method Get).Value | Where-Object { $_.DetectionState -eq "success" -and $_.LastStateUpdateDateTime -gt $Date }

$ManagedDevicesWithSuccessfulRemediation.count

$ADDevices = Get-MgBetaDevice -Filter "Startswith(OperatingSystemVersion, '10.0.19045')" -All 
$ADDevices  = get-mggroupmember -groupid '4aed3b89-c078-428b-b28d-45e9e2e69d99'
$ADDevices.count

$ADDevices | Where

# We need a17f8679-a1e6-46e7-961e-eeee78352cc5
Get-MgDeviceByDeviceId -DeviceId "5dac96bb-f886-40c3-b684-6bef04cd738a"
Get-MgDeviceById -Ids "5dac96bb-f886-40c3-b684-6bef04cd738a"

Get-MgDevice -Filter "Startswith(DisplayName, 'W10SIG01L-cm2fg')" -All | Select *

Get-MgBetaDevice  -Filter "Startswith(DisplayName, 'W10SIG01L-cm2fg')" -All | Select *

Get-MgDeviceManagementManagedDevice -Filter "Startswith(DeviceName, 'W10SIG01L-cm2fg')" | Select *
#$ADDevices | Select -first 1 *

# We have a9e6cbfc-b19d-431f-a90e-55e2027e85a3

Get-MgGroupMember -groupid '4aed3b89-c078-428b-b28d-45e9e2e69d99' | select  -ExpandProperty AdditionalProperties |  Where-Object {$_.displayName -eq "W10SIG01L-CM2FG"}

foreach ($Device in $ManagedDevicesWithSuccessfulRemediation){
    Write-Host "Working on device: $($Device.DeviceName)"
    # Add to group
    try{
        $ADDevice = $ADDevices | Where-Object { $_.DeviceId -eq $Device.DeviceName } 
		#New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $ADDevice.id
		Write-Output "New Member $($device.id) added to DeviceTargetGroup $($GroupId)"
	}catch{
		Write-Warning "Could not add new member $($device.id) to DeviceTargetGroup $($GroupId)"
		Write-Warning "Maybe the device is already member of the group"
	}
}

Get-MgDevice -Search "displayname:$($Device.DeviceName)" -ConsistencyLevel eventual | Select *

$Device | Select *

foreach ($Device in $Devices){
    Write-Host "Working on device: $($Device.DeviceName)"
    $Result = Get-MgBetaDeviceManagementManagedDeviceHealthScriptState -ManagedDeviceId $Device.Id -All | Where-Object { $_.PolicyName -eq $Remediation }| Select PolicyName, LastStateUpdateDateTime, DetectionState
    
    $Date = Get-Date -date "2024-11-13 01:00 PM"
    
    If (($Result.DetectionState -eq "success") -and ($Result.LastStateUpdateDateTime -gt $Date)){
        Write-Host "Device found with remediation and within date: $($Device.DeviceName)"
        # Add to group
        try{
            $ADDevice = Get-MgDevice -Search "displayname:$($Device.DeviceName)" -ConsistencyLevel eventual
		    #New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $ADDevice.id
		    Write-Output "New Member $($device.id) added to DeviceTargetGroup $($GroupId)"
	    }catch{
		    Write-Warning "Could not add new member $($device.id) to DeviceTargetGroup $($GroupId)"
		    Write-Warning "Maybe the device is already member of the group"
	    }
    }
    Start-Sleep -Seconds 3
}