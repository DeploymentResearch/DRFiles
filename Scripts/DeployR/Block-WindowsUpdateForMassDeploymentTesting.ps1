# Block-WindowsUpdate.ps1
# In WinPE: writes update policies into the offline OS registry and disables the update services (run after Apply OS).
# In the full OS: writes the same settings live, stops and disables the update services and scheduled tasks,
# and adds an outbound firewall block for public addresses.
# Based on the same technique as the PreventingUpdatesDuringOSD scripts in DRFiles, without the ConfigMgr dependencies.

# Settings
$OfflineOSDrive       = "S:"                        # Drive letter of the applied OS while in WinPE
$DummyWsusServer      = "http://127.0.0.1:8530"     # Nothing listens here, so scans fail immediately
$DisableWUService     = $true                       # Disable wuauserv and the UpdateOrchestrator tasks (breaks FoD, MSU and Store installs)
$BlockEdgeUpdate      = $true                       # Edge update policies, services and scheduled tasks
$QuietEdgeAndDefender = $true                       # Edge browser background activity and Defender cloud lookups
$AddFirewallRule      = $true                       # Full OS only
$FirewallRuleName     = "Benchmark - Block Internet"

$InWinPE = Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\MiniNT"
$Root = "HKLM:\SOFTWARE"
$ServicesRoot = "HKLM:\SYSTEM\CurrentControlSet\Services"
if ($InWinPE) {
    reg.exe load "HKLM\OfflineSW" "$OfflineOSDrive\Windows\System32\config\SOFTWARE" | Out-Null
    reg.exe load "HKLM\OfflineSYS" "$OfflineOSDrive\Windows\System32\config\SYSTEM" | Out-Null
    $Root = "HKLM:\OfflineSW"
    $ControlSet = "ControlSet{0:d3}" -f (Get-ItemProperty "HKLM:\OfflineSYS\Select").Current
    $ServicesRoot = "HKLM:\OfflineSYS\$ControlSet\Services"
}

$Settings = @(
    # Point Windows Update at a server that does not exist, and forbid the internet locations
    @{ Key = "Policies\Microsoft\Windows\WindowsUpdate";    Name = "WUServer";                                    Value = $DummyWsusServer; Type = "String" }
    @{ Key = "Policies\Microsoft\Windows\WindowsUpdate";    Name = "WUStatusServer";                              Value = $DummyWsusServer; Type = "String" }
    @{ Key = "Policies\Microsoft\Windows\WindowsUpdate";    Name = "DoNotConnectToWindowsUpdateInternetLocations"; Value = 1; Type = "DWord" }
    @{ Key = "Policies\Microsoft\Windows\WindowsUpdate";    Name = "DisableWindowsUpdateAccess";                  Value = 1; Type = "DWord" }
    @{ Key = "Policies\Microsoft\Windows\WindowsUpdate";    Name = "DisableDualScan";                             Value = 1; Type = "DWord" }
    @{ Key = "Policies\Microsoft\Windows\WindowsUpdate";    Name = "ExcludeWUDriversInQualityUpdate";             Value = 1; Type = "DWord" }
    @{ Key = "Policies\Microsoft\Windows\WindowsUpdate\AU"; Name = "UseWUServer";                                 Value = 1; Type = "DWord" }
    @{ Key = "Policies\Microsoft\Windows\WindowsUpdate\AU"; Name = "NoAutoUpdate";                                Value = 1; Type = "DWord" }
    # No driver or device metadata searches against Windows Update
    @{ Key = "Policies\Microsoft\Windows\DriverSearching";  Name = "DontSearchWindowsUpdate";                     Value = 1; Type = "DWord" }
    @{ Key = "Policies\Microsoft\Windows\DriverSearching";  Name = "SearchOrderConfig";                           Value = 0; Type = "DWord" }
    @{ Key = "Policies\Microsoft\Windows\Device Metadata";  Name = "PreventDeviceMetadataFromNetwork";            Value = 1; Type = "DWord" }
    # No Delivery Optimization cloud traffic, no Store app auto-updates, no consumer app installs
    @{ Key = "Policies\Microsoft\Windows\DeliveryOptimization"; Name = "DODownloadMode";                          Value = 99; Type = "DWord" }
    @{ Key = "Policies\Microsoft\WindowsStore";             Name = "AutoDownload";                                Value = 2; Type = "DWord" }
    @{ Key = "Policies\Microsoft\Windows\CloudContent";     Name = "DisableWindowsConsumerFeatures";              Value = 1; Type = "DWord" }
)

if ($BlockEdgeUpdate) {
    $Settings += @(
        # Edge has its own updater that ignores the Windows Update policies above
        @{ Key = "Policies\Microsoft\EdgeUpdate"; Name = "UpdateDefault";                Value = 0; Type = "DWord" }
        @{ Key = "Policies\Microsoft\EdgeUpdate"; Name = "AutoUpdateCheckPeriodMinutes"; Value = 0; Type = "DWord" }
    )
}

