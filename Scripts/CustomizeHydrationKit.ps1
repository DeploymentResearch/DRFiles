<#
.Synopsis
    Script to Customize Johan Arwidmarks Hydration kit for ConfigMgr
.DESCRIPTION
    Created: 2017-04-31
    Version: 1.0

    Author : Matt Benninge
    Twitter: @matbg

    Disclaimer: This script is provided "AS IS" with no warranties, confers no rights and 
    is not supported by the author or DeploymentArtist..

    This version is only tested with the following Hydration Kit:
    http://deploymentresearch.com/Research/Post/580/Hydration-Kit-For-Windows-Server-2016-and-ConfigMgr-Current-Technical-Preview-Branch

    This should be used before the Hydration Kit has been run and directly on the source files.

    Uncomment any value that you do not whish to be customized and that value will be skipped.

.EXAMPLE
    NA
#>
#Requires -RunAsAdministrator 
#Requires -Version 3

#Set the path to the unpacked Hydrationkit
$HydrationSource = "H:\HydrationCMWS2016" #Default = C:\HydrationCMWS2016

#Set the drive where you want the deploymentshare to be created (should be the same drive as above). This and the value above is used if you want to change the drive the Deploymentshare is created on.
$NewMDTPath = "H:" #Default = C:

#Change Domain and OU structure, these values will be changed in all files where applicable
$NewDomainName = "corp.sccmtest.org" #Default = corp.viamonstra.com
$NewMachineOU = "ou=Servers,ou=SCCMTest,dc=corp,dc=sccmtest,dc=org" #Default = ou=Servers,ou=ViaMonstra,dc=corp,dc=viamonstra,dc=com
$NewOrgName = "SCCMTest" #Default = ViaMonstra or VIAMONSTRA
$NewTimeZoneName = "W. Europe Standard Time" #Default = Pacific Standard Time

#Change Admin Passwd
$NewPasswd = "newpass" #Default = P@ssw0rd

#General IP settings, used in all files where applicable, default for all these are on the 192.168.1.x net
$NewOSDAdapter0DNSServerList = "192.168.5.200" #Also used for DC01 ip-adress
$newOSDAdapter0Gateways= "192.168.5.1"
$NewOSDAdapter0SubnetMask= "255.255.255.0"
$NewADSubNet = "192.168.5.0"

#DC01 - set DHCP scope on DC01
$NewDHCPScopes0StartIP="192.168.5.100"
$NewDHCPScopes0EndIP="192.168.5.199"

#Set IP-adress for CM01
$NewCM01OSDAdapter0IPAddressList= "192.168.5.214"

#Set IP-adress for CM02
$NewCM02OSDAdapter0IPAddressList= "192.168.5.215"

#Set IP-adress for MDT01
$NewMDT01OSDAdapter0IPAddressList= "192.168.5.210"

#Set IP-adress for WSUS01
$NewWSUS01OSDAdapter0IPAddressList = "192.168.5.240"


#------------------ Do Not change below this line-----------------#

#Update CreateHydrationDeploymentShare.ps1
If($NewMDTPath){(Get-Content $HydrationSource\Source\CreateHydrationDeploymentShare.ps1).replace('C:', $NewMDTPath) | Set-Content $HydrationSource\Source\CreateHydrationDeploymentShare.ps1}

#Update Customsettings.ini
If($NewTimeZoneName){(Get-Content $HydrationSource\Source\Media\Control\CustomSettings.ini).replace('Pacific Standard Time', $NewTimeZoneName) | Set-Content $HydrationSource\Source\Media\Control\CustomSettings.ini}

#Update Customsettings_CM01.ini
If($NewOSDAdapter0DNSServerList){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_CM01.ini).replace('192.168.1.200', $NewOSDAdapter0DNSServerList) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_CM01.ini}
If($newOSDAdapter0Gateways){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_CM01.ini).replace('192.168.1.1', $newOSDAdapter0Gateways) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_CM01.ini}
If($NewCM01OSDAdapter0IPAddressList){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_CM01.ini).replace('192.168.1.214', $NewCM01OSDAdapter0IPAddressList) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_CM01.ini}
If($NewOSDAdapter0SubnetMask){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_CM01.ini).replace('255.255.255.0', $NewOSDAdapter0SubnetMask) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_CM01.ini}

#Update Customsettings_CM02.ini
If($NewOSDAdapter0DNSServerList){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_CM02.ini).replace('192.168.1.200', $NewOSDAdapter0DNSServerList) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_CM02.ini}
If($newOSDAdapter0Gateways){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_CM02.ini).replace('192.168.1.1', $newOSDAdapter0Gateways) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_CM02.ini}
If($NewCM02OSDAdapter0IPAddressList){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_CM02.ini).replace('192.168.1.215', $NewCM02OSDAdapter0IPAddressList) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_CM02.ini}
If($NewOSDAdapter0SubnetMask){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_CM02.ini).replace('255.255.255.0', $NewOSDAdapter0SubnetMask) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_CM02.ini}

