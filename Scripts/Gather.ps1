<#
.SYNOPSIS
    Checks for elevation before running a gather operation.
.DESCRIPTION
    Elevation check wrapper used ahead of the gather logic in a deployment script.
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
      1.0.0 - 2022-01-02 - Initial release
#>

# Check for elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
    Write-Warning "Aborting script..."
    Break
}

cls
if (Test-Path -Path "C:\MININT") {Write-Host "C:\MININT exists, deleting...";Remove-Item C:\MININT -Recurse}
cscript.exe ZTIGather.wsf /debug:true

# Optional, comment out if you want the script to open the log in CMTrace
& "C:\MDT\CMTrace" C:\MININT\SMSOSD\OSDLOGS\ZTIGather.log
