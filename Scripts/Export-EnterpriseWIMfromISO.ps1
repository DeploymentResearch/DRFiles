# Sample scripts for export Enterprise sku's from Windows 10 ISO files

# Below are details for the build
$ExportList = @()
$ExportList += [pscustomobject]@{ ISOPath = "E:\ISO\Windows 10 Enterprise x64 v1507.iso"; OutputWIMFile = "C:\Ref\REFW10-X64-1507-Original.wim" }
$ExportList += [pscustomobject]@{ ISOPath = "E:\ISO\Windows 10 Enterprise x64 v1511.iso"; OutputWIMFile = "C:\Ref\REFW10-X64-1511-Original.wim" }
$ExportList += [pscustomobject]@{ ISOPath = "E:\ISO\Windows 10 Enterprise x64 v1607.iso"; OutputWIMFile = "C:\Ref\REFW10-X64-1607-Original.wim" }
$ExportList += [pscustomobject]@{ ISOPath = "E:\ISO\Windows 10 Enterprise x64 v1703.iso"; OutputWIMFile = "C:\Ref\REFW10-X64-1703-Original.wim" }
$ExportList += [pscustomobject]@{ ISOPath = "E:\ISO\Windows 10 Business Editions x64 v1709.iso"; OutputWIMFile = "C:\Ref\REFW10-X64-1709-Original.wim" }
$ExportList += [pscustomobject]@{ ISOPath = "E:\ISO\Windows 10 Business Editions x64 v1803.iso"; OutputWIMFile = "C:\Ref\REFW10-X64-1803-Original.wim" }
$ExportList += [pscustomobject]@{ ISOPath = "E:\ISO\Windows 10 Business Editions x64 v1809.iso"; OutputWIMFile = "C:\Ref\REFW10-X64-1809-Original.wim" }
$ExportList += [pscustomobject]@{ ISOPath = "E:\ISO\Windows 10 Business Editions x64 v1903.iso"; OutputWIMFile = "C:\Ref\REFW10-X64-1903-Original.wim" }
$ExportList += [pscustomobject]@{ ISOPath = "E:\ISO\Windows 10 Business Editions x64 v1909.iso"; OutputWIMFile = "C:\Ref\REFW10-X64-1909-Original.wim" }
$ExportList += [pscustomobject]@{ ISOPath = "E:\ISO\Windows 10 Business Editions x64 v2004.iso"; OutputWIMFile = "C:\Ref\REFW10-X64-2004-Original.wim" }

foreach ($row in $ExportList){

    $ISO = $row.ISOPath
    $WIM = $row.OutputWIMFile

    Write-host "Exporting from $ISO into $WIM"
    Mount-DiskImage -ImagePath $ISO
    $ISOImage = Get-DiskImage -ImagePath $ISO | Get-Volume
    $ISODrive = [string]$ISOImage.DriveLetter+":"

    Export-WindowsImage -SourceImagePath "$ISODrive\sources\install.wim" -SourceName "Windows 10 Enterprise" -DestinationImagePath $WIM 

    Dismount-DiskImage -ImagePath $ISO

}

# Single Export 1909
$ISO = "E:\ISO\Windows 10 Business Editions x64 1909 (updated March 2021).iso"
$WIM = "C:\Ref\REFW10-X64-1909-March-2021-Enterprise.wim"
Mount-DiskImage -ImagePath $ISO
$ISOImage = Get-DiskImage -ImagePath $ISO | Get-Volume
$ISODrive = [string]$ISOImage.DriveLetter+":"
Export-WindowsImage -SourceImagePath "$ISODrive\sources\install.wim" -SourceName "Windows 10 Enterprise" -DestinationImagePath $WIM 
Dismount-DiskImage -ImagePath $ISO

# Single Export 20H2
$ISO = "E:\ISO\Windows 10 Business Editions x64 20H2 (updated March 2021).iso"
$WIM = "C:\Ref\REFW10-X64-20H2-March-2021-Enterprise.wim"
Mount-DiskImage -ImagePath $ISO
$ISOImage = Get-DiskImage -ImagePath $ISO | Get-Volume
$ISODrive = [string]$ISOImage.DriveLetter+":"
Export-WindowsImage -SourceImagePath "$ISODrive\sources\install.wim" -SourceName "Windows 10 Enterprise" -DestinationImagePath $WIM 
Dismount-DiskImage -ImagePath $ISO
