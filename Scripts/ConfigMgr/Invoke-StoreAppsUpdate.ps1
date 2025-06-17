param (
    [Parameter(Mandatory = $true)]
    [string]$WaitTime
   )

#$ts = $(get-date -f MMddyyyy_hhmmss)
#$Logfile = "C:\Windows\Temp\Invoke-StoreAppsUpdate_$ts.log"
$Logfile = "C:\Temp\Invoke-StoreAppsUpdate.log"

# Simple logging function
Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
   )

   $TimeGenerated = $(Get-Date -UFormat "%D %T")
   $Line = "$TimeGenerated : $Message"
   Add-Content -Value $Line -Path $LogFile -Encoding Ascii 

}

$AppUpdatesCount = (Get-WinEvent -LogName "Microsoft-Windows-AppXDeploymentServer/Operational" | 
    Where-Object {$_.ID -eq 478} ).count

Write-Log "----------------------------------------------------------------------"
Write-Log "Starting script. Current app updates count is: $AppUpdatesCount"
Write-Log "Pausing for $WaitTime seconds"
Start-Sleep -Seconds $WaitTime

$AppUpdatesCount = (Get-WinEvent -LogName "Microsoft-Windows-AppXDeploymentServer/Operational" | 
    Where-Object {$_.ID -eq 478} ).count

Write-Log "$WaitTime seconds pause completed, current app updates count is: $AppUpdatesCount"

# Update all UWP apps
Write-Log "Updating all UWP apps"
Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | 
    Invoke-CimMethod -MethodName UpdateScanMethod

$AppUpdatesCount = (Get-WinEvent -LogName "Microsoft-Windows-AppXDeploymentServer/Operational" | 
    Where-Object {$_.ID -eq 478} ).count

Write-Log "Current app updates count is: $AppUpdatesCount, will wait 60 minutes and report again"
Start-Sleep -Seconds 3600

$AppUpdatesCount = (Get-WinEvent -LogName "Microsoft-Windows-AppXDeploymentServer/Operational" | 
    Where-Object {$_.ID -eq 478} ).count

Write-Log "UWP apps updated"
Write-Log "Current app updates count is: $AppUpdatesCount"
Write-Log "Ending script..."
