# Assume WindowsAutopilotInfo module is installed on the server
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
#Install-Module WindowsAutopilotIntune -Force

# To get a CSV for testing only, run the Get-WindowsAutoPilotInfo.ps1 with the following parameters
# C:\Windows\Temp\Get-WindowsAutoPilotInfo.ps1 -GroupTag "Marketing" -OutputFile C:\Windows\Temp\filename.csv


param(
    $Body,
    $RequestArgs
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

$Data = $Body | ConvertFrom-Json
$SerialNumber = $Data.'Device Serial Number'
$HardwareHash = $Data.'Hardware Hash'
$GroupTag = $Data.'Group Tag'

# Temp Johan - For manual testing
#$CsvData = Import-Csv -Path "E:\AP_CSV_Files1234567Z.csv"

#$SerialNumber = $csvdata.'Device Serial Number'
#$HardwareHash = $csvdata.'Hardware Hash'
#$GroupTag = $csvdata.'Group Tag'
#$LogFile = "E:\Logs\Invoke-PSDAutopilotRegistration_$SerialNumber.log"

# Check for serial number, abort if missing
If ($SerialNumber -eq ""){
    $LogFile = "$RestPSLocalRoot\endpoints\Logs\Invoke-PSDAutopilotRegistration_UnknownDevices.log"
    Write-Log "No serial number found, assuming all other info missing too. Aborting..."
    Return "Autopilot assignment failed"
    Break
}
Else{
    $LogFile = "$RestPSLocalRoot\endpoints\Logs\Invoke-PSDAutopilotRegistration_$SerialNumber.log"
}

# Delete any existing log file
#If (Test-path $LogFile){remove-item $LogFile -Force}

# Log the data from the JSON object
Write-Log "SerialNumber name sent from task sequence is $SerialNumber"
Write-Log "HardwareHash name sent from task sequence is $HardwareHash"
Write-Log "IntuneGroup name sent from task sequence is $GroupTag"

# TEMP Johan: Export to CSV File
$ExportPath = "E:\AP_CSV_Files"
$Data | Export-Csv -Path "$ExportPath\$($SerialNumber).csv" -NoTypeInformation -Force

#Return "Device with serial number $SerialNumber uploaded to Autopilot"
#Break

# Set Authentication info for to Microsoft Graph
$tenant = "viamonstra001.onmicrosoft.com"
$authority = "https://login.windows.net/$tenant"
$AppID = "031cea94-e5c5-4796-9c3b-eecb70f1f3e4"
$AppSecret = Get-Content "E:\Setup\Viamonstra Graph API Secret.txt"

# Log the settings
Write-Log "Intune tenant is $tenant"
Write-Log "Authority tenant is $authority"
Write-Log "AppID is $AppID"
Write-Log "AppSecret is **Secret**"

# Connect to Microsoft Graph
Update-MSGraphEnvironment -AppId $AppID -Quiet
Update-MSGraphEnvironment -AuthUrl $authority -Quiet
Connect-MSGraph -ClientSecret $AppSecret -Quiet

# Import device into Windows Autopilot
Write-Log "About to import device with serialNumber: $SerialNumber using groupTag: $GroupTag"
$NewDevice = Add-AutopilotImportedDevice -serialNumber $SerialNumber -hardwareIdentifier $HardwareHash -groupTag $GroupTag
Write-Log "Device import id is $($NewDevice.id)"

# Wait until the device have been imported
$importStart = Get-Date
$processingCount = 1
while ($processingCount -gt 0)
{
	$processingCount = 0
    $device = Get-AutopilotImportedDevice -id $NewDevice.id
	if ($device.state.deviceImportStatus -eq "unknown") {
		$processingCount = $processingCount + 1
	}
	$deviceCount = $NewDevice.Length

    $importDuration = (Get-Date) - $importStart
    $importSeconds = [Math]::Ceiling($importDuration.TotalSeconds)
	Write-Log "Waiting for device to be imported. Elapsed time to complete import: $importSeconds seconds"
	if ($processingCount -gt 0){
		Start-Sleep 30
	}
}
$importDuration = (Get-Date) - $importStart
$importSeconds = [Math]::Ceiling($importDuration.TotalSeconds)
$successCount = 0
Write-Log "$($device.serialNumber): $($device.state.deviceImportStatus) $($device.state.deviceErrorCode) $($device.state.deviceErrorName)"
if ($device.state.deviceImportStatus -eq "complete") {
	Write-Log "Device imported successfully.  Elapsed time to complete import: $importSeconds seconds"
}

# Give the import another 30 seconds
Start-Sleep -Seconds 30

# Wait until the devices can be found in Intune (should sync automatically)
# Max wait time is 10 minutes
$MaxSyncTimeInSeconds = 600
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
Write-Log "All devices synced. Elapsed time to complete sync: $syncSeconds seconds"

# Assign the computer name 
if ($AssignedComputerName -ne "")
{
    Write-Log "Assigning computer name $AssignedComputerName to device"
    Set-AutopilotDevice -Id $device.Id -displayName $AssignedComputerName
}

# Wait for assignment. Max time is 30 minutes
Start-Sleep -Seconds 10
$AssignmentStatus = $false
$MaxAssignmentTimeInSeconds = 1800
$assignStart = Get-Date
$processingCount = 1
while ($processingCount -gt 0)
{
	$processingCount = 0
	$APDevice = Get-AutopilotDevice -serial $SerialNumber -Expand
	if (-not ($APDevice.deploymentProfileAssignmentStatus.StartsWith("assigned"))) {
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
        $AssignmentStatus = $false
        #break
    }
    Else{
        # Assume all is good
        $AssignmentStatus = $true
    }
	
}

Start-Sleep -Seconds 10

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
