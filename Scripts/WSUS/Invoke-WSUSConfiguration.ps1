# WSUS Administration Max Connections Should be Unlimited	
Import-Module webadministration ; (get-itemproperty IIS:\Sites\'WSUS Administration' -name limits.maxConnections.Value)
Import-Module webadministration ; set-Itemproperty IIS:\Sites\'WSUS Administration' -Name limits.maxConnections -Value 4294967295

# WSUS Administration MaxBandwidth should be unlimited
Import-Module webadministration ; (get-itemproperty IIS:\Sites\'WSUS Administration' -name limits.maxbandwidth.Value)
Import-Module webadministration ; set-Itemproperty IIS:\Sites\'WSUS Administration' -Name limits.maxBandwidth -Value 4294967295

# WSUS Administration TimeOut should be 320
Import-Module webadministration;(get-itemproperty IIS:\Sites\'WSUS Administration' -Name limits.connectionTimeout.value).TotalSeconds
Import-Module webadministration ; set-Itemproperty IIS:\Sites\'WSUS Administration' -Name limits.connectionTimeout -Value 00:05:20

# Copy the web.config file to a location where it can be modified
$TempPath = "D:\Installs\WSUS"
$OriginalFileName = (Get-WebConfigFile 'IIS:\Sites\WSUS Administration\ClientWebService').fullname
Copy-Item -Path $OriginalFileName -Destination $TempPath
$FullFileName = "$TempPath\Web.config"

# WSUS ClientWebService web.config executionTimeout should be 7200
[XML]$xml = Get-Content $FullFileName
$ChangeThis = ((($xml.configuration).'system.web').httpRunTime)
$ChangeThis.SetAttribute('executionTimeout', '7200')
$xml.Save($FullFileName)

# WSUS ClientWebService web.config maxRequestLength should be 20480
[XML]$xml = Get-Content $FullFileName
$ChangeThis = ((($xml.configuration).'system.web').httpRunTime)
$ChangeThis.maxRequestLength = "20480"
$xml.Save($FullFileName)

# WSUSPool CPU ResetInterval should be 15 min
Import-Module webadministration ; set-Itemproperty IIS:\AppPools\Wsuspool -Name cpu -Value @{resetInterval="00:15:00"}

# WSUSPool Ping Disabled
Import-Module webadministration ; set-Itemproperty IIS:\AppPools\Wsuspool -Name processmodel.pingingEnabled False

# WSUSPool Private Memory Limit should be 0
Import-module webadministration
$applicationPoolsPath = "/system.applicationHost/applicationPools"
$appPoolPath = "$applicationPoolsPath/add[@name='WsusPool']"
Set-WebConfiguration "$appPoolPath/recycling/periodicRestart/@privateMemory" -Value 0

# WSUSPool queueLength should be 30000
Import-Module webadministration ; set-Itemproperty IIS:\AppPools\Wsuspool -name queueLength 30000

# WSUSPool RapidFail Should be Disable
Import-Module webadministration ; set-Itemproperty IIS:\AppPools\Wsuspool -name failure.rapidFailProtection False

# WSUSPool Recycling Regular Time interval should be 0
Import-Module webadministration ; set-Itemproperty IIS:\AppPools\Wsuspool recycling.periodicRestart.time -Value 00:00:00

# WSUSPool requests should be 0
Import-module webadministration
$applicationPoolsPath = "/system.applicationHost/applicationPools"
$appPoolPath = "$applicationPoolsPath/add[@name='WsusPool']"
Set-WebConfiguration "$appPoolPath/recycling/periodicRestart/@requests" -Value 0

# Use Robocopy to restore the web.config file
robocopy "$TempPath\" "C:\Program Files\Update Services\WebServices\ClientWebService" web.config /R:0 /B

