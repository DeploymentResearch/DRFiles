<#
.SYNOPSIS
    Application install wrapper with PowerShell transcript logging.
.DESCRIPTION
    Sample wrapper for ConfigMgr application installs. Detects script folder, culture, and
    architecture, starts a transcript, then runs the installer.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark / deploymentresearch.com
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2017-03-21 - Initial release
#>

# Initialize
$ScriptDir = split-path -parent $MyInvocation.MyCommand.Path
$ScriptName = split-path -leaf $MyInvocation.MyCommand.Path
$Lang = (Get-Culture).Name
$Architecture = $env:PROCESSOR_ARCHITECTURE
$Logpath = "C:\Windows\Temp"
$LogFile = $Logpath + "\" + "$ScriptName.txt"

# Start logging
Start-transcript -path $LogFile

#Output base info
Write-Output ""
Write-Output "$ScriptName - ScriptDir: $ScriptDir"
Write-Output "$ScriptName - ScriptName: $ScriptName"
Write-Output "$ScriptName - Current Culture: $Lang"
Write-Output "$ScriptName - Architecture: $Architecture"
Write-Output "$ScriptName - Log: $LogFile"

# Copy PreReq Files
If (!(Test-Path "C:\Windows\System32\EMC\QlikView")) {New-Item -Path "C:\Windows\System32\EMC\QlikView" -ItemType Directory}
Copy-Item -Path "$ScriptDir\Settings.ini" -Destination "C:\Windows\System32\EMC\QlikView\"
Copy-Item -Path "$ScriptDir\QlikViewAppDataCopy.cmd" -Destination "C:\Windows\System32\EMC\QlikView\"

# Installing
$SetupName = "QlikView Plugin"
$SetupFile = "msiexec"
$SetupSwitches = "/passive /i $ScriptDir\QvPluginSetup-v11.msi ALLUSERS=1 /quiet"
Write-Output "Starting install of $SetupName"
Write-Output "Command line to start is: $SetupFile $SetupSwitches"
Start-Process -FilePath $SetupFile -ArgumentList $SetupSwitches -NoNewWindow -Wait
Write-Output "Finished installing $SetupName"

# Post Installation tasks

## Default Profile Location
$defaultProfileHive = "HKLM\DefaultProfile"
$defaultProfileLocation = "C:\Users\Default\ntuser.dat"
$regFile = "$ScriptDir\HKCU_QvPluginSetup_DefaultProfile.reg"

## Load Default Profile Registry Hive
reg load $defaultProfileHive $defaultProfileLocation

## Call .reg file from local directory
regedit /s $regFile

## Release handles on Registry Hive
[gc]::collect()

## Unload Default Profile Registry Hive
reg unload $defaultProfileHive

# Stop logging
Stop-Transcript
