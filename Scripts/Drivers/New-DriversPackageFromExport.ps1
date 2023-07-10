$DriversPath = "C:\Drivers"
$TempPath = "C:\Temp" 

New-Item -Path $DriversPath -ItemType Directory -Force
New-Item -Path $TempPath -ItemType Directory -Force

Export-WindowsDriver -Online -Destination C:\Drivers

New-WindowsImage -CapturePath $DriversPath -ImagePath "$TempPath\DriverPackage.wim" -Name "Driver Automation Tool Package"

