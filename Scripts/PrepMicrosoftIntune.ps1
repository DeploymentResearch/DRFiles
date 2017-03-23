#----------------------------------------------------------------------------
# Purpose: Used to install the Microsoft Intune Client Software in a reference image
# 
# Version: 1.0 - March 21, 2017 - Johan Arwidmark
#
# Twitter: @jarwidmark
# Blog   : http://deploymentresearch.com
# 
# Disclaimer:
# This script is provided "AS IS" with no warranties, confers no rights and 
# is not supported by the authors or Deployment Artist.
#----------------------------------------------------------------------------

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

# Copy the Microsoft Intune Setup files locally
New-Item -Path "C:\Setup\Intune" -ItemType Directory -Force
Copy-Item .\Microsoft_Intune_Setup.exe "C:\Setup\Intune"
Copy-Item .\MicrosoftIntune.accountcert "C:\Setup\Intune"

# Create a registry key to specify that the Intune client installation is pending registration in the cloud
New-Item -Path 'HKLM:\Software\Microsoft\Onlinemanagement\Deployment' -Force
New-ItemProperty -Path 'HKLM:\Software\Microsoft\Onlinemanagement\Deployment' -PropertyType dword -Name "WindowsIntuneEnrollPending" -Value 00000001 

# Run the Installer locally with the argument /PrepareEnroll
$SetupName = "Microsoft Intune Client Software"
$SetupFile = "C:\Setup\Intune\Microsoft_Intune_Setup.exe"
$SetupSwitches = "/PrepareEnroll"
Write-Output "Starting install of $SetupName"
Write-Output "Command line to start is: $SetupFile $SetupSwitches"
Start-Process -FilePath $SetupFile -ArgumentList $SetupSwitches -NoNewWindow -Wait
Write-Output "Finished installing $SetupName"

# Stop logging
Stop-Transcript