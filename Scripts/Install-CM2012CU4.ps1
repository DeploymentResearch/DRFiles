<#
.SYNOPSIS
    Installs ConfigMgr 2012 R2 Cumulative Update 4.
.DESCRIPTION
    Validates that the update setup files are present, then runs the installer silently.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark / deploymentresearch.com
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.1.0

    Change history:
      1.1.0 - 2022-01-02 - Initial release
#>

# Validation
Write-Output "Checking for CU4 setup files"
If (Test-Path C:\Setup\CM2012CU\CM12-R2CU4-KB3026739-X64-ENU.exe){
    Write-Output "CU4 setup files found, OK, continuing..."
    Write-Output ""
    } 
Else {
    Write-Output "Oupps, cannot find CU4 setup files, aborting..."
    Break
}

# Extract the CU4 setup files
C:\Setup\CM2012CU\CM12-R2CU4-KB3026739-X64-ENU.exe /X:C:\Setup\CM2012CU /Q

# Install the main CU4 site server update
msiexec /i C:\Setup\CM2012CU\cm12-r2cu4-kb3026739-x64-enu.msi NODBUPGRADE=0 NOADVCLIPACKAGE=0 /q /l*v C:\Windows\Temp\cm12-r2cu4-kb3026739-x64-enu.msi.log 
sleep 10

# Update the ConfigMgr Admin console
msiexec.exe /p "E:\Program Files\Microsoft Configuration Manager\hotfix\KB3026739\AdminConsole\i386\configmgr2012adminui-r2-kb3026739-i386.msp" /l*v C:\Windows\Temp\configmgr2012adminui-r2-kb3026739-i386.msp.LOG /q REINSTALL=ALL REINSTALLMODE=mous REBOOT=ReallySuppress
