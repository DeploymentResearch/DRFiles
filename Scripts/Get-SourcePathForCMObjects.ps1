# The Script lists all the content source paths for the following CM objects. 
# Applications 
# Driver Packages 
# Drivers 
# Boot Images 
# OS Images 
# Software Update Package Groups 
# Packages 

$SiteServer = $env:COMPUTERNAME
$SiteCode = "P01"

Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
cd "$SiteCode`:"

clear-host

 
function GetInfoPackages()
{
$xPackages = Get-CMPackage | Select-object Name, PkgSourcePath, PackageID
$info = @()
foreach ($xpack in $xPackages) 
    {
    #write-host $xpack.Name
    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
    $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.PkgSourcePath
    $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
    $info += $object
    }
$info
}
 
 
function GetInfoDriverPackage()
{
$xPackages = Get-CMDriverPackage | Select-object Name, PkgSourcePath, PackageID
$info = @()
foreach ($xpack in $xPackages) 
    {
    #write-host $xpack.Name
    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
    $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.PkgSourcePath
    $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
    $info += $object
 
    }
    $info
}
 
 
function GetInfoBootimage()
{
$xPackages = Get-CMBootImage | Select-object Name, PkgSourcePath, PackageID
$info = @()
foreach ($xpack in $xPackages) 
    {
    #write-host $xpack.Name
    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
    $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.PkgSourcePath
    $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
    $info += $object
     
    }
    $info
}
 
 
function GetInfoOSImage()
{
$xPackages = Get-CMOperatingSystemImage | Select-object Name, PkgSourcePath, PackageID
$info = @()
foreach ($xpack in $xPackages) 
    {
    #write-host $xpack.Name
    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
    $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.PkgSourcePath
    $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
    $info += $object
     
    }
    $info
}
 
 
function GetInfoDriver()
{
$xPackages = Get-CMDriver | Select-object LocalizedDisplayName, ContentSourcePath, PackageID
$info = @()
foreach ($xpack in $xPackages) 
    {
    #write-host $xpack.Name
    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.LocalizedDisplayName
    $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.ContentSourcePath
    $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
    $info += $object
     
    }
    $info
}
 
 
function GetInfoSWUpdatePackage()
{
$xPackages = Get-CMSoftwareUpdateDeploymentPackage | Select-object Name, PkgSourcePath, PackageID
$info = @()
foreach ($xpack in $xPackages) 
    {
    #write-host $xpack.Name
    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
    $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.PkgSourcePath
    $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
    $info += $object
     
    }
    $info
}
 
 
# Legacy, only use for ConfigMgr 2012 SP1 
function CM2012SP1OnlyGetInfoApplications {
    
    foreach ($Application in Get-CMApplication) {
  
        $AppMgmt = ($Application.SDMPackageXML).AppMgmtDigest
        $AppName = $AppMgmt.Application.DisplayInfo.FirstChild.Title
 
        foreach ($DeploymentType in $AppMgmt.DeploymentType) {
 
            # Calculate Size and convert to MB
             $size = 0
            foreach ($MyFile in $DeploymentType.Installer.Contents.Content.File) {
                $size += [int]($MyFile.GetAttribute("Size"))
            }
            $size = [math]::truncate($size/1MB)
  
            # Fill properties
            $AppData = @{            
                AppName            = $AppName
                Location           = $DeploymentType.Installer.Contents.Content.Location
                DeploymentTypeName = $DeploymentType.Title.InnerText
                Technology         = $DeploymentType.Installer.Technology
                 ContentId          = $DeploymentType.Installer.Contents.Content.ContentId
           
                SizeMB             = $size
             }                           
 
            # Create object
            $Object = New-Object PSObject -Property $AppData
     
            # Return it
            $Object
        }
    }
 }
 

function GetInfoApplications()
{

$Applications = Get-WmiObject -ComputerName $SiteServer -Namespace root\SMS\site_$SiteCode -class SMS_Application | Where-Object {$_.IsLatest -eq $True}

Write-Output ""
$Applications | ForEach-Object {
    $CheckApplication = [wmi]$_.__PATH
    $CheckApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($CheckApplication.SDMPackageXML,$True)
    $info = @()
    foreach ($CheckDeploymentType in $CheckApplicationXML.DeploymentTypes) {
        $object = New-Object -TypeName PSObject
        $CheckInstaller = $CheckDeploymentType.Installer
        $CheckContents = $CheckInstaller.Contents[0]
        #Write-Output "INFO: Current content path for $($_.LocalizedDisplayName):"
        #Write-Output "$($CheckContents.Location)"
        $object | Add-Member -MemberType NoteProperty  -Name Application -Value $_.LocalizedDisplayName
        $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $CheckContents.Location
        $info += $object

    }
    $info
}
}



# Set maxiumum result to 5000
Set-CMQueryResultMaximum -Maximum 5000
 
# Get the Data
 
# Only works on ConfigMgr 2012 SP1
#Write-host "Applications" -ForegroundColor Yellow
#CM2012SP1OnlyGetInfoApplications | select-object AppName, Location, Technology | Format-Table -AutoSize | Out-String -Width 4096 | Out-File E:\Setup\Objects-Applications.txt

Write-host "Applications" -ForegroundColor Yellow
GetInfoApplications | Format-Table -AutoSize | Out-String -Width 4096 | Out-File E:\Setup\Objects-Applications.txt
 
Write-host "Driver Packages" -ForegroundColor Yellow
GetInfoDriverPackage | Format-Table -AutoSize | Out-String -Width 4096 | Out-File E:\Setup\Objects-DriverPackages.txt
 
Write-host "Drivers" -ForegroundColor Yellow
GetInfoDriver | Format-Table -AutoSize | Out-String -Width 4096 | Out-File E:\Setup\Objects-Drivers.txt

Write-host "Boot Images" -ForegroundColor Yellow
GetInfoBootimage | Format-Table -AutoSize | Out-String -Width 4096 | Out-File E:\Setup\Objects-BootImages.txt

Write-host "OS Images" -ForegroundColor Yellow
GetInfoOSImage  | Format-Table -AutoSize | Out-String -Width 4096 | Out-File E:\Setup\Objects-OSImages.txt
 
Write-host "Software Update Package Groups" -ForegroundColor Yellow
GetInfoSWUpdatePackage | Format-Table -AutoSize | Out-String -Width 4096 | Out-File E:\Setup\Objects-SoftwareUpdatePackages.txt
 
Write-host "Packages" -ForegroundColor Yellow
GetInfoPackages | Format-Table -AutoSize | Out-String -Width 4096 | Out-File E:\Setup\Objects-Packages.txt

Write-Host ""
Write-Host "Check the TXT files in E:\Setup"
Write-Host ""