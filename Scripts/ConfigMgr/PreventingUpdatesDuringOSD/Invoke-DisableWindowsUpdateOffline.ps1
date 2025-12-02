<#
.SYNOPSIS
    Script that disables Windows Updates during the WinPE (offline) phase of ConfigMgr OSD
    
.DESCRIPTION
    Script that disables Windows Updates during the WinPE (offline) phase of ConfigMgr OSD

.NOTES
    Author: Johan Arwidmark / deploymentresearch.com
    Twitter (X): @jarwidmark
    LinkedIn: https://www.linkedin.com/in/jarwidmark
    License: MIT
    Source:  https://github.com/DeploymentResearch/DRFiles

.DISCLAIMER
    This script is provided "as is" without warranty of any kind, express or implied.
    Use at your own risk — the author and DeploymentResearch assume no responsibility for any
    issues, damages, or data loss resulting from its use or modification.

    This script is shared in the spirit of community learning and improvement.
    You are welcome to adapt and redistribute it under the terms of the MIT License.

.VERSION
    1.0.0
    Released: 2025-11-25
    Change history:
      1.0.0 - 2025-11-25 - Initial release
#>

# Set WSUS Server for SUP, protocol (http/https) and port (8530/8531)
$WSUSServer = "http://cm01.corp.viamonstra.com:8530"

# Figure out if we can use the task sequence object
try {
		$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
}
catch [System.Exception] {
	Write-Warning -Message "Unable to create Microsoft.SMS.TSEnvironment object, aborting..."
    Break
}

$LogPath = $TSEnv.Value("_SMSTSLogPath") 
$Logfile = "$LogPath\DisableWindowsUpdatesOffline.log"

# Delete any existing logfile if it exists
If (Test-Path $Logfile){Remove-Item $Logfile -Force -ErrorAction SilentlyContinue -Confirm:$false}

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

function Set-RegistryValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('String','ExpandString','DWord','QWord','Binary','MultiString')]
        [string]$Type,

        [Parameter(Mandatory = $true)]
        $Value,

        [string]$Description = ""
    )

    try {
        if ($Description) {
            Write-Log -Message $Description
        }

        # Ensure key exists, but DO NOT recreate it if it already does
        if (-not (Test-Path -Path $Path)) {
            Write-Log -Message "Registry key does not exist. Creating: $Path"
            $null = New-Item -Path $Path -Force -ErrorAction Stop
        }
        else {
            Write-Log -Message "Registry key already exists: $Path"
        }

        # Get current value if it exists
        $currentValue = $null
        $hadCurrent = $false
        try {
            $props = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
            $currentValue = $props.$Name
            $hadCurrent = $true
        }
        catch {
            # Value does not exist yet
        }

        if ($hadCurrent) {
            Write-Log -Message "Current value detected: $Name = '$currentValue'"
        }
        else {
            Write-Log -Message "Registry value '$Name' does not currently exist"
        }

        # Set / update value (this does NOT touch other values)
        Write-Log -Message "Setting registry value '$Name' of type '$Type' to '$Value'"
        if ($hadCurrent) {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction Stop | Out-Null
        }
        else {
            New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force -ErrorAction Stop | Out-Null
        }
    }
    catch {
        Write-Log -Message "Failed to set registry value '$Path\$Name'. Error: $($_.Exception.Message)"
        throw
    }
}


# Load the SOFTWARE offline registry hive from the OS volume
$OSDTargetSystemDrive = $TSEnv.Value("OSDTargetSystemDrive")
$HivePath = "$OSDTargetSystemDrive\Windows\System32\config\SOFTWARE"
Write-Log -Message "About to load registry hive: $HivePath"
reg load "HKLM\NewOS" $HivePath 
Start-Sleep -Seconds 5

# Updating SOFTWARE registry 
# Disabling Consumer Experience
Set-RegistryValue `
    -Path "HKLM:\NewOS\Policies\Microsoft\Windows\CloudContent" `
    -Name "DisableWindowsConsumerFeatures" `
    -Type "DWord" `
    -Value 1 `
    -Description "Disabling Windows Consumer Features"

# Updating SOFTWARE registry 
# Disable Windows Updates
Set-RegistryValue `
    -Path "HKLM:\NewOS\Policies\Microsoft\Windows\WindowsUpdate" `
    -Name "DoNotConnectToWindowsUpdateInternetLocations" `
    -Type "DWord" `
    -Value 1 `
    -Description "Disabling Windows Updates"

