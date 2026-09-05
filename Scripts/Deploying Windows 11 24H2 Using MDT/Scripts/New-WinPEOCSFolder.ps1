<#
.SYNOPSIS
    Creates the empty x86 WinPE optional components folder MDT expects.
.DESCRIPTION
    MDT looks for the x86 WinPE_OCs folder even when only x64 is used, so this creates the
    folder to avoid the resulting error.
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
      1.0.0 - 2024-10-29 - Initial release
#>

# Create empty folder for x86 components (not used, but MDT looks for the folder)
$x86Folder = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs"
New-Item -Path $x86Folder -ItemType Directory -Force
