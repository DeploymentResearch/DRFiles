<#
.SYNOPSIS
    Lists the current BIOS settings on a Lenovo device.
.DESCRIPTION
    Queries the Lenovo_BiosSetting WMI class and displays the current values in a grid view.
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
      1.0.0 - 2025-06-19 - Initial release
#>

(Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\wmi).CurrentSetting | Where-Object {$_ -ne ""} | Sort-Object | Out-GridView
