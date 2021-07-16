# The Script lists all the content source paths for the following CM objects. 
# Applications 
# Driver Packages  
# Drivers 
# Boot Images 
# OS Images 
# Software Update Package Groups 
# Packages 

$SiteServer = $env:COMPUTERNAME
$SiteCode = "PS1"
$OutputPath = "E:\Setup"

Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
cd "$SiteCode`:"

clear-host

 
function GetInfoPackages(){
$xPackages = Get-CMPackage -Fast | Select-object Name, PkgSourcePath, PackageID
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
 
 
function GetInfoDriverPackage(){
$xPackages = Get-CMDriverPackage -Fast | Select-object Name, PkgSourcePath, PackageID
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
 
 
function GetInfoBootimage(){
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
 
 
function GetInfoOSImage(){
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
 
 
function GetInfoDriver(){
$xPackages = Get-CMDriver -Fast | Select-object LocalizedDisplayName, ContentSourcePath, PackageID
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

 
function GetInfoSWUpdatePackage(){
$xPackages = Get-CMSoftwareUpdateDeploymentPackage  | Select-object Name, PkgSourcePath, PackageID
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

 
function GetInfoApplications(){

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
Write-host "Applications" -ForegroundColor Yellow
GetInfoApplications | Format-Table -AutoSize | Out-String -Width 4096 | Out-File $OutputPath\Objects-Applications.txt
 
Write-host "Driver Packages" -ForegroundColor Yellow
GetInfoDriverPackage | Format-Table -AutoSize | Out-String -Width 4096 | Out-File $OutputPath\Objects-DriverPackages.txt
 
Write-host "Drivers" -ForegroundColor Yellow
GetInfoDriver | Format-Table -AutoSize | Out-String -Width 4096 | Out-File $OutputPath\Objects-Drivers.txt

Write-host "Boot Images" -ForegroundColor Yellow
GetInfoBootimage | Format-Table -AutoSize | Out-String -Width 4096 | Out-File $OutputPath\Objects-BootImages.txt

Write-host "OS Images" -ForegroundColor Yellow
GetInfoOSImage  | Format-Table -AutoSize | Out-String -Width 4096 | Out-File $OutputPath\Objects-OSImages.txt
 
Write-host "Software Update Package Groups" -ForegroundColor Yellow
GetInfoSWUpdatePackage | Format-Table -AutoSize | Out-String -Width 4096 | Out-File $OutputPath\Objects-SoftwareUpdatePackages.txt
 
Write-host "Packages" -ForegroundColor Yellow
GetInfoPackages | Format-Table -AutoSize | Out-String -Width 4096 | Out-File $OutputPath\Objects-Packages.txt

Write-Host ""
Write-Host "Check the TXT files in $OutputPath"
Write-Host ""