#Update Customsettings_DC01.ini
If($NewOSDAdapter0DNSServerList){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_DC01.ini).replace('192.168.1.200', $NewOSDAdapter0DNSServerList) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_DC01.ini}
If($newOSDAdapter0Gateways){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_DC01.ini).replace('192.168.1.1', $newOSDAdapter0Gateways) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_DC01.ini}
If($NewOSDAdapter0SubnetMask){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_DC01.ini).replace('255.255.255.0', $NewOSDAdapter0SubnetMask) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_DC01.ini}
If($NewADSubNet){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_DC01.ini).replace('192.168.1.0', $NewADSubNet) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_DC01.ini}
If($NewDHCPScopes0StartIP){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_DC01.ini).replace('192.168.1.100', $NewDHCPScopes0StartIP) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_DC01.ini}
If($NewDHCPScopes0EndIP){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_DC01.ini).replace('192.168.1.199', $NewDHCPScopes0EndIP) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_DC01.ini}


#Update Customsettings_MDT01.ini
If($NewOSDAdapter0DNSServerList){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_MDT01.ini).replace('192.168.1.200', $NewOSDAdapter0DNSServerList) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_MDT01.ini}
If($newOSDAdapter0Gateways){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_MDT01.ini).replace('192.168.1.1', $newOSDAdapter0Gateways) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_MDT01.ini}
If($NewMDT01OSDAdapter0IPAddressList){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_MDT01.ini).replace('192.168.1.210', $NewMDT01OSDAdapter0IPAddressList) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_MDT01.ini}
If($NewOSDAdapter0SubnetMask){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_MDT01.ini).replace('255.255.255.0', $NewOSDAdapter0SubnetMask) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_MDT01.ini}

#Update Customsettings_WSUS01.ini
If($NewOSDAdapter0DNSServerList){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_WSUS01.ini).replace('192.168.1.200', $NewOSDAdapter0DNSServerList) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_WSUS01.ini}
If($newOSDAdapter0Gateways){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_WSUS01.ini).replace('192.168.1.1', $newOSDAdapter0Gateways) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_WSUS01.ini}
If($NewWSUS01OSDAdapter0IPAddressList){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_WSUS01.ini).replace('192.168.1.240', $NewWSUS01OSDAdapter0IPAddressList) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_WSUS01.ini}
If($NewOSDAdapter0SubnetMask){(Get-Content $HydrationSource\Source\Media\Control\Customsettings_WSUS01.ini).replace('255.255.255.0', $NewOSDAdapter0SubnetMask) | Set-Content $HydrationSource\Source\Media\Control\Customsettings_WSUS01.ini}

#Update Scripts
If($NewADSubNet){(Get-Content "$($HydrationSource)\Source\Hydration\Applications\Configure - Create AD Subnets\\Configure-CreateADSubnets.ps1").replace('192.168.1.0', $NewADSubNet) | Set-Content "$($HydrationSource)\Source\Hydration\Applications\Configure - Create AD Subnets\\Configure-CreateADSubnets.ps1"}


#Update Domain Name
If($NewMachineOU)
{
    $NewMachineOUfiles = Get-ChildItem -recurse -Path $HydrationSource\Source | Select-String -pattern 'ou=Servers,ou=ViaMonstra,dc=corp,dc=viamonstra,dc=com' | group path | select name
    foreach($NewMachineOUfile in $NewMachineOUfiles)
    {
        (Get-Content $NewMachineOUfile.Name).replace('ou=Servers,ou=ViaMonstra,dc=corp,dc=viamonstra,dc=com', $NewMachineOU) | Set-Content $NewMachineOUfile.Name
    }
}

#Update Domain Name
If($NewDomainName)
{
    $NewDomainNamefiles = Get-ChildItem -recurse -Path $HydrationSource\Source | Select-String -pattern 'corp.viamonstra.com' | group path | select name
    foreach($NewDomainNamefile in $NewDomainNamefiles)
    {
        (Get-Content $NewDomainNamefile.Name).replace('corp.viamonstra.com', $NewDomainName) | Set-Content $NewDomainNamefile.Name
    }
}

#Update ORGName
If($NewOrgName)
{
    $NewOrgNamefiles = Get-ChildItem -recurse -Path $HydrationSource\Source | Select-String -pattern "ViaMonstra" | group path | select name
    foreach($NewOrgNamefile in $NewOrgNamefiles)
    {
        (Get-Content $NewOrgNamefile.Name).replace('ViaMonstra', $NewOrgName) | Set-Content $NewOrgNamefile.Name
        (Get-Content $NewOrgNamefile.Name).replace('VIAMONSTRA', $NewOrgName.ToUpper()) | Set-Content $NewOrgNamefile.Name
    }
}

#Update password
If($NewPasswd)
{
    $passwdfiles = Get-ChildItem -recurse -Path $HydrationSource\Source | Select-String -pattern 'P@ssw0rd' | group path | select name
    foreach($passwdfile in $passwdfiles)
    {
        (Get-Content $passwdfile.Name).replace('P@ssw0rd', $NewPasswd) | Set-Content $passwdfile.Name
    }
}