<#
.SYNOPSIS
    Installs the ConfigMgr client for use with a cloud management gateway.
.DESCRIPTION
    Runs ccmsetup with the CCMHOSTNAME and related arguments taken from the cloud attach
    properties in the ConfigMgr console.
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
      1.0.0 - 2022-05-05 - Initial release
#>

#Obtain CCMSETUPCMD arguments from CoMgmtSettingsProd Properties under \Administration\Overview\Cloud Services\Cloud Attach in CM Console
Start-Process msiexec -Wait -ArgumentList '/i ccmsetup.msi /q CCMSETUPCMD="CCMHOSTNAME=CMG01.CORP.VIAMONSTRA.COM/CCM_Proxy_MutualAuth/54465498798456 SMSSiteCode=PS1"'
timeout 10
Wait-Process -Name ccmsetup
