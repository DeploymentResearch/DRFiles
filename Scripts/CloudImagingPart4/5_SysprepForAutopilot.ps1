# Sysprep has an additional provider that is added in Windows 10 and Windows 8 to clean Appx packages and to generalize the image. 
# The provider works only if the Appx package is a per-user package or an all-user provisioned package.

# Per-user package means that the Appx package is installed for a particular user account and is not available for other users of the computer.
# All-user package means that the Appx has been provisioned into the image so that all users who use this image can access the app.
# If an all-user package that is provisioned into the image was manually deprovisioned from the image but not removed for a particular user, 
# the provider will encounter an error while cleaning out this package during sysprep. 
# The provider will also fail if an all-user package that is provisioned into the image was updated by one of the users on this reference computer.
# Get-AppxPackage | Remove-AppxPackage

<#
.Synopsis
    This script runs Sysprep for Windows Autopilot
    
#>

#Requires -RunAsAdministrator
[CmdletBinding()]
param (

)


$Logfile = "C:\Windows\Temp\SysprepForAutopilot.log"

# Delete any existing logfile if it exists
If (Test-Path $Logfile){Remove-Item $Logfile -Force -ErrorAction SilentlyContinue -Confirm:$false}

Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
   )

   $TimeGenerated = $(Get-Date -UFormat "%D %T")
   $Line = "$TimeGenerated : $Message"
   Add-Content -Value $Line -Path $LogFile -Encoding Ascii

}

Write-Log "SysprepForAutopilot: Starting..."

# Create Unattend.xml file for Sysprep
Write-Log "Create Unattend.xml file for Sysprep"
$UnattendForAutopilotSysprep = [xml]@"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="generalize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <DoNotCleanTaskBar>true</DoNotCleanTaskBar>
        </component>
        <component name="Microsoft-Windows-PnpSysprep" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <PersistAllDeviceInstalls>true</PersistAllDeviceInstalls>
            <DoNotCleanUpNonPresentDevices>false</DoNotCleanUpNonPresentDevices>
        </component>
    </settings>
</unattend>
"@

$SysprepUnattendFile = "$env:windir\Temp\UnattendForAutopilotSysprep.xml"
Write-Log "Saving Unattend.xml file: $SysprepUnattendFile"
$UnattendForAutopilotSysprep.Save($SysprepUnattendFile)

# Run sysprep
$SysprepPath = "C:\Windows\System32\Sysprep\Sysprep.exe"
$SysprepArguments = "/generalize /oobe /quit /unattend:$SysprepUnattendFile"
Write-Log "SysprepForAutopilot: About to run: $SysprepPath $SysprepArguments"
$SysprepProcess = Start-Process $SysprepPath -ArgumentList $SysprepArguments -NoNewWindow -PassThru -Wait

# Making sure Sysprep completed successfully
If (Test-Path "C:\Windows\System32\Sysprep\Sysprep_succeeded.tag"){
    # Assume Sysprep succeeded
    Write-Log "SysprepForAutopilot: C:\Windows\System32\Sysprep\Sysprep_succeeded.tag found, Sysprep succeeded"
    # All good, shutdown the computer
    & Shutdown.exe /s /t 30 /f
}
Else{
    # Assume Sysprep failed
    Write-Log "SysprepForAutopilot: C:\Windows\System32\Sysprep\Sysprep_succeeded.tag Not found, Sysprep failed"
    Exit 1
}