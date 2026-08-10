<#

************************************************************************************************************************

Created:	2026-08-09
Version:	1.0

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and 
is not supported by the author or DeploymentArtist.

Author - Johan Arwidmark
    Twitter: @jarwidmark
    Blog   : http://deploymentresearch.com

************************************************************************************************************************

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