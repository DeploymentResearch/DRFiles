<#
.SYNOPSIS
    Enable or disable verbose logging for common ConfigMgr components.

.DESCRIPTION
    Designed to be run one line or one section at a time (F8 in ISE or VS Code),
    not as a whole script. Run section 0 first to load the helper functions.

    Run elevated, locally on the server that hosts the component:
      Sections 1 to 3: site server
      Section 4:       SMS Provider server
      Section 5:       management point (or any client)
      Section 6:       distribution point

    Registry values for sections 1 to 3, 5 and 6 follow the Microsoft article "About log files":
    https://learn.microsoft.com/en-us/intune/configmgr/core/plan-design/hierarchy/about-log-files
    Section 4 (SMS Provider) is field knowledge, not in that article. Verify in a lab.
#>

#region 0. Helper functions (run this section first)

$TracingRoot = 'HKLM:\SOFTWARE\Microsoft\SMS\Tracing'

function Enable-CMComponentVerbose {
    param(
        [Parameter(Mandatory)][string]$Component,
        [int]$MaxFileSizeMB = 20,
        [int]$LogMaxHistory = 5
    )
    $Key = Join-Path $TracingRoot $Component
    if (-not (Test-Path $Key)) { Write-Warning "Key not found: $Key"; return }
    Set-ItemProperty -Path $Key -Name LoggingLevel  -Value 0 -Type DWord
    Set-ItemProperty -Path $Key -Name DebugLogging  -Value 1 -Type DWord
    Set-ItemProperty -Path $Key -Name MaxFileSize   -Value ($MaxFileSizeMB * 1MB) -Type DWord
    Set-ItemProperty -Path $Key -Name LogMaxHistory -Value $LogMaxHistory -Type DWord
    Write-Host "Verbose logging enabled for $Component"
}

function Disable-CMComponentVerbose {
    param(
        [Parameter(Mandatory)][string]$Component,
        [int]$LogMaxHistory = 1
    )
    $Key = Join-Path $TracingRoot $Component
    if (-not (Test-Path $Key)) { Write-Warning "Key not found: $Key"; return }
    Set-ItemProperty -Path $Key -Name LoggingLevel  -Value 1 -Type DWord
    Set-ItemProperty -Path $Key -Name DebugLogging  -Value 0 -Type DWord
    Set-ItemProperty -Path $Key -Name MaxFileSize   -Value 2621440 -Type DWord
    Set-ItemProperty -Path $Key -Name LogMaxHistory -Value $LogMaxHistory -Type DWord
    Write-Host "Logging reset to default for $Component"
}

function Get-CMComponentLogging {
    param([Parameter(Mandatory)][string]$Component)
    Get-ItemProperty -Path (Join-Path $TracingRoot $Component) |
        Select-Object @{n='Component';e={$Component}}, LoggingLevel, DebugLogging, MaxFileSize, LogMaxHistory, TraceFilename
}

#endregion

#region 1. Site server components (run the lines you need)

# Content distribution (distmgr.log)
Enable-CMComponentVerbose  -Component SMS_DISTRIBUTION_MANAGER
Disable-CMComponentVerbose -Component SMS_DISTRIBUTION_MANAGER

# Content transfer to DPs (PkgXferMgr.log)
Enable-CMComponentVerbose  -Component SMS_PACKAGE_TRANSFER_MANAGER
Disable-CMComponentVerbose -Component SMS_PACKAGE_TRANSFER_MANAGER

# Software update sync (wsyncmgr.log)
Enable-CMComponentVerbose  -Component SMS_WSUS_SYNC_MANAGER
Disable-CMComponentVerbose -Component SMS_WSUS_SYNC_MANAGER

# WSUS configuration (WCM.log)
Enable-CMComponentVerbose  -Component SMS_WSUS_CONFIGURATION_MANAGER
Disable-CMComponentVerbose -Component SMS_WSUS_CONFIGURATION_MANAGER

# Collection evaluation (colleval.log)
Enable-CMComponentVerbose  -Component SMS_COLLECTION_EVALUATOR
Disable-CMComponentVerbose -Component SMS_COLLECTION_EVALUATOR

# Policy creation (policypv.log)
Enable-CMComponentVerbose  -Component SMS_POLICY_PROVIDER
Disable-CMComponentVerbose -Component SMS_POLICY_PROVIDER

