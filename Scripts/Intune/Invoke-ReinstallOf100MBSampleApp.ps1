# Sample to delete a single app
# Note: Don't got forget to delete any files/installs that the detection method uses on your machine
# Deleting specific application based on its object id
$Path = "HKLM:SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps"
$UserObjectID1 = "userobject-guid" 
$AppID = "956e00ed-3da5-4e87-aaa7-ec7a0f06ef41" # P2P Test Application - 100 MB Single File 
$AppDetectionFile = "C:\Windows\Temp\100 MB Single File.txt"

# Clear the DO Cache
#Delete-DeliveryOptimizationCache -Force

# _getAppGRSHash function from Andrew (@AndrewZtrhgf): https://gist.github.com/ztrhgf/18f1c32220764f79af3da52d9f47d266
function _getAppGRSHash {
    param (
        [Parameter(Mandatory = $true)]
        [string] $appId
    )

    $intuneLogList = Get-ChildItem -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs" -Filter "IntuneManagementExtension*.log" -File | sort LastWriteTime -Descending | select -ExpandProperty FullName

    if (!$intuneLogList) {
        #Write-Error "Unable to find any Intune log files. Redeploy will probably not work as expected."
        return
    }

    foreach ($intuneLog in $intuneLogList) {
        $appMatch = Select-String -Path $intuneLog -Pattern "\[Win32App\] ExecManager: processing targeted app .+ id='$appId'" -Context 0, 2
        if ($appMatch) {
            foreach ($match in $appMatch) {
                $hash = ([regex]"\d+:Hash = ([^]]+)\]").Matches($match).captures.groups[1].value
                if ($hash) {
                    return $hash
                }
            }
        }
    }

    #Write-Error "Unable to find App '$appId' GRS hash in any of the Intune log files. Redeploy will probably not work as expected"
}

# Force a sync against Intune (
Get-ScheduledTask | ? {$_.TaskName -eq 'PushLaunch'} | Start-ScheduledTask
# The PushLaunch task is in  \Microsoft\Windows\EnterpriseMgmt\C48A02CD-0F20-4BDA-B881-B686E509E8CC\
# The "Schedule to run OMADMClient by client" might be interesting as well
# Event log Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin, 
# look for Event ID 206 and the message: MDM Session: OMA-DM session started for user: 
# look for Event ID 209 and the message: MDM Session: OMA-DM session ended with status: (The operation completed successfully.).

# Get GRS key
$GRSHash = _getAppGRSHash -appId $AppID

# Remove application detection file
If (Test-path $AppDetectionFile){Remove-Item -Path $AppDetectionFile -Force}

# Remove the various registry keys
If (test-path $Path\00000000-0000-0000-0000-000000000000){
    (Get-ChildItem -Path $Path\00000000-0000-0000-0000-000000000000) -match $AppID | Remove-Item -Recurse -Force
}

If (test-path $Path\$UserObjectID1){
    (Get-ChildItem -Path $Path\$UserObjectID1) -match $AppID | Remove-Item -Recurse -Force
}

If (test-path $Path\00000000-0000-0000-0000-000000000000\GRS){
    (Get-ChildItem -Path $Path\00000000-0000-0000-0000-000000000000\GRS) -match $GRSHash | Remove-Item -Recurse -Force
}

If (test-path $Path\$UserObjectID1\GRS){
    (Get-ChildItem -Path $Path\$UserObjectID1\GRS) -match $GRSHash | Remove-Item -Recurse -Force
}

# Restart the IME Service
Get-Service -DisplayName "Microsoft Intune Management Extension" | Restart-Service 