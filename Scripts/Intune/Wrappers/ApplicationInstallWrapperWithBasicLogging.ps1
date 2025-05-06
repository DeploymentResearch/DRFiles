# Initialize
$ScriptDir = split-path -parent $MyInvocation.MyCommand.Path
$ScriptName = split-path -leaf $MyInvocation.MyCommand.Path
$Lang = (Get-Culture).Name
$Architecture = $env:PROCESSOR_ARCHITECTURE
$Logpath = "C:\ProgramData\ViaMonstra\QlikView"
$LogFile = $Logpath + "\" + "$ScriptName.txt"

# Logging function
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

# Log base info
Write-Log "$ScriptName - ScriptDir: $ScriptDir"
Write-Log "$ScriptName - ScriptName: $ScriptName"
Write-Log "$ScriptName - Current Culture: $Lang"
Write-Log "$ScriptName - Architecture: $Architecture"
Write-Log "$ScriptName - Log: $LogFile"

# Copy PreReq Files
If (!(Test-Path "C:\Windows\System32\EMC\QlikView")) {New-Item -Path "C:\Windows\System32\EMC\QlikView" -ItemType Directory}
Copy-Item -Path "$ScriptDir\Settings.ini" -Destination "C:\Windows\System32\EMC\QlikView\"
Copy-Item -Path "$ScriptDir\QlikViewAppDataCopy.cmd" -Destination "C:\Windows\System32\EMC\QlikView\"

# Installing
$SetupName = "QlikView Plugin"
$SetupFile = "msiexec"
$SetupSwitches = "/passive /i $ScriptDir\QvPluginSetup-v11.msi ALLUSERS=1 /quiet"
Write-Log "Starting install of $SetupName"
Write-Log "Command line to start is: $SetupFile $SetupSwitches"
Start-Process -FilePath $SetupFile -ArgumentList $SetupSwitches -NoNewWindow -Wait
Write-Log "Finished installing $SetupName"

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

