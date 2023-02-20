$Clients = @(
    "CHI-W10PEER-001" # Hyper-V VM
    "DELL-3120-001"
    "DELL-3300-001"
    "DELL-3310-001"
    "DELL-5320-001"
    "DELL-7040-001"
    "DELL-7050-001"
)

$ScriptPath = "E:\HealthCheck\Scripts"
$ClearCacheScript = "ClearConfigMgrAndBranchCacheCaches.ps1"
$PackageInstallScript = "Install-LegacyPackages.ps1"
$CancelDownloadScript = "Cancel-Downloads.ps1"
$StifleRClientUsageScript = "Invoke-StifleRClientCPUUsage.ps1"
$AutologonEXE = "E:\Setup\Sysinternals\SysinternalsSuite\Autologon.exe"

$NumberOfClients = ($Clients | Measure-Object).Count
Write-Host "Total Number of active clients is: $NumberOfClients"

# Copy the scripts to all clients
Foreach ($Client in $Clients){
    $ComputerName = $Client
    Write-Host "Working on $ComputerName, copying the various scripts"
    Copy-Item -Path "$ScriptPath\$PackageInstallScript" -Destination "\\$ComputerName\C`$\Windows\Temp" -Force 
    Copy-Item -Path "$ScriptPath\$CancelDownloadScript" -Destination "\\$ComputerName\C`$\Windows\Temp" -Force 
    Copy-Item -Path "$ScriptPath\$StifleRClientUsageScript" -Destination "\\$ComputerName\C`$\Windows\Temp" -Force 
    Copy-Item -Path "$ScriptPath\$ClearCacheScript" -Destination "\\$ComputerName\C`$\Windows\Temp" -Force 
}

# Copy Autologon to all clients
Foreach ($Client in $Clients){
    $ComputerName = $Client
    Write-Host "Working on $ComputerName, copying Autologon.exe"
    Copy-Item -Path $AutologonEXE -Destination "\\$ComputerName\C`$\Windows\System32" -Force 
}    


$PackageInstallScriptBlock = [scriptblock]::Create("C:\Windows\Temp\$PackageInstallScript")
$CancelDownloadScriptBlock = [scriptblock]::Create("C:\Windows\Temp\$CancelDownloadScript")
$StifleRClientUsageScriptBlock = [scriptblock]::Create("C:\Windows\Temp\$StifleRClientUsageScript")
$ClearCacheScriptBlock = [scriptblock]::Create("C:\Windows\Temp\$ClearCacheScript")

# ---------------------------------------
# Reset Test Environment
# ---------------------------------------

# Cancel any downloads
Foreach ($Client in $Clients){
    $ComputerName = $Client
    Write-Host "Working on $ComputerName"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $CancelDownloadScriptBlock -AsJob | Out-Null
}

# Clear any results
Foreach ($Client in $Clients){
    $ComputerName = $Client
    If (Test-Path "\\$ComputerName\C`$\Windows\Temp\StiflerClientUsage.txt"){
        Remove-Item -Path "\\$ComputerName\C`$\Windows\Temp\StiflerClientUsage.txt" -Force
    }
}

# Run the Clear caches script on each client 
$ClearCacheScriptBlock = [scriptblock]::Create("C:\Windows\Temp\$ClearCacheScript")
Foreach ($Client in $Clients){
    $ComputerName = $Client
    Write-Host "Working on $ComputerName"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $ClearCacheScriptBlock -AsJob | Out-Null
}

Start-Sleep -Seconds 60

# Verify that the caches are empty
Foreach ($Client in $Clients){
    $ComputerName = $Client
    Write-Host "Working on $ComputerName"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock { 
        $UIResourceMgr = new-object -com "UIResource.UIResourceMgr"
        $CMCacheInfo = $UIResourceMgr.GetCacheInfo()
        $CMCacheFreeInGB = [math]::Round(($CMCacheInfo.FreeSize)/1024,2) # Original value in MB
        $CMCacheTotalInGB = [math]::Round(($CMCacheInfo.TotalSize)/1024,2) # Original value in MB
        $CMCacheUsedInGB = [math]::Round($CMCacheTotalInGB - $CMCacheFreeInGB,2)
        Write-host "ConfigMgr Client used cache size is: $([math]::Round($CMCacheTotalInGB - $CMCacheFreeInGB,2))"
    }
    Invoke-Command -ComputerName $ComputerName -ScriptBlock { 
        Write-host "BranchCache active cache size is: $([math]::Round(((Get-BCDataCache).CurrentActiveCacheSize/1GB),2))"
    }
    Write-Host ""
}


# Check status of jobs
Get-Job

# -----------------------------------------------------------
# Start Mass Deployment 
# -----------------------------------------------------------

# Run the scripts on each client, one client at the time 
Foreach ($Client in $Clients){
    $ComputerName = $Client
    Write-Host "Working on $ComputerName, Running the $PackageInstallScript script"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $PackageInstallScriptBlock -AsJob | Out-Null
    Write-Host "Waiting 2 minutes... making sure the download is running"
    Start-Sleep -seconds 120
    
    Write-Host "Running the $StifleRClientUsageScript script"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $StifleRClientUsageScriptBlock -AsJob | Out-Null
    Write-Host "Waiting 12 minutes... Giving the 10 minute usage script extra time to complete "
    Start-Sleep -Seconds 720

    $Result = Get-Content -Path "\\$ComputerName\C`$\Windows\Temp\StiflerClientUsage.txt"
    Write-Host "StifleR Client CPU Usage on $ComputerName is $Result%" 
    #Read-host -Prompt "Verify usage output, then press <Enter> to continue to next computer"
    
    Write-Host "Cancelling the download"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $CancelDownloadScriptBlock -AsJob | Out-Null
    Start-Sleep -Seconds 30

    #Read-host -Prompt "Verify downloaded cancelled, then press <Enter> to continue to next computer"
    
    #Write-Host "Clearing cache and move on to next computer"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $ClearCacheScriptBlock -AsJob | Out-Null


}

Start-Sleep -Seconds 300

# Collect the results
Foreach ($Client in $Clients){
    $ComputerName = $Client
    If (Test-Path "\\$ComputerName\C`$\Windows\Temp\StiflerClientUsage.txt"){
        $Result = Get-Content -Path "\\$ComputerName\C`$\Windows\Temp\StiflerClientUsage.txt"
        Write-Host "StifleR Client CPU Usage on $ComputerName is $Result%" 
    }
}


