<#
.SYNOPSIS
    Installs ConfigMgr site server prerequisites on Windows Server 2019.
.DESCRIPTION
    Adds the IIS, BITS, RDC, and .NET Framework features required by a primary site server.
    Requires internet access unless a source path is supplied, and the server reboots.
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
      1.1.0 - 2018-04-15 - Initial release
#>

# Requires Internet Access, if not, use source
# Note: Scripts reboots
Add-WindowsFeature Web-Windows-Auth,Web-ISAPI-Ext,Web-Metabase,Web-WMI,BITS,RDC,NET-Framework-Features,Web-Asp-Net,Web-Asp-Net45,NET-HTTP-Activation,NET-Non-HTTP-Activ,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Http-Redirect,Web-App-Dev,Web-Net-Ext,Web-Net-Ext45,Web-ISAPI-Filter,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-HTTP-Tracing,Web-Security,Web-Filtering,Web-Performance,Web-Stat-Compression,Web-Mgmt-Console,Web-Scripting-Tools,Web-Mgmt-Compat -Restart
