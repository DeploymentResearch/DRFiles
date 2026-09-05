<#
.SYNOPSIS
    Creates a WIM file from an application source folder.
.DESCRIPTION
    Copies the application source to a temporary folder and captures it into a single WIM file,
    which gives BranchCache far better block reuse than loose files.
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

# Creating a drive wim package manually
$ApplicationsPath = "\\cm01\Sources\P2P Test Packages\300 MB Multiple Files"
$TempSource = "E:\Temp\TempSource"
$WimPathSource = "E:\Temp"

Copy-Item -Path $ApplicationsPath -Destination $TempSource -Recurse

New-WindowsImage -CapturePath $TempSource -ImagePath "$WimPathSource\Source.wim" -Name "Source"
