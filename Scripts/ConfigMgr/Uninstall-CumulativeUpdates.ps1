<#
.SYNOPSIS
    Lists and removes installed cumulative updates.
.DESCRIPTION
    Reports the installed rollup packages with their state and install time, then removes the
    specified package without restarting.
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
      1.0.0 - 2026-07-24 - Initial release
#>

Get-WindowsPackage -Online | Where-Object PackageName -like '*RollupFix*' |
    Select-Object PackageName, PackageState, InstallTime

Remove-WindowsPackage -Online -PackageName 'Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.8875.1.28' -NoRestart
