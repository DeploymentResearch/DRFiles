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