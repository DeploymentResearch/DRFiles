<#
.SYNOPSIS
    Searches file contents recursively for a string and groups the hits by file.
.DESCRIPTION
    Reference snippets for finding which files under a path contain a given string, used for
    locating driver and tool references.
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
      1.0.0 - 2023-10-10 - Initial release
#>

Get-ChildItem -recurse | Select-String -pattern "serviceui" | group path | select name

$Path = "F:\Drivers\Intel Ethernet Adapter Complete Driver Pack\Release_28.2.1"
$Path = "F:\Drivers\Dell WinPE Drivers x64\WinPE10.0-Drivers-A31-HWWK8\network"
$SearchString = "VEN_8086&DEV_0DC5"
Get-ChildItem -Path $Path -Filter *.inf -recurse | Select-String -pattern $SearchString | Group-Object path | Select-Object name

$SearchString = "External"
Get-ChildItem *.ps1 -recurse | Select-String -pattern $SearchString | Group-Object path | Select-Object name

$SearchString = "TargetComputers"
Get-ChildItem *.inf -recurse | Select-String -pattern $SearchString | Group-Object path | Select-Object name



Get-ChildItem | Select-String -pattern "Microsoft.Policies.Sensors.WindowsLocationProvider" | group path | select name 
