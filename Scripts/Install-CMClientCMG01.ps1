#Obtain CCMSETUPCMD arguments from CoMgmtSettingsProd Properties under \Administration\Overview\Cloud Services\Cloud Attach in CM Console
Start-Process msiexec -Wait -ArgumentList '/i ccmsetup.msi /q CCMSETUPCMD="CCMHOSTNAME=CMG01.CORP.VIAMONSTRA.COM/CCM_Proxy_MutualAuth/54465498798456 SMSSiteCode=PS1"'
timeout 10
Wait-Process -Name ccmsetup
