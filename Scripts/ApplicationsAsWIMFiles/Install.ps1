<#
.SYNOPSIS
    Mounts an application WIM file and runs the installer inside it.
.DESCRIPTION
    Companion install script for the applications as WIM files scenario. Mounts Source.wim to a
    temporary folder, runs the installation, then dismounts and cleans up.
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
      1.0.0 - 2025-12-17 - Initial release
#>

# Define path
$WimFile = Get-ChildItem Source.wim
$MountPath = "C:\Users\Public\mount_" + $WimFile.BaseName
$ScriptDir = split-path -parent $MyInvocation.MyCommand.Path

# Mount the WIM file
New-Item -Path $MountPath -ItemType Directory
Mount-WindowsImage -ImagePath $wimFile.FullName -Index 1 -Path $mountPath

# Install the app
$SetupFile = "msiexec"
$SetupSwitches = "/i $MountPath\snagit.msi /q"
Start-Process -FilePath $SetupFile -ArgumentList $SetupSwitches -NoNewWindow -Wait
    
# Dismount the WIM file and Remove mount folder
Dismount-WindowsImage -Path $MountPath -Discard
Remove-Item -Path $MountPath -Force
