# Creating a drive wim package manually
$MountPath = "E:\Work\mount"
$DriverSource = "\\corp.viamonstra.com\fs1\SCCMSources\OSD\Driver Sources\Windows 10 x64\Lenovo m92p"
$TempSource = "E:\Work\TempSource"
$PackageDataSource = "\\corp.viamonstra.com\fs1\SCCMSources\OSD\MDMDriverPackages\Lenovo\ThinkCentre M92P 3227\Windows10-x64-201911\StandardPkg"

Copy-Item -Path $DriverSource -Destination $TempSource -Recurse

New-WindowsImage -CapturePath $TempSource -ImagePath "$PackageDataSource\DriverPackage.wim" -Name "StandardPkg"