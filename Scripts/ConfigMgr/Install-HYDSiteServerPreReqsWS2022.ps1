<#
.SYNOPSIS
    Installs ConfigMgr site server prerequisites on Windows Server 2022.
.DESCRIPTION
    Adds the IIS, BITS, RDC, and .NET Framework features required by a primary site server.
    Requires internet access unless the Source parameter is supplied.
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
Web-Windows-Auth,
Web-ISAPI-Ext,
Web-Metabase,
Web-WMI,
BITS,
RDC,
NET-Framework-45-Features,
NET-WCF-HTTP-Activation45,
NET-WCF-TCP-PortSharing45,
Web-Asp-Net45,
Web-Static-Content,
Web-Default-Doc,
Web-Dir-Browsing,
Web-Http-Errors,
Web-Http-Redirect,
Web-App-Dev,
Web-Net-Ext45,
Web-ISAPI-Filter,
Web-Health,
Web-Http-Logging,
Web-Log-Libraries,
Web-Request-Monitor,
Web-Http-Tracing,
Web-Security,
Web-Filtering,
Web-Performance,
Web-Stat-Compression,
Web-Mgmt-Console,
Web-Scripting-Tools,
Web-Mgmt-Compat
