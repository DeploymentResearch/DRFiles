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