if ($QuietEdgeAndDefender) {
    $Settings += @(
        # Defender: no cloud lookups or sample submission
        @{ Key = "Policies\Microsoft\Windows Defender\Spynet"; Name = "SpynetReporting";      Value = 0; Type = "DWord" }
        @{ Key = "Policies\Microsoft\Windows Defender\Spynet"; Name = "SubmitSamplesConsent"; Value = 2; Type = "DWord" }
        # Edge browser: no preloading, background mode, component updates or first-run experience
        @{ Key = "Policies\Microsoft\Edge"; Name = "StartupBoostEnabled";     Value = 0; Type = "DWord" }
        @{ Key = "Policies\Microsoft\Edge"; Name = "BackgroundModeEnabled";   Value = 0; Type = "DWord" }
        @{ Key = "Policies\Microsoft\Edge"; Name = "ComponentUpdatesEnabled"; Value = 0; Type = "DWord" }
        @{ Key = "Policies\Microsoft\Edge"; Name = "HideFirstRunExperience";  Value = 1; Type = "DWord" }
    )
}

foreach ($Setting in $Settings) {
    $Path = Join-Path $Root $Setting.Key
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Setting.Name -Value $Setting.Value -PropertyType $Setting.Type -Force | Out-Null
}

# Services to disable. Start = 4 in the registry works both offline and live.
$Services = @()
if ($DisableWUService) { $Services += "wuauserv" }
if ($BlockEdgeUpdate)  { $Services += "edgeupdate", "edgeupdatem" }

foreach ($Service in $Services) {
    $ServiceKey = Join-Path $ServicesRoot $Service
    if (Test-Path $ServiceKey) {
        Set-ItemProperty -Path $ServiceKey -Name "Start" -Value 4 -Type DWord
        Write-Output "Disabled service: $Service"
    }
    else {
        Write-Output "Service not found: $Service"
    }
}

if ($InWinPE) {
    [gc]::Collect()
    Start-Sleep -Seconds 2
    reg.exe unload "HKLM\OfflineSW" | Out-Null
    reg.exe unload "HKLM\OfflineSYS" | Out-Null
}
else {
    # Stop anything that is already running
    foreach ($Service in $Services) {
        & sc.exe stop $Service | Out-Null
    }
    if ($BlockEdgeUpdate) {
        Get-Process -Name "MicrosoftEdgeUpdate" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName "MicrosoftEdgeUpdateTask*" -ErrorAction SilentlyContinue | Disable-ScheduledTask | Out-Null
    }

    if ($DisableWUService) {
        $TaskPath = "\Microsoft\Windows\UpdateOrchestrator\"
        foreach ($TaskName in "Schedule Scan", "Schedule Maintenance Work", "Backup Scan", "Reboot", "USO_UxBroker") {
            $Task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
            if ($Task) {
                try {
                    $Task | Disable-ScheduledTask -ErrorAction Stop | Out-Null
                    Write-Output "Task disabled: $TaskPath$TaskName"
                }
                catch {
                    Write-Output "Task could not be disabled: $TaskPath$TaskName ($($_.Exception.Message))"
                }
            }
        }
    }

    if ($AddFirewallRule) {
        if (-not (Get-NetFirewallRule -DisplayName $FirewallRuleName -ErrorAction SilentlyContinue)) {
            # Every IPv4 range that is not private (10/8, 172.16/12, 192.168/16), loopback or link-local
            $PublicRanges = @(
                "1.0.0.0-9.255.255.255", "11.0.0.0-126.255.255.255", "128.0.0.0-169.253.255.255",
                "169.255.0.0-172.15.255.255", "172.32.0.0-192.167.255.255", "192.169.0.0-223.255.255.255"
            )
            New-NetFirewallRule -DisplayName $FirewallRuleName -Direction Outbound -Action Block -RemoteAddress $PublicRanges -Profile Any | Out-Null
            New-NetFirewallRule -DisplayName "$FirewallRuleName (IPv6)" -Direction Outbound -Action Block -RemoteAddress "2000::/3" -Profile Any | Out-Null
        }

        # Report the result, so the task sequence log shows whether the block is actually in effect
        $Rules = @(Get-NetFirewallRule -DisplayName "$FirewallRuleName*" -ErrorAction SilentlyContinue)
        Write-Output "Firewall rules present: $($Rules.Count) (expected 2)"
        foreach ($FwProfile in Get-NetFirewallProfile -PolicyStore ActiveStore) {
            Write-Output "Firewall profile $($FwProfile.Name) enabled: $($FwProfile.Enabled)"
        }
    }
}

exit 0
