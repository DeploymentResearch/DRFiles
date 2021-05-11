#
# Written by Johan Arwidmark, @jarwidmark on Twitter
#

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)][String] $SerialNumber,
        [Parameter(Mandatory=$true)][String] $HardwareHash,
        [Parameter(Mandatory=$true)][String] $IntuneGroup,
        [Parameter(Mandatory=$true)][String] $AssignedUser,
        [Parameter(Mandatory=$true)][String] $ComputerName
    )

# Script Variables
$LogFile = "C:\Windows\Temp\2_AutopilotRegistration.log"
$AppInfoImportFile = "C:\Windows\Temp\AppInfo.txt"

Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
   )

   $TimeGenerated = $(Get-Date -UFormat "%D %T")
   $Line = "$TimeGenerated $Message"
   Add-Content -Value $Line -Path $LogFile -Encoding Ascii

}

# Assume the WindowsAutopilotInfo module is already installed
# Importing the  WindowsAutopilotInfo, AzureAD, and Microsoft.Graph.Intune modules"
Write-Log "Importing the  WindowsAutopilotInfo, AzureAD, and Microsoft.Graph.Intune modules"
Import-Module WindowsAutoPilotIntune
Import-Module AzureAD
Import-Module Microsoft.Graph.Intune

# Import Authentication info for to Microsoft Graph from text file
Write-Log "Import Authentication info for to Microsoft Graph from text file: $AppInfoImportFile"
$AppInfo = Import-Csv -Path $AppInfoImportFile | Select -First 1
$TenantName = $AppInfo.TenantName
$TenantInitialDomain = $AppInfo.TenantInitialDomain
$AppName = $AppInfo.AppName
$AppID = $AppInfo.AppID
$AppSecret = $AppInfo.ClientSecret

# Construct Authority tenant
$Authority = "https://login.windows.net/$TenantInitialDomain"

# Log the settings
Write-Log "Intune tenant name is: $TenantName"
Write-Log "Intune tenant initial domain name is: $TenantInitialDomain"
Write-Log "Authority tenant is: $Authority"
Write-Log "AppName is: $AppName"
Write-Log "AppID is $AppID"
Write-Log "AppSecret is **Secret**"

# Connect to Microsoft Graph
Update-MSGraphEnvironment -AppId $AppID -Quiet
Update-MSGraphEnvironment -AuthUrl $authority -Quiet
Connect-MSGraph -ClientSecret $AppSecret -Quiet

# Verify that Intune group exist
$aadGroupID = (Get-Groups -Filter "DisplayName eq '$IntuneGroup'").id
If ($aadGroupID){
    Write-Log "All OK, Intune group $IntuneGroup found, ID is $aadGroupID" 
}
Else{
    Write-Log "Intune group $IntuneGroup not found, aborting script..." 
    Break
}

# Log the parameters (except $Hardwarehash)
Write-Log "Computer Name will be set to $ComputerName"
Write-Log "Serial Number for this device is $SerialNumber"
Write-Log "Assigned user for this device is $AssignedUser"
Write-Log "Intune group set to: $IntuneGroup"

# Check if devices already exist
$device = Get-AutoPilotDevice -Serial $serialNumber
If ($device){
    Write-Log "Machine with serial number: $serialNumber exists. Please run the cleanup, and run this script again"
    Break 
}
Write-Log "All OK so far, machine with serial number: $serialNumber does not exist"

# Start importing computers
$Imported = Add-AutopilotImportedDevice -serialNumber $SerialNumber -hardwareIdentifier $HardwareHash -assignedUser $AssignedUser -groupTag $IntuneGroup 
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

# Assign the computer name 
# Note that after changing the device (computer) name, you won’t see the new value right away in Intune, 
# at least until you initiate a sync (or wait up to 12 hours for the next one to occur).  
# The value has been set in the Windows Autopilot service, so it will take effect right away
if ($ComputerName -ne "")
{
    Write-Log "Assigning computer name $ComputerName to device"
    Set-AutopilotDevice -Id $device.Id -displayName $ComputerName
}
