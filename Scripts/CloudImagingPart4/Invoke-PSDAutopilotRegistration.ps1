# This scripts assumes the WindowsAutopilotIntuneCommunity PowerShell module are installed on the server
# The WindowsAutopilotIntuneCommunity module also installs the following modules
# - Microsoft.Graph.Groups
# - Microsoft.Graph.Authentication
# - Microsoft.Graph.Identity.DirectoryManagement

param(
    $Body
)

#Start-Transcript -Path "E:\logs\TranscriptTest.log"

$Logfolder = "E:\Logs"
$DataFolder = "E:\APDataFiles"
$LogFile = "$Logfolder\PSDAutopilotRegistration.log"

function Write-Log {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        $Message,
        [Parameter(Mandatory=$false)]
        $ErrorMessage,
        [Parameter(Mandatory=$false)]
        $Component = "Script",
        [Parameter(Mandatory=$false)]
        [int]$Type
    )
    <#
    Type: 1 = Normal, 2 = Warning (yellow), 3 = Error (red)
    #>
   $Time = Get-Date -Format "HH:mm:ss.ffffff"
   $Date = Get-Date -Format "MM-dd-yyyy"
   if ($ErrorMessage -ne $null) {$Type = 3}
   if ($Component -eq $null) {$Component = " "}
   if ($Type -eq $null) {$Type = 1}
   $LogMessage = "<![LOG[$Message $ErrorMessage" + "]LOG]!><time=`"$Time`" date=`"$Date`" component=`"$Component`" context=`"`" type=`"$Type`" thread=`"`" file=`"`">"
   $LogMessage.Replace("`0","") | Out-File -Append -Encoding UTF8 -FilePath $LogFile
}

#Write-Log "TEST"

# Parse payload
#$payload = if ($Body -and $Body -ne 'null') { $Body | ConvertFrom-Json } else { @{} }

$Data = $Body | ConvertFrom-Json
$SerialNumber = $Data.'Device Serial Number'
$HardwareHash = $Data.'Hardware Hash'
$ComputerName = $Data.'ComputerName'
$AutopilotGroup = $Data.'IntuneGroup'

# Check for serial number, abort if missing
If ($SerialNumber -eq ""){
    $LogFile = "$LogFolder\Invoke-PSDAutopilotRegistration_UnknownDevices.log"
    Write-Log "No serial number found, assuming all other info missing too. Aborting..."
    Return "Autopilot assignment failed"
    Break
}
Else{
    $LogFile = "$LogFolder\Invoke-PSDAutopilotRegistration_$SerialNumber.log"
}

# Export Autopilot Data for tracking / auditing / testing
$Body | Out-File "$DataFolder\AutopilotData_$SerialNumber.json"

# Folder to persist job metadata (survives process restarts)
$jobRoot = 'E:\RestPS\Jobs'

# Create a job id and start background work
$jobId = ([guid]::NewGuid().ToString('n'))

Write-Log "Job $jobId initiated for serial number: $SerialNumber"

