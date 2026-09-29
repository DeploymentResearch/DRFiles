# Clients to target
$RemoteComputers = @(
	"2PS-ROGUE-002"
    "2PS-ROGUE-003"
    "2PS-ROGUE-030"
    "2PS-ROGUE-031"
    "2PS-ROGUE-032"
)

# Scriptblock for clearing the ConfigMgr Cache   
$ClearCMCacheScriptBlock = {
    $UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
    $Cache = $UIResourceMgr.GetCacheInfo()
    $CacheElements = $Cache.GetCacheElements() 
    foreach ($Element in $CacheElements) { 	$Cache.DeleteCacheElementEx($Element.CacheElementID, $true) }
}

# Scriptblock for clearing the BranchCache Cache and the BranchCache Performance Counters 
$ClearBranchCacheCacheScriptBlock = {
    Clear-BCCache -Force
    Reset-BC -ResetPerfCountersOnly -Force
}

# Scriptblock for clearing the BITS Event Log
$ClearBITSEventLogScriptBlock = {
    $LogName = 'Microsoft-Windows-Bits-Client/operational'
    Get-WinEvent -ListLog $LogName | Where-Object { Wevtutil.exe cl $_.LogName }
}

# Scriptblock for Packages to Deploy
$PackagesScriptBlock = {
    # ConfigMgr Packages/Programs to run (ProgramID = Program Name)
    $Batch = @()
    $Batch += [pscustomobject]@{ PackageID = "PS100126"; ProgramID = "P2P Test Package - 100 MB Single File" }
    $Batch += [pscustomobject]@{ PackageID = "PS10012A"; ProgramID = "P2P Test Package - 200 MB Single File" }
    $Batch += [pscustomobject]@{ PackageID = "PS10012D"; ProgramID = "P2P Test Package - 300 MB Single File" }
    $Batch += [pscustomobject]@{ PackageID = "PS100123"; ProgramID = "P2P Test Package - 1 GB Single File" }

    # Run the programs
    [cimclass]$CimClass = (Get-CimClass -Namespace 'Root\ccm\clientsdk' -ClassName 'CCM_ProgramsManager' -ErrorAction 'Stop')
    foreach($Item in $Batch){

        [hashtable]$Arguments = @{
            'PackageID' = $Item.PackageID
            'ProgramID' = $Item.ProgramID
        }

        Try {
            Invoke-CimMethod -CimClass $CimClass -MethodName 'ExecuteProgram' –Arguments $Arguments -ErrorAction 'Stop'
        }
        Catch {
            $ErrorMessage = "Could not run Program $($Item.ProgramID). `n $_.ErrorMessage"
        }
    }
}

# Clear Cache Content on remote computers
foreach ($RemoteComputer in $RemoteComputers) {

    Write-Host "Working on device: $RemoteComputer"
    # Clear ConfigMgr Cache on remote machine
    Invoke-Command -ScriptBlock $ClearCMCacheScriptBlock -ComputerName $RemoteComputer

    # Clear the BranchCache Cache and the BranchCache Performance Counters 
    Invoke-Command -ScriptBlock $ClearBranchCacheCacheScriptBlock -ComputerName $RemoteComputer

    # Clear the BITS Event Log on remote machine
    Invoke-Command -ScriptBlock $ClearBITSEventLogScriptBlock -ComputerName $RemoteComputer
}

# Start mass deployment
# Note: A user must be logged on for the script to work.
foreach ($RemoteComputer in $RemoteComputers) {

    Write-Host "Working on device: $RemoteComputer"
    Invoke-Command -ScriptBlock $PackagesScriptBlock -ComputerName $RemoteComputer -AsJob

}

