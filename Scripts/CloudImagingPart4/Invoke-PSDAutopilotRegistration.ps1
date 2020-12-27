param(
    $RequestArgs,
    $Body
)

Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
   )

   $TimeGenerated = $(Get-Date -UFormat "%D %T")
   $Line = "$TimeGenerated $Message"
   Add-Content -Value $Line -Path $LogFile -Encoding Ascii

}

# Set Authentication info for to Microsoft Graph
$tenant = "CHANGE-ME"
$authority = "https://login.windows.net/$tenant"
$AppID = "CHANGE-ME"
$AppSecret = "CHANGE-ME"

# Log the settings
Write-Log "Intune tenant is $tenant"
Write-Log "Authority tenant is $authority"
Write-Log "AppID is $AppID"
Write-Log "AppSecret is **Secret**"

# Assume WindowsAutopilotInfo module is installed on the server
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
#Install-Module WindowsAutopilotIntune -Force

# Install the Get-WindowsAutoPilotInfo script 
# Install-Script -Name Get-WindowsAutoPilotInfo
# Copy-Item -Path "C:\Program Files\WindowsPowerShell\Scripts\Get-WindowsAutoPilotInfo.ps1" -Destination "E:\MDTProduction\Scripts" -Force

# Get computer name from the argument sent to this script 
$AssignedComputerName = $RequestArgs.split("=")[1]
Write-Log "Computer name sent from task sequence is $AssignedComputerName"

If ($AssignedComputerName -eq ""){
    Write-Log "No computer name found, assuming all other info missing too. Aborting..."
    Return "Autopilot assignment failed"
    Break
}
Else{
    $LogFile = "$RestPSLocalRoot\endpoints\Logs\Invoke-PSDAutopilotRegistration_$AssignedComputerName.log"
}


# Get data from the JSON object sent to this scripot
#$Body = Import-Csv "E:\Setup\1341-2415-3347-3372-8169-9672-55_Imported_11162020_102621.csv" | ConvertTo-Json
$SerialNumber = ($Body | ConvertFrom-Json | Select -First 1)."Device Serial Number"
$HardwareHash = ($Body | ConvertFrom-Json | Select -First 1)."Hardware Hash"
$IntuneGroup = ($Body | ConvertFrom-Json | Select -First 1)."Group Tag"

# Log the data from the JSON object
Write-Log "SerialNumber name sent from task sequence is $SerialNumber"
Write-Log "HardwareHash name sent from task sequence is $HardwareHash"
Write-Log "IntuneGroup name sent from task sequence is $IntuneGroup"

Return "Device with serial number $SerialNumber uploaded to Autopilot"

BREAK

# Connect to Microsoft Graph
Update-MSGraphEnvironment -AppId $AppID -Quiet
Update-MSGraphEnvironment -AuthUrl $authority -Quiet
Connect-MSGraph -ClientSecret $AppSecret -Quiet

# Import device into Windows Autopilot (purposly not using the group tag, will deal with that later)
$Imported = Add-AutopilotImportedDevice -serialNumber $SerialNumber -hardwareIdentifier $HardwareHash
Write-Log "Device import id is $($Imported.id)"

# Wait until the device have been imported
$importStart = Get-Date
$processingCount = 1
while ($processingCount -gt 0)
{
	$processingCount = 0
    $device = Get-AutopilotImportedDevice -id $Imported.id
	if ($device.state.deviceImportStatus -eq "unknown") {
		$processingCount = $processingCount + 1
	}
	$deviceCount = $Imported.Length
	Write-Log "Waiting for device to be imported"
	if ($processingCount -gt 0){
		Start-Sleep 30
	}
}
$importDuration = (Get-Date) - $importStart
$importSeconds = [Math]::Ceiling($importDuration.TotalSeconds)
$successCount = 0
# Write-Log "$($device.serialNumber): $($device.state.deviceImportStatus) $($device.state.deviceErrorCode) $($device.state.deviceErrorName)"
if ($device.state.deviceImportStatus -eq "complete") {
	Write-Log "Device imported successfully.  Elapsed time to complete import: $importSeconds seconds"
}


