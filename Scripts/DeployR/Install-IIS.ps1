<#
.SYNOPSIS
    Installs the IIS role features required by DeployR.
.DESCRIPTION
    Adds the web server role with the static content, error, digest authentication, Windows
    authentication, and management console features.
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
      1.0.0 - 2026-06-01 - Initial release
#>

# Install IIS
Add-WindowsFeature Web-Server, Web-Http-Errors, Web-Static-Content, Web-Digest-Auth, Web-Windows-Auth, Web-Mgmt-Console
