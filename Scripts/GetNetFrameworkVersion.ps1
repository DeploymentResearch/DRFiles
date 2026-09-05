<#
.SYNOPSIS
    Reports the installed .NET Framework version.
.DESCRIPTION
    Reads the release value from the NDP registry key and translates it into the matching .NET
    Framework version number.
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

$Version = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -recurse | 
Get-ItemProperty -name Release -EA 0 | 
#Where { $_.PSChildName -match '^(?![SW])\p{L}'} |
Select @{
  name="Release"
  expression={
      switch -regex ($_.Release) {
        "378389" { [Version]"4.5" }
        "378675|378758" { [Version]"4.5.1" }
        "379893" { [Version]"4.5.2" }
        "393295|393297" { [Version]"4.6" }
        "394254|394271" { [Version]"4.6.1" }
        "394802|394806" { [Version]"4.6.2" }
        "460798|460805" { [Version]"4.7" }
        "461308|461310" { [Version]"4.7.1" }
        "461808|461814" { [Version]"4.7.2" }
        "528040|528049" { [Version]"4.8" }
        {$_ -gt 528049} { [Version]"Undocumented version (> 4.8), please update script" }
      }
    }
}

Return $Version.Release.ToString()
