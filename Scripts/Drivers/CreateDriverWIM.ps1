<#
.SYNOPSIS
    Creates a driver package WIM file manually.
.DESCRIPTION
    Copies the driver source to a temporary folder and captures it into a single WIM file,
    which gives BranchCache far better block reuse than loose driver files.
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
      1.0.0 - 2021-04-06 - Initial release
#>

# Creating a drive wim package manually
$MountPath = "E:\Work\mount"
$DriverSource = "\\corp.viamonstra.com\fs1\SCCMSources\OSD\Driver Sources\Windows 10 x64\Lenovo m92p"
$TempSource = "E:\Work\TempSource"
$PackageDataSource = "\\corp.viamonstra.com\fs1\SCCMSources\OSD\MDMDriverPackages\Lenovo\ThinkCentre M92P 3227\Windows10-x64-201911\StandardPkg"

Copy-Item -Path $DriverSource -Destination $TempSource -Recurse

New-WindowsImage -CapturePath $TempSource -ImagePath "$PackageDataSource\DriverPackage.wim" -Name "StandardPkg"
