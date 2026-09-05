<#
.SYNOPSIS
    Mounts and dismounts a boot image WIM file.
.DESCRIPTION
    Minimal reference snippet for mounting a boot image, making changes, and saving them back
    to the WIM file.
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
      1.0.0 - 2024-01-06 - Initial release
#>

# Set Variables
$MountPath = "E:\Mount"
$WimFile = "E:\Sources\OSD\Boot\Zero Touch WinPE 11 x64\WinPE.wim"

# Mount the boot image
Mount-WindowsImage -ImagePath $WimFile -Path $MountPath -Index 1

# Do Whatever

# Unmount the Boot Image WIM file and save the changes
Dismount-WindowsImage -Path $MountPath -Save 
