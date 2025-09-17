﻿# Script to cleanup Windows before an Inplace Upgrade
# Author: Johan Arwidmark
# Twitter: @jarwidmark
# LinkedIn: https://www.linkedin.com/in/jarwidmark

$Logfile = "C:\Windows\Temp\Invoke-DiskCleanup.log"
$StartTime = Get-Date

# Script cleans the following components (change to $False to disable):
$CleanDriversFolder = $True
$CleanCBSTempFolder = $True
$CleanConfigMgrCache = $True # Configured for to delete content older than 5 days
$CleanWindowsTempFolder = $True
$CleanDOCache = $True
$ClearBranchCacheCache = $True
$NativeDiskCleanup = $True

# Delete any existing logfile if it exists 
If (Test-Path $Logfile) { Remove-Item $Logfile -Force -ErrorAction SilentlyContinue -Confirm:$false }

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

Function FreeSpace {
    $Disk = Get-wmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" 
    $FreeSpace = [MATH]::ROUND($disk.FreeSpace /1GB,2)
    Return $FreeSpace
}

# Get Free Diskspace before cleanup
$FreeSpaceBeforeCleanup = FreeSpace
Write-Log "Cleanup Started"
Write-Log "Free disk space before cleanup is $FreeSpaceBeforeCleanup GB"

If ($CleanDriversFolder) {
    # Remove any existing drivers folder
    Write-Log "Removing any existing drivers folder"
    $CurrentDiskSpace = FreeSpace
    Write-Log "- Free disk space before is: $CurrentDiskSpace GB"
    $Path = "C:\Drivers"
    If (Test-Path $Path){
        #Write-Log "Drivers folder found"
        Remove-Item -Path $Path -Force -Recurse -ErrorAction SilentlyContinue
    }
    Else {
        #Write-Log "Drivers folder not found"
    }
    $CurrentDiskSpace = FreeSpace
    Write-Log "- Free disk space after is: $CurrentDiskSpace GB"
}

If ($CleanCBSTempFolder){
    # Remove content from CBSTemp
    Write-Log "Removing content from the CBSTemp folder"
    $CurrentDiskSpace = FreeSpace
    Write-Log "- Free disk space before is: $CurrentDiskSpace GB"
    $Path = "C:\Windows\CbsTemp"
    If (Test-Path $Path){
        Remove-Item -Path $Path\* -Force -Recurse -ErrorAction SilentlyContinue
    }
    Else {
        Write-Log "CBSTemp folder not found"
    }
    $CurrentDiskSpace = FreeSpace
    Write-Log "- Free disk space after is: $CurrentDiskSpace GB"
}

If ($CleanConfigMgrCache){

    # Clear ConfigMgr Cache content older than 5 days
    # Including persisted cache items (DeleteCacheElementEx vs. DeleteCacheElement)
    Write-Log "Clearing ConfigMgr Cache"
    $CurrentDiskSpace = FreeSpace
    Write-Log "- Free disk space before is: $CurrentDiskSpace GB"
    try {

        $MinDays = 5
        $UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr -ErrorAction Stop
        $Cache = $UIResourceMgr.GetCacheInfo()

        $CacheElements = $Cache.GetCacheElements() | Where-Object {[datetime]$_.LastReferenceTime -lt (Get-Date).adddays(-$MinDays)}
        foreach ($Element in $CacheElements) { $Cache.DeleteCacheElementEx($Element.CacheElementID, $true) }
    
    }
    Catch{
        # No ConfigMgrClient
    }
    $CurrentDiskSpace = FreeSpace
    Write-Log "- Free disk space after is: $CurrentDiskSpace GB"
}

If ($CleanWindowsTempFolder){
    # Remove files from C:\Windows\Temp older than 7 days
    Write-Log "Removing files from C:\Windows\Temp older than 7 days"
    $CurrentDiskSpace = FreeSpace
    Write-Log "- Free disk space before is: $CurrentDiskSpace GB"
    $Path = "C:\Windows\Temp\*"
    $ContentToRemove = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-7)) } 
    $ContentToRemove | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    $CurrentDiskSpace = FreeSpace
    Write-Log "- Free disk space after is: $CurrentDiskSpace GB"
}

If ($CleanDOCache){

    # Clear Delivery Optimization Cache
    Write-Log "Clearing Delivery Optimization Cache"
    $CurrentDiskSpace = FreeSpace
    Write-Log "- Free disk space before is: $CurrentDiskSpace GB"
    if (Get-Command Delete-DeliveryOptimizationCache -ErrorAction SilentlyContinue) {
        #Delete-DeliveryOptimizationCache -IncludePinnedFiles -Force | Out-Null

        # Run Delete-DeliveryOptimizationCache inside a job, to prevent output (the cmdlet ignores stream preferences)
        $job = Start-Job -ScriptBlock {
            $ProgressPreference='SilentlyContinue'
            try { 
                Delete-DeliveryOptimizationCache  -IncludePinnedFiles -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue -Verbose:$false *> $null 
            } catch {
                # Do nothing
            }
        }
        Wait-Job $job | Out-Null
        Remove-Job $job -Force

    } else {
        Write-Log "Delete-DeliveryOptimizationCache cmdlet not available in this Windows version, skipping Delivery Optimization Cache cleanup"
    }
    $CurrentDiskSpace = FreeSpace
    Write-Log "- Free disk space after is: $CurrentDiskSpace GB"
}

If ($ClearBranchCacheCache){
    # Clear BranchCache Cache
    Write-Log "Clearing BranchCache Cache"
    $CurrentDiskSpace = FreeSpace
    Write-Log "- Free disk space before is: $CurrentDiskSpace GB"
    Try{
        Clear-BCCache -Force -ErrorAction Stop
    }
    Catch{
        # Do Nothing
    }
    $CurrentDiskSpace = FreeSpace
    Write-Log "- Free disk space after is: $CurrentDiskSpace GB"
}

