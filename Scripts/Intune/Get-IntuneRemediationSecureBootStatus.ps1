# Query Intune remediation results for Secure Boot status.
# Reference:
# https://support.microsoft.com/en-us/topic/monitoring-secure-boot-certificate-status-with-microsoft-intune-remediations-6696a27b-fa09-4570-b112-124965adc87f

#Set the name of the remediation you want to query. This should be the display name of the remediation in Intune. You can use wildcards (*) to match multiple remediations, but if multiple remediations match, only the first one will be used.
$RemediationName = "Secure Boot Inventory Data Collection script"

Connect-MgGraph -NoWelcome -Scopes "DeviceManagementManagedDevices.Read.All", "DeviceManagementConfiguration.Read.All", "DeviceManagementScripts.Read.All"

$scriptsResponse = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
$scriptMatches = @($scriptsResponse.value | Where-Object { $_.displayName -like "*$RemediationName*" })

if (-not $scriptMatches) {
    Write-Host "Remediation not found: $RemediationName" -ForegroundColor Red
    return
}

if (@($scriptMatches).Count -gt 1) {
    Write-Host "Multiple remediations matched. Using the first one:" -ForegroundColor Yellow
    $scriptMatches | Select-Object id, displayName | Format-Table -AutoSize
}

$script = $scriptMatches | Select-Object -First 1
$resultsResponse = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$($script.id)/deviceRunStates"
$results = @($resultsResponse.value)

$output = foreach ($result in $results) {
    try {
        $parsed = if ($result.preRemediationDetectionScriptOutput) {
            $result.preRemediationDetectionScriptOutput | ConvertFrom-Json
        }
        else {
            [PSCustomObject]@{}
        }
    }
    catch {
        $parsed = [PSCustomObject]@{}
    }

    $obj = [ordered]@{
        DeviceName              = $parsed.Hostname
        RemediationState        = $result.remediationState
        DetectionState          = $result.detectionState
        LastSyncDateTime        = $result.lastSyncDateTime
        LastStateUpdateDateTime = $result.lastStateUpdateDateTime
    }

    foreach ($prop in $parsed.PSObject.Properties) {
        $obj[$prop.Name] = $prop.Value
    }

    [PSCustomObject]$obj
}

$output