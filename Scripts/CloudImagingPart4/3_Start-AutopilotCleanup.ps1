#
# Written by Johan Arwidmark, @jarwidmark on Twitter
#
# Original Autopilot Cleanup code function written by Oliver Kiselbach, @okieselb on Twitter
#

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)][String] $SerialNumber,
        [Parameter(Mandatory=$false)][Switch] $IntuneCleanup,
        [Parameter(Mandatory=$false,DontShow)][Switch] $ShowCleanupRequestOnly
    )

# Script Variables
$LogFile = "C:\Windows\Temp\3_AutopilotCleanup.log"
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

Function Start-AutopilotCleanup(){

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)][String] $SerialNumber,
        [Parameter(Mandatory=$false)][Switch] $IntuneCleanup,
        [Parameter(Mandatory=$false,DontShow)][Switch] $ShowCleanupRequestOnly
    )


    If ($ShowCleanupRequestOnly){
        Write-Log "ShowCleanupRequestOnly mode is enabled"
    }
    
   

    $graphApiVersion = "Beta"
    $graphUrl = "https://graph.microsoft.com/$graphApiVersion"

    If ($serialNumber){
        Write-Log "Serial number sent in request was: $serialNumber" 
        $serialNumbers = $serialNumber
        
    }
    Else{
        $serialNumbers = (Get-AutopilotDevice).Serialnumber
    }

    # collection for the batch job deletion requests
    $requests = @()

    # according to the docs the current max batch count is 20
    # https://github.com/microsoftgraph/microsoft-graph-docs/blob/master/concepts/known-issues.md#limit-on-batch-size
    $batchMaxCount = 20;
    $batchCount = 0

    $i = 0

    $NumberOfMachinesToDelete = ($serialNumbers | Measure-Object).Count
    if ($NumberOfMachinesToDelete -gt 0){
        # loop through all serialNumbers and build batches of requests with max of $batchMaxCount
        Write-Log "About to delete the following $NumberOfMachinesToDelete devices:"
        foreach ($Number in $serialNumbers){
            Write-Log "Serial number: $Number"
        }

        for ($i = 0; $i -le $serialNumbers.Count; $i++) {
            # reaches batch count or total requests invoke graph call
            if ($batchCount -eq $batchMaxCount -or $i -eq $serialNumbers.Count){
                if ($requests.count -gt 0){
                    # final deletion batch job request collection
                    $content = [pscustomobject]@{
                        requests = $requests
                    }
            
                    # convert request data to proper format for graph request 
                    $jsonContent = ConvertTo-Json $content -Compress
        
                    if ($ShowCleanupRequestOnly){
                        #Write-Host $(ConvertTo-Json $content)
                    }
                    else{
                        try{
                            # delete the Autopilot devices as batch job
                            $result = Invoke-MSGraphRequest -Url "$graphUrl/`$batch" `
                                                            -HttpMethod POST `
                                                            -Content "$jsonContent"
                            
                            # display some deletion job request results (status=200 equals successfully transmitted, not successfully deleted!)
                            Write-Log $result.responses | Select-Object @{Name="Device Serial Number";Expression={$_.id}},@{Name="Deletion Request Status";Expression={$_.status}}
                            # according to the docs response might have a nextLink property in the batch response... I didn't saw this in this scenario so taking no care of it here
                        }
                        catch{
                            Write-Error $_.Exception 
                            break
                        }
                    }
                    # reset batch requests collection
                    $requests = @()
                    $batchCount = 0
                }
            }
            # add current serial number to request batch
            if ($i -ne $serialNumbers.Count){
                try{
                    # check if device with serial number exists otherwise it will be skipped
                    $device = Get-AutoPilotDevice -serial $serialNumbers[$i]
    
                    if ($device.id){
                        # building the request batch job collection with the device id
                        $requests += [pscustomobject]@{
                            id = $serialNumbers[$i]
                            method = "DELETE"
                            url = "/deviceManagement/windowsAutopilotDeviceIdentities/$($device.id)"
                        }

                        # try to delete the managed Intune device object, otherwise the Autopilot record can't be deleted (enrolled devices can't be deleted)
                        # under normal circumstances the Intune device object should already be deleted, devices should be retired and wiped before off-lease or disposal
                        if ($IntuneCleanup -and -not $ShowCleanupRequestOnly){
                            Get-IntuneManagedDevice | Where-Object serialNumber -eq $serialNumbers[$i] | Remove-DeviceManagement_ManagedDevices

                            # enhancement option: delete AAD record as well
                            # side effect: all BitLocker keys will be lost, maybe delete the AAD record at later time separately
                        }
                    }
                    else{
                        Write-Log "$($serialNumbers[$i]) not found, skipping device entry"
                    }
                }
                catch{
                    Write-Error $_.Exception 
                    break
                }
            }
            $batchCount++
        }
    }
    Else{
        # No Computers to delete
        Write-Log "No devices to delete, aborting script..."
        Break
    }
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

If ($SerialNumber){
    # Assuming Intune cleanup shall run as well
    Write-Log "SerialNumber parameter sent, assume individual wipe"
    Start-AutopilotCleanup -SerialNumber $SerialNumber -IntuneCleanup
}
Else{
    Write-Log "SerialNumber parameter not used, assume deletion of all devices in the tenant"
    Start-AutopilotCleanup -IntuneCleanup
}





Write-Log "Invoking Autopilot sync..."
Start-Sleep -Seconds 15
Invoke-AutopilotSync

Break

Write-Log "`nWaiting 60 seconds to re-check if devices are deleted..."
Start-Sleep -Seconds 60

# Check if all Autopilot devices are successfully deleted
$serialNumbers = Import-Csv $DeviceList | Select-Object -Unique 'Device Serial Number' | Select-Object -ExpandProperty 'Device Serial Number'

Write-Log "These devices couldn't be deleted:"
foreach ($serialNumber in $serialNumbers){
    $device = Get-AutoPilotDevice -serial $serialNumber
    Write-Log " $($device.serialNumber)"
}