If ($NativeDiskCleanup){
    # Run Disk Cleanup
    # when changing StateFlags number please check run command for cleanmgr
    Write-Log "Clearing Disk using Disk Cleanup (CleanMgr.exe)"
    Write-Log "Disk Cleanup is a built-in Windows utility that scans the system for unnesserary files"
    Write-Log "Files, such as temporary files, old Windows Updates, setup log files, memory dumps and more"
    $CurrentDiskSpace = FreeSpace
    Write-Log "- Free disk space before is: $CurrentDiskSpace GB"
    $SageSet = "StateFlags2024"
    $Base = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\"

    $Locations = @(
	    "Active Setup Temp Folders"
	    # "BranchCache"
	    "Content Index Cleaner"
	    "D3D Shader Cache"
	    "Delivery Optimization Files"
	    "Device Driver Packages"
	    "Diagnostic Data Viewer database files"
	    "Downloaded Program Files"
	    "Download Program Files"
	    #  "DownloadsFolder"
	    "GameNewsFiles"
	    "GameStatisticsFiles"
	    "GameUpdateFiles"
	    "Internet Cache Files"
	    "Language Pack"
	    "Memory Dump Files"
	    "Offline Pages Files"
	    "Old ChkDsk Files"
	    "Previous Installations"
	    # "Recycle Bin"
	    "RetailDemo Offline Content"
	    "Service Pack Cleanup"
	    "Setup Log Files"
	    "System error memory dump files"
	    "System error minidump files"
	    "Temporary Files"
	    "Temporary Setup Files"
	    #  "Temporary Sync Files"
	    "Thumbnail Cache"
	    "Update Cleanup"
	    "Upgrade Discarded Files"
	    "User file versions"
	    "Windows Defender"
	    "Windows Error Reporting Files"
	    #  "Windows Error Reporting Archive Files"
	    #  "Windows Error Reporting Queue Files"
	    #  "Windows Error Reporting System Archive Files"
	    #  "Windows Error Reporting System Queue Files"
	    "Windows ESD installation files"
	    "Windows Upgrade Log Files"
    )
    # value 2 means 'include' in cleanmgr run, 0 means 'do not run'
    ForEach ($Location in $Locations)
    {
	    Set-ItemProperty -Path $($Base + $Location) -Name $SageSet -Type DWORD -Value 2 -ErrorAction SilentlyContinue | Out-Null
    }
	
    # Request temporary files for RedirectStandardOutput and RedirectStandardError
    $RedirectStandardOutput = [System.IO.Path]::GetTempFileName()
    $RedirectStandardError = [System.IO.Path]::GetTempFileName()

    # Kill any running cleanmgr instances
    Get-Process -Name cleanmgr -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    # Run the cleanup with the SageSet number
    $SageRunNumber = [string]([int]$SageSet.Substring($SageSet.Length - 4))
    $cmdArgs = "/sagerun:$SageRunNumber"
    Write-Log "About to run CleanMgr"
    #Start-Process "$env:SystemRoot\System32\cleanmgr.exe" -ArgumentList $cmdArgs # -Wait
    $CleanMgr = Start-Process "$env:SystemRoot\System32\cleanmgr.exe" -ArgumentList $cmdArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput $RedirectStandardOutput -RedirectStandardError $RedirectStandardError

    Write-Log "CleanMgr Launched, now waiting for process to finish"
    $TimeoutSeconds = 1200
    $ElapsedSeconds = 0
    $LogIntervalSeconds = 60

    while ($ElapsedSeconds -lt $TimeoutSeconds) {
        $Processes = Get-Process -Name cleanmgr,dismhost -ErrorAction SilentlyContinue
        if ($Processes) {
            $ElapsedMinutes = [math]::Floor($ElapsedSeconds / 60)
            Write-Log "Waiting for cleanmgr/dismhost to finish... $ElapsedMinutes minutes elapsed"
            Start-Sleep -Seconds $LogIntervalSeconds
            $ElapsedSeconds += $LogIntervalSeconds
        } else {
            Write-Log "cleanmgr and dismhost processes have ended"
            break
        }
    }

    # CleanMgr error handling
    if ($CleanMgr.ExitCode -eq 0) {
	    Write-Log "CleanMgr has been successfully processed"
    } elseif ($CleanMgr.ExitCode -gt 0) {
	    return Write-Log "CleanMgr has been processed, exit code is $($CleanMgr.ExitCode)"
    } else {
	    #return Write-Log "An unknown error occurred."
    }

    # Remove the Stateflags
    ForEach ($Location in $Locations)
    {
	    Remove-ItemProperty -Path $($Base + $Location) -Name $SageSet -Force -ErrorAction SilentlyContinue | Out-Null
    }
    $CurrentDiskSpace = FreeSpace
    Write-Log "- Free disk space after is: $CurrentDiskSpace GB"
}

# Get Free Diskspace after native disk cleanup
$FreeSpaceAfterCleanup = FreeSpace
$DiskSpaceSavings = -([math]::Round($FreeSpaceBeforeCleanup - $FreeSpaceAfterCleanup,2))
Write-Log "Native disk Cleanup Completed. The script cleaned $DiskSpaceSavings GB from $($Env:ComputerName)"
$EndTime = Get-Date
$TimeSpan = New-TimeSpan -Start $StartTime -End $EndTime
$DurationMinutes = $TimeSpan.Minutes
$DurationSeconds = $TimeSpan.Seconds
Write-Log "Script runtime was $DurationMinutes minutes and $DurationSeconds seconds"

Write-OutPut "Cleanup complete - $DiskSpaceSavings GB freed"