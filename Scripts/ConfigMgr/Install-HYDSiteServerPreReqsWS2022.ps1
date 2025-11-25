<#

************************************************************************************************************************

Created:	2025-11-25
Version:	1.0

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and 
is not supported by the author or DeploymentArtist.

Author - Johan Arwidmark
    Twitter: @jarwidmark
    Blog   : http://deploymentresearch.com

************************************************************************************************************************

#>

# Requires Internet Access, if not, use source
# Note: Scripts reboots
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
Web-Mgmt-Compat `
-Restart