# State messages (statesys.log)
Enable-CMComponentVerbose  -Component SMS_STATE_SYSTEM
Disable-CMComponentVerbose -Component SMS_STATE_SYSTEM

# Discovery data processing (ddm.log)
Enable-CMComponentVerbose  -Component SMS_DISCOVERY_DATA_MANAGER
Disable-CMComponentVerbose -Component SMS_DISCOVERY_DATA_MANAGER

# Site configuration and hierarchy (hman.log)
Enable-CMComponentVerbose  -Component SMS_HIERARCHY_MANAGER
Disable-CMComponentVerbose -Component SMS_HIERARCHY_MANAGER

# Check current settings for a component
Get-CMComponentLogging -Component SMS_DISTRIBUTION_MANAGER

# List all component names available on this server
Get-ChildItem $TracingRoot | Select-Object -ExpandProperty PSChildName | Sort-Object

#endregion

#region 2. SQL tracing for all site server logs (very noisy, disable after the repro)

# Enable
Set-ItemProperty -Path $TracingRoot -Name SqlEnabled -Value 1 -Type DWord

# Disable
Set-ItemProperty -Path $TracingRoot -Name SqlEnabled -Value 0 -Type DWord

#endregion

#region 3. Apply the changes on the site server

# Restarts all site server component threads. Expect a short interruption in site processing.
Restart-Service -Name SMS_EXECUTIVE -Force

#endregion

#region 4. SMS Provider (SMSProv.log), run on the SMS Provider server

$ProvKey = 'HKLM:\SOFTWARE\Microsoft\SMS\Providers'

# Enable (0 = verbose) and raise the log size to 20 MB
Set-ItemProperty -Path $ProvKey -Name 'Logging Level'    -Value 0 -Type DWord
Set-ItemProperty -Path $ProvKey -Name 'SMSProv Log Size' -Value 20 -Type DWord

# Disable (back to default)
Set-ItemProperty -Path $ProvKey -Name 'Logging Level'    -Value 1 -Type DWord

# Apply (restarts WMI and its dependent services)
Restart-Service -Name Winmgmt -Force

#endregion

#region 5. Management point or client (CCM logs), run on the MP or client

# Note: Administrators may need write permission on the @Global key first.
$CcmGlobal = 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global'
$CcmDebug  = 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\DebugLogging'

# Enable
Set-ItemProperty -Path $CcmGlobal -Name LogLevel      -Value 0 -Type DWord
Set-ItemProperty -Path $CcmGlobal -Name LogMaxSize    -Value 5242880 -Type DWord
Set-ItemProperty -Path $CcmGlobal -Name LogMaxHistory -Value 5 -Type DWord
if (-not (Test-Path $CcmDebug)) { New-Item -Path $CcmDebug -Force | Out-Null }
Set-ItemProperty -Path $CcmDebug -Name Enabled -Value 'True' -Type String

# Disable (back to defaults)
Set-ItemProperty -Path $CcmGlobal -Name LogLevel      -Value 1 -Type DWord
Set-ItemProperty -Path $CcmGlobal -Name LogMaxSize    -Value 250000 -Type DWord
Set-ItemProperty -Path $CcmGlobal -Name LogMaxHistory -Value 1 -Type DWord
Set-ItemProperty -Path $CcmDebug  -Name Enabled -Value 'False' -Type String

# Apply
Restart-Service -Name CcmExec -Force

#endregion

#region 6. Distribution point role, run on the DP

$DpLogging = 'HKLM:\SOFTWARE\Microsoft\SMS\DP\Logging'
if (-not (Test-Path $DpLogging)) { New-Item -Path $DpLogging -Force | Out-Null }

# Enable
Set-ItemProperty -Path $DpLogging -Name LogLevel      -Value 0 -Type DWord
Set-ItemProperty -Path $DpLogging -Name LogMaxSize    -Value 5242880 -Type DWord
Set-ItemProperty -Path $DpLogging -Name LogMaxHistory -Value 5 -Type DWord

# Disable (back to defaults)
Set-ItemProperty -Path $DpLogging -Name LogLevel      -Value 1 -Type DWord
Set-ItemProperty -Path $DpLogging -Name LogMaxSize    -Value 250000 -Type DWord
Set-ItemProperty -Path $DpLogging -Name LogMaxHistory -Value 1 -Type DWord

#endregion