# Updating SOFTWARE registry 
# Disable Edge Updates 
Set-RegistryValue `
    -Path "HKLM:\NewOS\Policies\Microsoft\EdgeUpdate" `
    -Name "AutoUpdateCheckPeriodMinutes" `
    -Type "DWord" `
    -Value 0 `
    -Description "Disabling Edge Updates"

# Updating SOFTWARE registry 
# Disable Edge Updates 
Set-RegistryValue `
    -Path "HKLM:\NewOS\Policies\Microsoft\EdgeUpdate" `
    -Name "UpdateDefault" `
    -Type "DWord" `
    -Value 0 `
    -Description "Disabling Edge Updates"

# Updating SOFTWARE registry 
# Exclude Drivers in Windows Update
Set-RegistryValue `
    -Path "HKLM:\NewOS\Policies\Microsoft\Windows\WindowsUpdate" `
    -Name "ExcludeWUDriversInQualityUpdate" `
    -Type "DWord" `
    -Value 1 `
    -Description "Exclude Drivers in Windows Update"

# Updating SOFTWARE registry 
# Disable Dual Scan
Set-RegistryValue `
    -Path "HKLM:\NewOS\Policies\Microsoft\Windows\WindowsUpdate" `
    -Name "DisableDualScan" `
    -Type "DWord" `
    -Value 1 `
    -Description "Disable Dual Scan"

# Updating SOFTWARE registry 
# Set WSUS Server updates
Set-RegistryValue `
    -Path "HKLM:\NewOS\Policies\Microsoft\Windows\WindowsUpdate\AU" `
    -Name "UseWUServer" `
    -Type "DWord" `
    -Value 1 `
    -Description "Set WSUS Server updates"

# Updating SOFTWARE registry 
# Set WSUS Server updates
Set-RegistryValue `
    -Path "HKLM:\NewOS\Policies\Microsoft\Windows\WindowsUpdate" `
    -Name "WUServer" `
    -Type "String" `
    -Value $WSUSServer `
    -Description "Set WSUS Server updates"


# Cleanup (to prevent access denied issue unloading the registry hive)
[gc]::collect()
Start-Sleep -Seconds 5

# Unload the registry hive
Write-Log -Message "Unloading the registry hive"
Set-Location X:\
reg unload "HKLM\NewOS"  

Start-Sleep -Seconds 5



############# Disable the Service via offline SYSTEM hive ####################

# Load the SYSTEM offline registry hive from the OS volume
$OSDTargetSystemDrive = $TSEnv.Value("OSDTargetSystemDrive")
$HivePath = "$OSDTargetSystemDrive\Windows\System32\config\SYSTEM"
Write-Log -Message "About to load registry hive: $HivePath"
reg load "HKLM\NewOS" $HivePath 
Start-Sleep -Seconds 5

# Updating SYSTEM registry 
# Disable the Windows Update Service
Set-RegistryValue `
    -Path "HKLM:\NewOS\ControlSet001\Services\wuauserv" `
    -Name "Start" `
    -Type "DWord" `
    -Value 4 `
    -Description "Disable the Windows Update Service"

# Updating SYSTEM registry 
# Disable the edgeupdate Edge Update Service
Set-RegistryValue `
    -Path "HKLM:\NewOS\ControlSet001\Services\edgeupdate" `
    -Name "Start" `
    -Type "DWord" `
    -Value 4 `
    -Description "Disable the edgeupdate Edge Update Service"

# Updating SYSTEM registry 
# Disable the edgeupdatem Edge Update Service
Set-RegistryValue `
    -Path "HKLM:\NewOS\ControlSet001\Services\edgeupdatem" `
    -Name "Start" `
    -Type "DWord" `
    -Value 4 `
    -Description "Disable the edgeupdatem Edge Update Service"

# Cleanup (to prevent access denied issue unloading the registry hive)
[gc]::collect()
Start-Sleep -Seconds 5

# Unload the registry hive
Write-Log -Message "Unloading the registry hive"
Set-Location X:\
reg unload "HKLM\NewOS"  
