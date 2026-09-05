<#
.SYNOPSIS
    Unpins Internet Explorer from the taskbar.
.DESCRIPTION
    Uses the Shell.Application COM object to invoke the unpin verb on the taskbar item.
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
      1.0.0 - 2024-01-05 - Initial release
#>

# Unpin Internet Explorer from the Taskbar
$AppName = @("Internet Explorer")
$Action = "Unpin from taskbar"
((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | 
  Where-Object { $AppName -eq $_.Name }).Verbs() | 
  Where-Object {$_.Name.replace('&','') -match $Action} | 
  ForEach-Object {$_.DoIt()}
