Set-Location "D:\Videos"

# Rename all mp4 files with a prefix sequence
# WhatIf
Get-ChildItem *.mp4 | Foreach {$i=1} {Rename-Item $_ -NewName ("{0:0#} - $($_.name)" -f $i++) -whatif}

# Real Run 
Get-ChildItem *.mp4 | Foreach {$i=1} {Rename-Item $_ -NewName ("{0:0#} - $($_.name)" -f $i++)}
