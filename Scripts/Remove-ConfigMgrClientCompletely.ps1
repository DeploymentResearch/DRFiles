# Uninstall ConfigMgr agent via ccmsetup.exe
.\ccmsetup.exe /uninstall

# Stop WMI Service
$ServiceName = "winmgmt"
$Service = Get-Service -Name $ServiceName
 
 if ($Service.Status -eq "Running"){
 Stop-Service $ServiceName -Force
 Write-Host "Stopping $ServiceName service" 
 " ---------------------- " 
 " Service is now stopped"
 }
 
 if ($Service.Status -eq "stopped"){ 
 Write-Host "$ServiceName service is already stopped"
 }

# Remove ConfigMgr agent services
sc delete ccmsetup
sc delete ccmexec
sc delete cmrcservice
sc delete smstsmgr
If (Test-Path -Path 'HKLM:\SYSTEM\CurrentControlSet\services\Ccmsetup'){ Remove-Item 'HKLM:\SYSTEM\CurrentControlSet\services\Ccmsetup' -Recurse }
If (Test-Path -Path 'HKLM:\SYSTEM\CurrentControlSet\services\CcmExec'){ Remove-Item 'HKLM:\SYSTEM\CurrentControlSet\services\CcmExec' -Recurse }
If (Test-Path -Path 'HKLM:\SYSTEM\CurrentControlSet\services\smstsmgr'){ Remove-Item 'HKLM:\SYSTEM\CurrentControlSet\services\smstsmgr' -Recurse }
If (Test-Path -Path 'HKLM:\SYSTEM\CurrentControlSet\services\CmRcService'){ Remove-Item 'HKLM:\SYSTEM\CurrentControlSet\services\CmRcService' -Recurse }

# Remove ConfigMgr agent directories
If (Test-Path "$env:windir\ccm") { Remove-Item -Path "$env:windir\ccm" -Recurse }
If (Test-Path "$env:windir\ccmsetup") { Remove-Item -Path "$env:windir\ccmsetup" -Recurse }
If (Test-Path "$env:windir\ccmcache") { Remove-Item -Path "$env:windir\ccmcache" -Recurse }

# Remove other ConfigMgr agent files 
If (Test-Path "%windir%\smscfg.ini") { Remove-Item -Path "$env:windir\smscfg.ini" }
Remove-Item -Path "$env:windir\sms*.mif"

# Remove ConfigMgr agent registry keys
If (Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\CCM'){ Remove-Item 'HKLM:\SOFTWARE\Microsoft\CCM' -Recurse }
If (Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\CCMSetup'){ Remove-Item 'HKLM:\SOFTWARE\Microsoft\CCMSetup' -Recurse }
If (Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\SMS'){ Remove-Item 'HKLM:\SOFTWARE\Microsoft\SMS' -Recurse }

# Remove ConfigMgr agent WMI classes
get-wmiobject -query "SELECT * FROM __Namespace WHERE Name='CCM'" -Namespace "root" | Remove-WmiObject
get-wmiobject -query "SELECT * FROM __Namespace WHERE Name='sms'" -Namespace "root\cimv2" | Remove-WmiObject

# Remove tasks from task scheduler (taskschd.msc)
# Under Microsoft delete the Configuration Manager folder and any tasks within it