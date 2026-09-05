<#
.SYNOPSIS
    Installs the AADInternals PowerShell module and its prerequisites.
.DESCRIPTION
    Enables TLS 1.2, installs the NuGet package provider and PowerShellGet, trusts the
    PowerShell Gallery, and installs the module.
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
      1.0.0 - 2026-07-15 - Initial release
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module PowerShellGet -Force -AllowClobber

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module AADInternals -SkipPublisherCheck -Scope AllUsers
