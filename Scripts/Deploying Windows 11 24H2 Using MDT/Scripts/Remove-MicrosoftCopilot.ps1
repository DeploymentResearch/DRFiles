<#
.SYNOPSIS
    Removes the Microsoft Copilot app from Windows.
.DESCRIPTION
    Uninstalls the Copilot Appx package for the current user.
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
      1.0.0 - 2024-12-01 - Initial release
#>

Get-AppxPackage -Name Microsoft.Copilot | Remove-AppxPackage
