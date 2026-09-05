<#
.SYNOPSIS
    Bulk renames files with a numbered prefix.
.DESCRIPTION
    Renames every matching file in a folder with a sequential prefix. Includes a WhatIf line to
    preview the result before committing.
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
      1.0.0 - 2023-07-10 - Initial release
#>

Set-Location "D:\Videos"

# Rename all mp4 files with a prefix sequence
# WhatIf
Get-ChildItem *.mp4 | Foreach {$i=1} {Rename-Item $_ -NewName ("{0:0#} - $($_.name)" -f $i++) -whatif}

# Real Run 
Get-ChildItem *.mp4 | Foreach {$i=1} {Rename-Item $_ -NewName ("{0:0#} - $($_.name)" -f $i++)}