# Wait until the devices can be found in Intune (should sync automatically)
# Max wait time is 10 minutes
$MaxSyncTimeInSeconds = 600
Start-Sleep -Seconds 10
$syncStart = Get-Date
$processingCount = 1
while ($processingCount -gt 0)
{
	$processingCount = 0
	$current | % {
		if ($device.state.deviceImportStatus -eq "complete") {
			$device = Get-AutopilotDevice -id $device.state.deviceRegistrationId
			if (-not $device) {
				$processingCount = $processingCount + 1
			}
			$autopilotDevices += $device
		}	
	}
	Write-Log "Waiting for device to be synced"
	if ($processingCount -gt 0){
		Start-Sleep 30
	}
    $syncDuration = (Get-Date) - $syncStart
    $syncSeconds = [Math]::Ceiling($syncDuration.TotalSeconds)
    If ($syncSeconds -gt $MaxSyncTimeInSeconds){
        Write-Log "Exceeding maxium time to complete sync. Time reported: $syncSeconds seconds"
        break
    }
    
}
$syncDuration = (Get-Date) - $syncStart
$syncSeconds = [Math]::Ceiling($syncDuration.TotalSeconds)
Write-Log "All devices synced.  Elapsed time to complete sync: $syncSeconds seconds"


# Get the Azure AD device ID
$aaDeviceID = $device.azureActiveDirectoryDeviceId
Write-Log "Azure AD device ID is $aaDeviceID" 

# Get the Intune group ID
$aadGroupID = (Get-Groups -Filter "DisplayName eq '$IntuneGroup'").id
Write-Log "Intune group ID is $aadGroupID" 

# Add the device to the Intune group
# And Yes, I know that the Get-WindowsAutoPilotInfo.ps1 scripts supports the -AddToGroup parameter, but...
# I prefer to use Microsoft Graph directly since the script needs to use it anyway, and is already connected to it.
# The -AddToGroup parameter requires a separate connection to the AzureAD API.
$DeviceUri = [uri]::EscapeUriString("https://graph.microsoft.com/V1.0/devices?`$filter=deviceId eq '$aaDeviceID'")
Write-Log "DeviceUri is $DeviceUri"
$dev = (Invoke-MSGraphRequest -url $DeviceUri -HttpMethod get).Value
Write-Log "Dev is $($dev.id)"

$body = @"
{
    "@odata.id": "https://graph.microsoft.com/v1.0/directoryObjects/$($dev.id)"
}
"@

$GroupUri = [uri]::EscapeUriString("https://graph.microsoft.com/v1.0/groups/$aadGroupID/members/`$ref")
Write-Log "GroupUri is $GroupUri"
Write-Log "Adding device id $($dev.id) to Intune group $IntuneGroup ($aadGroupID)"
Invoke-MSGraphRequest -url $GroupUri -HttpMethod POST -Content $body

# Assign the computer name 
if ($AssignedComputerName -ne "")
{
    Write-Log "Assigning computer name $AssignedComputerName to device"
    Set-AutopilotDevice -Id $device.Id -displayName $AssignedComputerName
}

# Force an Windows Autopilot syncronization
Invoke-AutopilotSync

# Wait for assignment. Max time is 30 minutes
Start-Sleep -Seconds 10
$AssignmentStatus = $False
$MaxAssignmentTimeInSeconds = 1800
$assignStart = Get-Date
$processingCount = 1
while ($processingCount -gt 0)
{
	$processingCount = 0
	$device = Get-AutopilotDevice -id $device.id -Expand
	if (-not ($device.deploymentProfileAssignmentStatus.StartsWith("assigned"))) {
		$processingCount = $processingCount + 1
	}
    $assignDuration = (Get-Date) - $assignStart
    $assignSeconds = [Math]::Ceiling($assignDuration.TotalSeconds)
    Write-Log "Waiting for assignment... Elapsed assignment time so far is: $assignSeconds seconds"
	if ($processingCount -gt 0){
		Start-Sleep 30
	}
    If ($assignSeconds -gt $MaxAssignmentTimeInSeconds){
        Write-Log "Exceeding maxium time to complete sync. Time reported: $assignSeconds seconds"
        $AssignmentStatus = $true
        break
    }
	
}

if ($AssignmentStatus -eq $true){
    $assignDuration = (Get-Date) - $assignStart
    $assignSeconds = [Math]::Ceiling($assignDuration.TotalSeconds)
    Write-Log "Profile assigned to the device.  Elapsed time to complete assignment: $assignSeconds seconds"
    Write-Log "Device with serial number $SerialNumber uploaded to Autopilot"
    Return "Device with serial number $SerialNumber uploaded to Autopilot"
}
Else{    
    Write-Log "Assignment failed, but device with serial number $SerialNumber uploaded to Autopilot"
    Return "Device with serial number $SerialNumber uploaded to Autopilot"
}
