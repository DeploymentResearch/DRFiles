$RemoteComputer = "CHI-W10PEER-001"

# Trigger-AppInstallation Function by Timmy Andersson (@TimmyITdotcom)
Function Trigger-AppInstallation {
    Param (
        [String][Parameter(Mandatory=$True, Position=1)] $Computername,
        [String][Parameter(Mandatory=$True, Position=2)] $AppName,
        [ValidateSet("Install","Uninstall")]
        [String][Parameter(Mandatory=$True, Position=3)] $Method
    )
 
    Begin {
        $Application = (Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" -ComputerName $Computername | Where-Object {$_.Name -like $AppName})
 
        $Args = @{EnforcePreference = [UINT32] 0
        Id = "$($Application.id)"
        IsMachineTarget = $Application.IsMachineTarget
        IsRebootIfNeeded = $False
        Priority = 'High'
        Revision = "$($Application.Revision)" }
    }
 
    Process {
        Invoke-CimMethod -Namespace "root\ccm\clientSDK" -ClassName CCM_Application -ComputerName $Computername -MethodName $Method -Arguments $Args
    }
    End {
    }
}

# Scriptblock for clearing the ConfigMgr Cache   
$ClearCMCacheScriptBlock = {
    $UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
    $Cache = $UIResourceMgr.GetCacheInfo()
    $CacheElements = $Cache.GetCacheElements() 
    foreach ($Element in $CacheElements) { 	$Cache.DeleteCacheElementEx($Element.CacheElementID, $true) }
}

# Scriptblock for getting ConfigMgr Cache info
$GetCMCacheScriptBlock = {
    $resman = new-object -com "UIResource.UIResourceMgr"; $cacheInfo = $resman.GetCacheInfo()
    $ccmcachetotal = ($cacheinfo.TotalSize)/1024
    $ccmcachetotalRounded = [math]::Round($ccmcachetotal,2)
    $ccmcachefree = ($cacheinfo.FreeSize)/1024
    $ccmcachefreeRounded = [math]::Round($ccmcachefree,2)
    $ccmcacheused = $ccmcachetotal - $ccmcachefree
    $ccmcacheusedRounded = [math]::Round($ccmcacheused,2)
    Write-Host "Total Cache Space: $ccmcachetotalRounded GB"
    Write-Host "Used Cache Space: $ccmcacheusedRounded GB"
    Write-Host "Free Cache Space: $ccmcachefreeRounded GB"
}

# Scriptblock for clearing the BITS Event Log
$ClearBITSEventLogScriptBlock = {
    $LogName = 'Microsoft-Windows-Bits-Client/operational'
    Get-WinEvent -ListLog $LogName | Where-Object { Wevtutil.exe cl $_.LogName }
}

# Scriptblock for getting a count of BITS Event Log entries
$GetBITSEventLogCountScriptBlock = {
    $LogName = 'Microsoft-Windows-Bits-Client/operational'
    (Get-WinEvent -FilterHashTable @{ LogName=$LogName } -ErrorAction SilentlyContinue | Measure-Object).count
}

# Scriptblock for getting download details
$GetBITSDownloadDetailsScriptBlock = {
    $LogName = 'Microsoft-Windows-Bits-Client/operational'
    $Events = (Get-WinEvent -FilterHashTable @{ LogName=$LogName; ID=60 } -ErrorAction SilentlyContinue  ) | 
        Where { ($_.Message -like "*BITS stopped transferring the CCMDTS Job transfer*") -and ($_.Message -like "*SMS_DP*")}| 
        Sort-Object -Descending TimeCreated | foreach {
    $_ | Add-Member -MemberType NoteProperty -Name name -Value $_.Properties[1].Value;
    $_ | Add-Member -MemberType NoteProperty -Name url -Value $_.Properties[3].Value;
    $_ | Add-Member -MemberType NoteProperty -Name bytesTotal -Value $_.Properties[8].Value;
    $_ | Add-Member -MemberType NoteProperty -Name bytesTransferred -Value $_.Properties[9].Value;
    $_ | Add-Member -MemberType NoteProperty -Name bytesTransferredFromPeer -Value $_.Properties[12].Value -PassThru;
    } 
    $events | Sort-Object TimeCreated -Descending | Select -First 30 TimeCreated, url, bytesTotal, bytesTransferred, bytesTransferredFromPeer
}



# Clear ConfigMgr Cache on remote machine
Invoke-Command -ScriptBlock $ClearCMCacheScriptBlock -ComputerName $RemoteComputer

# Get ConfigMgr Cache Info
Invoke-Command -ScriptBlock $GetCMCacheScriptBlock -ComputerName $RemoteComputer

# Clear the BITS Event Log on remote machine
Invoke-Command -ScriptBlock $ClearBITSEventLogScriptBlock -ComputerName $RemoteComputer

# Get BITS Log Entries Count
Invoke-Command -ScriptBlock $GetBITSEventLogCountScriptBlock -ComputerName $RemoteComputer

# Prepare for single app Test
Set-Location C: # File system commands won't work of connected to the ConfigMgr PSDrive
$DetectionFile = "Windows\Temp\300 MB Single File.txt" 
If (Test-path "\\$RemoteComputer\C`$\$DetectionFile") { Remove-Item "\\$RemoteComputer\C`$\$DetectionFile" }

# Run single app Test
$AppDeploymentName = "P2P Test Application - 300 MB Single File"
Trigger-AppInstallation -AppName $AppDeploymentName -Computername $RemoteComputer -Method Install

# Get BITS Download Details
Invoke-Command -ScriptBlock $GetBITSDownloadDetailsScriptBlock -ComputerName $RemoteComputer

