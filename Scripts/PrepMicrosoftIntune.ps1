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

# Copy the Microsoft Intune Setup files locally
Copy-Item .\Microsoft_Intune_Setup.exe "C:\Windows\Temp"
Copy-Item .\MicrosoftIntune.accountcert "C:\Windows\Temp"

# Create a registry key to specify that the Intune client installation is pending registration in the cloud
Reg.exe add HKEY_LOCAL_MACHINE\Software\Microsoft\Onlinemanagement\Deployment /v WindowsIntuneEnrollPending /t REG_DWORD /d 1

# Run the Installer locally with the argument /PrepareEnroll
& C:\Windows\Temp\Windows_Intune_Setup.exe /PrepareEnroll