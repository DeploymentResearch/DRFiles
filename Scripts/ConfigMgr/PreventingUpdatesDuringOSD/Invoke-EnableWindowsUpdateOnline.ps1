<#
.SYNOPSIS
    Script that enables Windows Updates again during the Windows (online) phase of ConfigMgr OSD
    
.DESCRIPTION
    Script that enables Windows Updates again during the Windows (online) phase of ConfigMgr OSD

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
    Released: 2026-01-01
    Change history:
      1.0.0 - 2026-01-01 - Initial release
#>

# Figure out if we can use the task sequence object
try {
		$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
        $LogPath = $TSEnv.Value("_SMSTSLogPath") 
        $Logfile = "$LogPath\EnableWindowsUpdatesOnline.log"
}
catch [System.Exception] {
	Write-Warning -Message "Unable to create Microsoft.SMS.TSEnvironment object, log in C:\Windows\Temp..."
    $LogPath = "C:\Windows\Temp" 
    $Logfile = "$LogPath\EnableWindowsUpdatesOnline.log"
}


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

function Enable-AndStartService {
    [CmdletBinding()]
    param(
        [string]$ServiceName = 'wuauserv'
    )

    # Enable + set to Automatic
    Write-Log "Enabling $ServiceName (set start type to Automatic)"
    & sc.exe config $ServiceName start= auto | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Warning: Failed to set $ServiceName start type to automatic. Exit code: $LASTEXITCODE"
    }

    # Start
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Log "Service $ServiceName not found, nothing to do."
        return
    }

    if ($svc.Status -ne 'Running') {
        Write-Log "Starting $ServiceName"
        & sc.exe start $ServiceName | Out-Null

        switch ($LASTEXITCODE) {
            0     { Write-Log "$ServiceName started successfully." }
            1056  { Write-Log "$ServiceName is already running (SC exit code 1056)." }
            default { Write-Log "Warning: Failed to start $ServiceName. Exit code: $LASTEXITCODE" }
        }
    }
    else {
        Write-Log "$ServiceName is already running."
    }
}

Write-Log "---------------- Starting Enabling Updates Online ----------------"
Write-Log "Enabling is done by removing previously configured policies."

# Updating SOFTWARE registry 
# Removing Consumer Experience
$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
$Name = "DisableWindowsConsumerFeatures" 
Write-Log "Removing $Value from registry key $Path"
Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue

# Updating SOFTWARE registry 
# Removing Windows Updates
$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$Name = "DoNotConnectToWindowsUpdateInternetLocations" 
Write-Log "Removing $Value from registry key $Path"
Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue

# Updating SOFTWARE registry 
# Removing Edge Updates 
$Path = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
$Name = "AutoUpdateCheckPeriodMinutes" 
Write-Log "Removing $Value from registry key $Path"
Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue

# Updating SOFTWARE registry 
# Removing Edge Updates 
$Path = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
$Name = "UpdateDefault" 
Write-Log "Removing $Value from registry key $Path"
Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue

# Updating SOFTWARE registry 
# Removing Drivers in Windows Update
$Path ="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$Name = "ExcludeWUDriversInQualityUpdate" 
Write-Log "Removing $Value from registry key $Path"
Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue

# Updating SOFTWARE registry 
# Removing Dual Scan
$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$Name = "DisableDualScan" 
Write-Log "Removing $Value from registry key $Path"
Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue

# Updating SOFTWARE registry 
# Removing WSUS Server
$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
$Name = "UseWUServer" 
Write-Log "Removing $Value from registry key $Path"
Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue

# Updating SOFTWARE registry 
# Removing WSUS Server 
$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$Name = "WUServer" 
Write-Log "Removing $Value from registry key $Path"
Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue

############# Disable and stop the Services  ####################

# Disable and Stopping WUAService"
Enable-AndStartService -ServiceName "wuauserv"

# Disable and stopping edgeupdate
Enable-AndStartService -ServiceName "edgeupdate"

# Disable and stopping edgeupdatem
Enable-AndStartService -ServiceName "edgeupdatem"

