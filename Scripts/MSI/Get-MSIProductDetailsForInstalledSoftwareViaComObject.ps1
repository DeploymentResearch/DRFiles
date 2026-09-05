<#
.SYNOPSIS
    Lists installed MSI products and their cached package paths.
.DESCRIPTION
    Enumerates the installed products through the WindowsInstaller COM object and returns the
    product code and local package path for each one.
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
      1.0.0 - 2023-09-20 - Initial release
#>

$Installer = New-Object -ComObject WindowsInstaller.Installer
$InstallerProducts = $Installer.ProductsEx("", "", 7)
$InstalledProducts = ForEach($Product in $InstallerProducts){
    [PSCustomObject]@{ProductCode = $Product.ProductCode()
    LocalPackage = $Product.InstallProperty("LocalPackage")
    VersionString = $Product.InstallProperty("VersionString")
    ProductPath = $Product.InstallProperty("ProductName")}
} 

$InstalledProducts | Where-Object { $_.productpath -like "*stifler*"  }
