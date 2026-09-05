<#
.SYNOPSIS
    Installs distribution point prerequisites on Windows Server 2022.
.DESCRIPTION
    Adds the IIS, BITS, and RDC features required by a ConfigMgr distribution point. Requires
    internet access unless the Source parameter is supplied.
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
      1.0.0 - 2026-08-09 - Initial release
#>

# Requires Internet Access, if not, use -Source parameter

Install-WindowsFeature `
RDC,
Web-Server,
Web-Common-Http,
Web-Static-Content,
Web-Default-Doc,
Web-Http-Errors,
Web-App-Dev,
Web-ISAPI-Ext,
Web-Health,
Web-Http-Logging,
Web-Log-Libraries,
Web-Request-Monitor,
Web-Security,
Web-Filtering,
Web-Windows-Auth,
Web-Performance,
Web-Stat-Compression,
Web-Mgmt-Tools,
Web-Mgmt-Console,
Web-Scripting-Tools,
Web-Mgmt-Compat,
Web-Metabase,
Web-WMI
