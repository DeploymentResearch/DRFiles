<#
.SYNOPSIS
    Removes the Graph PowerShell Module and the modules that depend on it.
.DESCRIPTION
    Uninstalls all versions of the Graph and related Intune modules, which is usually needed
    before a clean reinstall. Close any open PowerShell sessions afterwards.
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
      1.0.0 - 2025-05-22 - Initial release
#>

# After uninstalling, close any PowerShell sessions

# Uninstall other Modules that may use it
Uninstall-Module IntuneStuff -AllVersions
Uninstall-Module WindowsAutoPilotIntune -AllVersions
Uninstall-Module WindowsAutopilotIntuneCommunity -AllVersions
Uninstall-Module IntuneDeviceInventory -AllVersions

# Uninstall Microsoft Graph (first all modules except Authentication, then the Authentication module)
Get-InstalledModule Microsoft.Graph.* | ForEach-Object { if($_.Name -ne "Microsoft.Graph.Authentication") { Uninstall-Module $_.Name -AllVersions } }
Uninstall-Module Microsoft.Graph.Authentication -AllVersions

# Close PowerShell sessions here....

# Install the latest version
Install-Module Microsoft.Graph -Verbose

# Get number of Modules
(Get-InstalledModule Microsoft.Graph.*).count
