<#
.SYNOPSIS
    Removes leftover unattend.xml files after an Autopilot test deployment.
.DESCRIPTION
    Deletes unattend.xml from the Panther and Sysprep folders so the file does not interfere
    with the next OOBE run.
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
      1.0.0 - 2020-11-09 - Initial release
#>

If (Test-Path "C:\Windows\Panther\unattend.xml" ){Remove-Item "C:\Windows\Panther\unattend.xml" -Force } 
If (Test-Path "C:\Windows\System32\Sysprep\unattend.xml" ){Remove-Item "C:\Windows\System32\Sysprep\unattend.xml" -Force } 
