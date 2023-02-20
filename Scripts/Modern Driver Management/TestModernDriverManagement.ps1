#
# Test Admin Service
#

$SMSProvider = "cm01.corp.viamonstra.com" 
$Cred = Get-Credential 

# Access AdminService metadata
$AdminServiceUri = "https://$SMSProvider/AdminService/v1.0/$metadata"
Invoke-RestMethod -Method Get -Uri $AdminServiceUri -Credential $Cred | Select-Object -ExpandProperty Value | Sort-Object Name

# Get info from a device
$AdminServiceUri = "https://$SMSProvider/AdminService/wmi/SMS_R_System(16778039)"
Invoke-RestMethod -Method Get -Uri $AdminServiceUri -Credential $Cred | Select-Object -ExpandProperty Value | Select Name, build, OperatingSystemNameandVersion

# Get all packages
$AdminServiceUri = "https://$SMSProvider/AdminService/wmi/SMS_Package"
Invoke-RestMethod -Method Get -Uri $AdminServiceUri -Credential $Cred | Select-Object -ExpandProperty Value | Select Name, PackageID

# Get all driver packages
$AdminServiceUri = "https://$SMSProvider/AdminService/wmi/SMS_Package?`$Filter=contains(Name,'Drivers')"
Invoke-RestMethod -Method Get -Uri $AdminServiceUri -Credential $Cred | Select-Object -ExpandProperty Value | Select Name, PackageID, Description

#
# Test Invoke-CMApplyDriverPackage.ps1
#

Set-Location "E:\Sources\OSD\Tools\Modern Driver Management"
$SMSProvider = "cm01.corp.viamonstra.com"	
$Cred = Get-Credential 
$Password = $Cred.GetNetworkCredential().Password
$UserName = "$($Cred.GetNetworkCredential().Domain)\$($Cred.GetNetworkCredential().UserName)"

# Check Dell Optiplex 7050
.\Invoke-CMApplyDriverPackage.ps1 -DebugMode -Endpoint $SMSProvider -UserName $UserName -Password $Password -TargetOSVersion 21H2 -TargetOSName 'Windows 10' -Manufacturer Dell -ComputerModel "Optiplex 7050" -SystemSKU "07A1" -Verbose

# Check the  log
& cmtrace.exe "C:\Windows\Temp\ApplyDriverPackage.log"






# Get all Driver Packages
# https://cm01.corp.viamonstra.com/AdminService/wmi/SMS_Package?$filter=contains(Name,'Drivers')
