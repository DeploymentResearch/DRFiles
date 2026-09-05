<#
.SYNOPSIS
    Checks whether .NET Framework 4.8 is installed.
.DESCRIPTION
    Reads the release value from the NDP registry key and compares it against the known 4.8
    release numbers.
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
      1.0.0 - 2026-05-31 - Initial release
#>

$Version = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release
If ($Version -in 528040, 528049, 528372, 528449){
    Write-Host "Microsoft .NET Framework 4.8 is installed" 
}
