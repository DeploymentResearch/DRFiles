<#
.Synopsis
    This script runs Sysprep and some additional cleanup for Windows Autopilot
    
.Description
    This script was written by Johan Arwidmark @jarwidmark

.LINK
    https://github.com/FriendsOfMDT/PSD

.NOTES
          FileName: PSDSysprepForAutopilot.ps1
          Solution: PowerShell Deployment for MDT
          Author: PSD Development Team
          Contact: @jarwidmark
          Primary: @jarwidmark 
          Created: 2020-11-09
          Modified: 2020-11-18

          Version - 0.0.0.1 - () - Finalized functional version 1.

.EXAMPLE
	.\PSDSysprepForAutopilot.ps1
#>

#Requires -RunAsAdministrator
[CmdletBinding()]
param (

)

# Import core PSD module
Import-Module PSDUtility -Force -Scope Global


# Check for debug in PowerShell and TSEnv
if($TSEnv:PSDDebug -eq "YES"){
    $Global:PSDDebug = $true
}
if($PSDDebug -eq $true)
{
    $verbosePreference = "Continue"
}

Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Starting..."

# Verify that Sysprep unattend.xml file exist
$SysprepUnattendPath = "C:\MININT\Cache\Scripts"
$SysprepUnattendFile = "UnattendForAutopilotSysprep.xml"
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Verifying that Sysprep unattend.xml file exist in $SysprepUnattendPath"
If (Test-path "$SysprepUnattendPath\$SysprepUnattendFile"){
    Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): $SysprepUnattendFile file found in $SysprepUnattendPath"
}
Else{
    Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): $SysprepUnattendFile file Not found in $SysprepUnattendPath, aborting..."
    Exit 1
}

# Stop sysprep if exists (Auditmode)
$SysprepProcess = Get-Process Sysprep -ErrorAction SilentlyContinue
if ($SysprepProcess){
    Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Sysprep process is running, we're probably in audit mode, stopping it"
    $SysprepProcess  | stop-process -Force
}

# Run sysprep
$SysprepPath = "C:\Windows\System32\Sysprep\Sysprep.exe"
$SysprepArgument = "/quiet /generalize /oobe /quit /unattend:$SysprepUnattendPath\$SysprepUnattendFile"
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): About to run: $SysprepPath $SysprepArgument"
$SysprepProcess = Start-Process $SysprepPath -ArgumentList $SysprepArgument -NoNewWindow -PassThru -Wait

# Making sure Sysprep completed successfully
If (Test-Path "C:\Windows\System32\Sysprep\Sysprep_succeeded.tag"){
    # Assume Sysprep succeeded
    Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): C:\Windows\System32\Sysprep\Sysprep_succeeded.tag found, Sysprep succeeded"
}
Else{
    # Assume Sysprep failed
    Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): C:\Windows\System32\Sysprep\Sysprep_succeeded.tag Not found, Sysprep failed"
    Exit 1
}