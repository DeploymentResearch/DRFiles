$Installer = New-Object -ComObject WindowsInstaller.Installer
$InstallerProducts = $Installer.ProductsEx("", "", 7)
$InstalledProducts = ForEach($Product in $InstallerProducts){
    [PSCustomObject]@{ProductCode = $Product.ProductCode()
    LocalPackage = $Product.InstallProperty("LocalPackage")
    VersionString = $Product.InstallProperty("VersionString")
    ProductPath = $Product.InstallProperty("ProductName")}
} 

$InstalledProducts | Where-Object { $_.productpath -like "*stifler*"  }