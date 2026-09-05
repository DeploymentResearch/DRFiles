<#
.SYNOPSIS
    Creates a shortcut on the desktop.
.DESCRIPTION
    Sample code showing how to create a shortcut with a custom icon using the WScript.Shell COM
    object.
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

# Sample code to create shortcut on Desktop 

$IconLocation = "$Env:USERPROFILE\Desktop\Icons-Land-Multiple-Smiley-Pirate-Smile.ico"
If (!(test-path $IconLocation)){ Write-warning "Oops, icon file is missing, aborting..."; Break }
$WshShell = New-Object -ComObject "WScript.Shell"
$ShortCut = $WshShell.CreateShortcut("$Env:USERPROFILE\Desktop\Link.lnk")
$ShortCut.TargetPath = 'https://google.com'
$ShortCut.IconLocation = $IconLocation
$ShortCut.Save()