$job = Start-Job -Name $jobId -ScriptBlock {
    #param($payload)
    # ----- Long-running work goes here -----
    $RegisteringStartTime = Get-Date

    function Write-Log {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        $Message,
        [Parameter(Mandatory=$false)]
        $ErrorMessage,
        [Parameter(Mandatory=$false)]
        $Component = "Script",
        [Parameter(Mandatory=$false)]
        [int]$Type
    )
    <#
    Type: 1 = Normal, 2 = Warning (yellow), 3 = Error (red)
    #>
       $Time = Get-Date -Format "HH:mm:ss.ffffff"
       $Date = Get-Date -Format "MM-dd-yyyy"
       if ($ErrorMessage -ne $null) {$Type = 3}
       if ($Component -eq $null) {$Component = " "}
       if ($Type -eq $null) {$Type = 1}
       $LogMessage = "<![LOG[$Message $ErrorMessage" + "]LOG]!><time=`"$Time`" date=`"$Date`" component=`"$Component`" context=`"`" type=`"$Type`" thread=`"`" file=`"`">"
       $LogMessage.Replace("`0","") | Out-File -Append -Encoding UTF8 -FilePath $LogFile
    }

    $SerialNumber = $using:SerialNumber
    $HardwareHash = $using:HardwareHash
    $ComputerName = $using:ComputerName
    $AutopilotGroup = $using:AutopilotGroup
    $Logfolder = $using:Logfolder
    $LogFile = "$Logfolder\AutopilotRegistrationJobForSerialNumber_$SerialNumber.log"

    Write-Log "Autopilot Registration Process starting for serial Number: $SerialNumber"

    ######################

    # Generic settings
    # Note: AppID = Application (client) ID of the App Registration
    $TenantID = "<your tentant id>"
    $AppID = "<your app registration client id>" 
    $AppSecret = "<server-side code to lookup the secret key>"

    # Log the data from the JSON object
    Write-Log "Computer name: $ComputerName"
    Write-Log "Serial number: $SerialNumber"
    Write-Log "Hardware hash: $HardwareHash"
    Write-Log "Autopilot Entra Group name: $AutopilotGroup"

    # Import the PowerShell modules
    Import-Module WindowsAutopilotIntuneCommunity
    Import-Module Microsoft.Graph.Groups
    Import-Module Microsoft.Graph.Authentication
    Import-Module Microsoft.Graph.Identity.DirectoryManagement

    # Connect to Microsoft Graph using an App Registration
    # Note: Using the Connect-MgGraph cmdlet instead of the deprecated Connect-MSGraph
    $SecuredAppSecret = ConvertTo-SecureString -String $AppSecret -AsPlainText -Force
    $ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AppId, $SecuredAppSecret

    # Log the settings
    Write-Log "Trying to connect to Intune tenant ID: $TenantID using AppID: $AppID"
    Write-Log "First four characters of the AppSecret is: $($AppSecret.Substring(0,4))"

    # Clear any Graph cache
    Write-Log "Clearing any Graph cache"
    Disconnect-MgGraph -ErrorAction SilentlyContinue

    # Disable shared token cache for this run
    Write-Log "Disabling shared token cache for this run"
    $env:AZURE_IDENTITY_DISABLE_SHARED_TOKEN_CACHE = "true"

    try {
        Connect-MgGraph -TenantId $tenantID -ClientSecretCredential $ClientSecretCredential -NoWelcome -ErrorAction Stop
        Write-Log "Connection to Microsoft Graph successful"
    }
    catch {
        Write-Log "Unable to connect to Microsoft Graph" 
        Write-Log "Error message: $($_.Exception.Message)" 
        Return "Failure: Device with serial number $SerialNumber was not correctly registered with Autopilot"
    }


    try{
        $NewDevice = Add-AutopilotImportedDevice -serialNumber $SerialNumber -hardwareIdentifier $HardwareHash -Tenant $TenantID -AppId $AppID -AppSecret $AppSecret
        Start-Sleep -Seconds 3
        Write-Log "Device import successfully initiated"
        Write-Log "Device import id is $($NewDevice.id)"
    }
    catch {
        Write-Log "Could not import device"
        Write-Log "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Log "StatusDescription:" $_.Exception.Response.StatusDescription
    }

    # Wait until the device have been imported
    Write-Log "Waiting until the device have been imported..."
    $importStart = Get-Date
    $processingCount = 1
    while ($processingCount -gt 0)
    {
	    $processingCount = 0
        $device = Get-AutopilotImportedDevice -id $NewDevice.id -Tenant $TenantID -AppId $AppID -AppSecret $AppSecret
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
    Write-Log "SerialNumber: $($device.serialNumber), Device import status: $($device.state.deviceImportStatus), Return code: $($device.state.deviceErrorCode)"
    if ($device.state.deviceImportStatus -eq "complete") {
	    Write-Log "Device imported successfully.  Elapsed time to complete import: $importSeconds seconds"
    }

    # Give the import another 30 seconds
    Start-Sleep -Seconds 30

    # Wait until the device can be found in Intune (should sync automatically)
    # Max wait time is 10 minutes
    Write-Log "Waiting until the device can be found in Intune..."
    $MaxSyncTimeInSeconds = 600
    $syncStart = Get-Date
    $processingCount = 1
    while ($processingCount -gt 0)
    {
	    $processingCount = 0
	    $current | ForEach-Object {
		    if ($device.state.deviceImportStatus -eq "complete") {
			    $APdevice = Get-AutopilotDevice -id $device.state.deviceRegistrationId -Tenant $TenantID -AppId $AppID -AppSecret $AppSecret
			    if (-not $APdevice) {
				    $processingCount = $processingCount + 1
			    }
			    #$autopilotDevices += $APdevice
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
    Write-Log "Device synced. Elapsed time to complete sync: $syncSeconds seconds"


    # Add device to group (Group tag does not seem to like group names with spaces, so adding statically)
    Write-Log "Add device with serial: $SerialNumber to Intune/Entra group: $AutopilotGroup"
    $GroupID = (Get-MgGroup -Filter "displayName eq '$AutopilotGroup'").id
    $DirectoryObjectId = (Get-MgDeviceByDeviceId -DeviceId $APdevice.azureAdDeviceId).id

    try{
	    New-MgGroupMember -GroupId $GroupID -DirectoryObjectId $DirectoryObjectId
	    Write-Log "New Member $DirectoryObjectId added to DeviceTargetGroup $GroupID"
    }catch{
	    Write-Log "Could not add new member $DirectoryObjectId to DeviceTargetGroup  $GroupID"
	    Write-Log "Maybe the device is already member of the group"
    }

    # Assign the computer name (requires Device.ReadWrite.All)
    #For testing: $APdevice = Get-AutopilotDevice -serial $SerialNumber -Tenant $TenantID -AppId $AppID -AppSecret $AppSecret -Verbose
    if ($ComputerName -ne "")
    {
        try {
            Write-Log "Assigning computer name $ComputerName to device"
            Set-AutopilotDevice -Id $APdevice.id -displayName $ComputerName -Tenant $TenantID -AppId $AppID -AppSecret $AppSecret
        }
        catch {
            Write-Log "Could not add $ComputerName to Autopilot device with serial: $SerialNumber"
        }

    }
    Start-Sleep -Seconds 10

    # Wait for assignment. Max time is 30 minutes
    Write-Log "Waiting for assignment. Max time is 30 minutes..."

    $AutopilotStatus = $false
    $MaxAssignmentTimeInSeconds = 1800
    $assignStart = Get-Date
    $processingCount = 1

    while ($processingCount -gt 0) {
        $processingCount = 0
        $APDevice = Get-AutopilotDevice -serial $SerialNumber -Tenant $TenantID -AppId $AppID -AppSecret $AppSecret
    
        if (-not ($APDevice.deploymentProfileAssignmentStatus.StartsWith("assigned"))) {
            $processingCount++
        } else {
            # Device is actually assigned
            $AssignmentStatus = $true
            break
        }

        $assignDuration = (Get-Date) - $assignStart
        $assignSeconds = [Math]::Ceiling($assignDuration.TotalSeconds)
        Write-Log "Waiting for assignment... Elapsed assignment time so far is: $assignSeconds seconds"

        if ($processingCount -gt 0) {
            Start-Sleep 30
        }

        if ($assignSeconds -gt $MaxAssignmentTimeInSeconds) {
            Write-Log "Exceeded maximum time to complete sync. Time reported: $assignSeconds seconds"
            $AssignmentStatus = $false
            break
        }
    }

    # Log the assignment, and report back to the client
    if ($AssignmentStatus) {
        $assignDuration = (Get-Date) - $assignStart
        $assignSeconds = [Math]::Ceiling($assignDuration.TotalSeconds)
        Write-Log "Autopilot profile assigned to device. Elapsed time to complete assignment: $assignSeconds seconds"
        Write-Log "The deploymentProfileAssignmentStatus value is: $($APDevice.deploymentProfileAssignmentStatus)"
        Write-Log "Note: An assignment status of `"assignedUnknownSyncState`" is expected until the device checks in"

        $RegisteringDuration = (Get-Date) - $RegisteringStartTime
        $RegisteringDurationInSeconds = [Math]::Ceiling($RegisteringDuration.TotalSeconds)
        Write-Log "Device $ComputerName with serial number $SerialNumber is ready for Windows Autopilot. Total registration time: $RegisteringDurationInSeconds seconds"
        # Note: The client-side script looks for the word "Success" in the return object.
        Return "Success: Device $ComputerName with serial number $SerialNumber is ready for Windows Autopilot. Total registration time: $RegisteringDurationInSeconds seconds"

    } else {
        Write-Log "Assignment failed, but device with serial number $SerialNumber is uploaded to Autopilot"
        Return "Failure: Device with serial number $SerialNumber was not correctly registered with Autopilot"
    }

    ######################

    # return a final object
    [pscustomobject]@{
        status = 'completed'
        finishedAt = (Get-Date).ToString('o')
        result = @{ message = 'All done' }
    }
} #-ArgumentList $Body

# Persist a tiny job record so your status endpoint can find it
$record = [pscustomobject]@{
  id = $jobId
  SerialNumber = $SerialNumber 
  startedAt = (Get-Date).ToString('o')
}
$record | ConvertTo-Json | Set-Content -Path (Join-Path $jobRoot "$jobId.json") -Encoding UTF8

Return $record


