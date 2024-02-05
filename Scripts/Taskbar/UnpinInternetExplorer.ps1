# Unpin Internet Explorer from the Taskbar
$AppName = @("Internet Explorer")
$Action = "Unpin from taskbar"
((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | 
  Where-Object { $AppName -eq $_.Name }).Verbs() | 
  Where-Object {$_.Name.replace('&','') -match $Action} | 
  ForEach-Object {$_.DoIt()}