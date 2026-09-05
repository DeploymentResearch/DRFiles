<#
.SYNOPSIS
    Exports the drivers from a running Windows installation into a WIM file.
.DESCRIPTION
    Runs Export-WindowsDriver against the online image and captures the exported drivers into a
    single WIM file for reuse in a deployment.
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
      1.0.0 - 2023-07-06 - Initial release
#>

$DriversPath = "C:\Drivers"
$TempPath = "C:\Temp" 

New-Item -Path $DriversPath -ItemType Directory -Force
New-Item -Path $TempPath -ItemType Directory -Force

Export-WindowsDriver -Online -Destination C:\Drivers

New-WindowsImage -CapturePath $DriversPath -ImagePath "$TempPath\DriverPackage.wim" -Name "Driver Automation Tool Package"

