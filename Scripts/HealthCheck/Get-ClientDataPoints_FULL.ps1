<#
.SYNOPSIS
  This script collects information on client computers for machines with 2Pint StifleR and BranchCache.

.DESCRIPTION
  This script is designed to work for a specific customer at this point however it can be generalized by removing or adding a couple of fields specific to site information. 
  The result of this script produces a CSV that is stored in a network share. There a consolidation script is executed to merge all of the CSV's together. 
  
.LINK
  https://P2intSoftware.com

.NOTES
          FileName: CollectBranchcacheClientInfo.ps1
          Authors: Todd Anderson, Jordan Benzing, and Johan Arwidmark
          Contact: @2PintSoftware
          Created: 2019-07-11
          Modified: 2019-07-11

          Version - v1.0.1 - (2019-09-17)

.Example
  .\CollectBranchCacheClientInfo.ps1

#>

$ExportPath = "\\cm01.corp.viamonstra.com\HealthCheck$\Clients"
$computername = $env:computername

# Get date
$Date = Get-Date -Format "dd/MM/yyyy"


#BranchCache Info
$BC_BranchCacheServiceStatus = (Get-BCStatus).BranchCacheServiceStatus
$BC_BranchCacheServiceStartType = (Get-BCStatus).BranchCacheServiceStartType
$BC_ContentDownloadListenPort = (Get-BCNetworkConfiguration).ContentDownloadListenPort
$BC_CurrentClientMode = (Get-BCClientConfiguration).CurrentClientMode
$BC_PreferredContentInformationVersion = (Get-BCClientConfiguration).PreferredContentInformationVersion
$BC_MaxCacheSizeAsPercentageOfDiskVolume = (Get-BCDataCache).MaxCacheSizeAsPercentageOfDiskVolume

$BC_MaxCacheSizeInGB = ((Get-BCDataCache).MaxCacheSizeAsNumberOfBytes/1GB) 
$BC_MaxCacheSizeInGB = [math]::Round($BC_MaxCacheSizeInGB,2)

$BC_CurrentSizeOnDiskInGB = ((Get-BCDataCache).CurrentSizeOnDiskAsNumberOfBytes/1GB)
$BC_CurrentSizeOnDiskInGB = [math]::Round($BC_CurrentSizeOnDiskInGB,2)

$BC_CurrentActiveCacheSizeInGB = ((Get-BCDataCache).CurrentActiveCacheSize/1GB)
$BC_CurrentActiveCacheSizeInGB = [math]::Round($BC_CurrentActiveCacheSizeInGB,2)


#IP Info
$DefaultGty=((Get-wmiObject Win32_networkAdapterConfiguration | Where-Object{$_.IPEnabled}).DefaultIPGateway)
$IPAddress=((Get-wmiObject Win32_networkAdapterConfiguration | Where-Object{$_.IPEnabled}).IPAddress)

    #Get Connection Type
    $WirelessConnected = $null
    $WiredConnected = $null
    $VPNConnected = $null

    # Detecting PowerShell version, and call the best cmdlets
    if ($PSVersionTable.PSVersion.Major -gt 2)
    {
        # PowerShell 3.0 and above supports Get-CimInstance, and PowerShell 6 and above does not support Get-WmiObject, so using Get-CimInstance.
        $WirelessAdapters =  Get-CimInstance -Namespace "root\WMI" -Class MSNdis_PhysicalMediumType -Filter 'NdisPhysicalMediumType = 9'
        $WiredAdapters =  Get-CimInstance -Namespace "root\WMI" -Class MSNdis_PhysicalMediumType -Filter "NdisPhysicalMediumType = 0 and NOT InstanceName like '%pangp%' and NOT InstanceName like '%cisco%' and NOT InstanceName like '%juniper%' and NOT InstanceName like '%vpn%' and NOT InstanceName like 'Hyper-V%' and NOT InstanceName like 'VMware%' and NOT InstanceName like 'VirtualBox Host-Only%'" 
        $ConnectedAdapters =  Get-CimInstance -Class win32_NetworkAdapter -Filter 'NetConnectionStatus = 2'
        $VPNAdapters =  Get-CimInstance -Class Win32_NetworkAdapterConfiguration -Filter "Description like '%pangp%' or Description like '%cisco%' or Description like '%juniper%' or Description like '%vpn%'" 
    }
    else
    {
        # Needed this script to work on PowerShell 2.0 (don't ask)
        $WirelessAdapters = Get-WmiObject -Namespace "root\WMI" -Class MSNdis_PhysicalMediumType -Filter 'NdisPhysicalMediumType = 9'
        $WiredAdapters = Get-WmiObject -Namespace "root\WMI" -Class MSNdis_PhysicalMediumType -Filter "NdisPhysicalMediumType = 0 and NOT InstanceName like '%pangp%' and NOT InstanceName like '%cisco%' and NOT InstanceName like '%juniper%' and NOT InstanceName like '%vpn%' and NOT InstanceName like 'Hyper-V%' and NOT InstanceName like 'VMware%' and NOT InstanceName like 'VirtualBox Host-Only%'"
        $ConnectedAdapters = Get-WmiObject -Class win32_NetworkAdapter -Filter 'NetConnectionStatus = 2'
        $VPNAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "Description like '%pangp%' or Description like '%cisco%' or Description like '%juniper%' or Description like '%vpn%'" 
    }


    Foreach($Adapter in $ConnectedAdapters) {
        If($WirelessAdapters.InstanceName -contains $Adapter.Name)
        {
            $WirelessConnected = $true
        }
    }

    Foreach($Adapter in $ConnectedAdapters) {
        If($WiredAdapters.InstanceName -contains $Adapter.Name)
        {
            $WiredConnected = $true
        }
    }

    Foreach($Adapter in $ConnectedAdapters) {
        If($VPNAdapters.Index -contains $Adapter.DeviceID)
        {
            $VPNConnected = $true
        }
    }

    If(($WirelessConnected -ne $true) -and ($WiredConnected -eq $true)){ $ConnectionType="WIRED"}
    If(($WirelessConnected -eq $true) -and ($WiredConnected -eq $true)){$ConnectionType="WIRED AND WIRELESS"}
    If(($WirelessConnected -eq $true) -and ($WiredConnected -ne $true)){$ConnectionType="WIRELESS"}
    If($VPNConnected -eq $true){$ConnectionType="VPN"}

#Disk Info
$Disk_Free = ((Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'").freespace/1GB)
$Disk_Free = [math]::Round($Disk_Free,2)
$Disk_Total = ((Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'").size/1GB)
$Disk_Total = [math]::Round($Disk_Total,2)

#RAM
$RAM = ((Get-WmiObject win32_physicalmemory | Measure-Object -Property Capacity -Sum).sum)/1GB

#OS
$OS = (Get-WmiObject win32_operatingsystem).version


# Region ConfigMgrInfo

If(Test-Path -Path "C:\Windows\CCM\logs\"){
    $resman = new-object -com "UIResource.UIResourceMgr"; $cacheInfo = $resman.GetCacheInfo()
    $ccmcachefree = ($cacheinfo.FreeSize)/1024
    $ccmcachetotal = ($cacheinfo.TotalSize)/1024
    $ccmcacheused = $ccmcachetotal - $ccmcachefree
    $ccmcacheused = [math]::Round($ccmcacheused,2)
    $ccmcachetotal = [math]::Round($ccmcachetotal,2)
    $CMVersion = (Get-WmiObject -NameSpace Root\CCM -Class Sms_Client).clientversion
    $CMBGID = (Get-WmiObject -NameSpace Root\CCM\locationservices -Class boundarygroupcache).BoundaryGroupIDs

    #Last DP
    $searchtext = " successfully processed download completion."
    $file = "c:\Windows\CCM\Logs\ContentTransferManager.log"
    if (Test-Path $file){
        if (Get-Content $file | Select-String -Pattern $searchtext -Quiet){
            $StrResult = (Get-Content $file | Select-String -Pattern $searchtext | Select-Object -Last 1).ToString()
            if($StrResult){
                $LastCTMid = $StrResult.SubString(1,$StrResult.IndexOf('}')) | ForEach-Object{$_.Replace($_.SubString(0,$_.IndexOf('{')),'')}
            }
            
            $searchtext2 = "CTM job $LastCTMid switched to location "
            $StrResult2 = ""
            $StrResult2 = (Get-Content $file | Select-String -Pattern $searchtext2 -SimpleMatch | Select-Object -Last 1)
                     
            If($StrResult2){
                $StrResult2 = $StrResult2.ToString()
                $LastDP = $StrResult2.Split('/')[2]}
            Else{
                
                $searchtext3 = "CTM job $LastCTMid (corresponding DTS job {"
                $StrResult3 = ""
                $StrResult3 = (Get-Content $file | Select-String -Pattern $searchtext3 -SimpleMatch | Select-Object -Last 1)
                If($StrResult3){
                    $StrResult3 = $StrResult3.ToString()
                    $LastDP = $StrResult3.Split('/')[2]
                }
            }
        }
    }
}


If(!(Test-Path -Path "C:\Windows\CCM\logs\")){
  $ccmcachefree = "NA"
  $ccmcachetotal = "NA"
  $ccmcacheused = "NA"
  $ccmcacheused = "NA"
  $ccmcachetotal = "NA"
  $CMVersion = "NA"
  $CMBGID = "NA"
  $LastDP = "NA"
}
#EndRegion ConfigMgrInfo



#Region StifleR

#Set the path to where StifleR config file is installed.
$path = "C:\Program Files\2Pint Software\StifleR Client\StifleR.ClientApp.exe.config"

if(Test-Path -Path $path){
    $xml = [xml](Get-Content $path)
    $timer = $xml.Configuration.appsettings.add | Where-Object {$_.key -eq "UpdateRulesTimerInSec"} | Select-Object -ExpandProperty value
    $StiflerServers = $xml.Configuration.appsettings.add | Where-Object {$_.key -eq "StiflerServers"} | Select-Object -ExpandProperty value
    $rulezurl = $xml.Configuration.appsettings.add | Where-Object {$_.key -eq "StifleRulezURL"} | Select-Object -ExpandProperty value
    $dblog = $xml.Configuration.appsettings.add | Where-Object {$_.key -eq "EnableDebugLog"} | Select-Object -ExpandProperty value
    $StiflerService = (Get-Service -name "StifleRClient").Status
    $Stiflerversion = (Get-WmiObject -query "select version from win32reg_addremoveprograms where (displayname like '%Stifler%')").version

    $LastStifleRCorruptConfigFileQuery = @"
    <QueryList>
      <Query Id="0" Path="Application">
        <Select Path="Application">*[System[(EventID=1026)]]</Select>
      </Query>
    </QueryList>
    "@
    $LastStifleRCorruptConfigFile = (Get-WinEvent -FilterXml $LastStifleRCorruptConfigFileQuery | Where-Object {$_.Message -match "StifleR.ClientApp.exe"} | Sort -Descending TimeCreated | Select -first 1 TimeCreated,ID,Message).TimeCreated

    $LastStifleRClientAppCrashQuery = @"
    <QueryList>
      <Query Id="0" Path="Application">
        <Select Path="Application">*[System[(EventID=1001)]]</Select>
      </Query>
    </QueryList>
    "@
    $LastStifleRClientAppCrash = (Get-WinEvent -FilterXml $LastStifleRClientAppCrashQuery  | Where-Object {$_.Message -match "StifleR.ClientApp.exe"} | Sort -Descending TimeCreated | Select -first 1 TimeCreated,ID,Message).TimeCreated

    $StifleRLastConnectedFromEventLogQuery = @"
    <QueryList>
      <Query Id="0" Path="StifleR">
        <Select Path="StifleR">*[System[(EventID=7684)]]</Select>
      </Query>
    </QueryList>
"@

    $StifleRLastConnectedFromEventLog = (Get-WinEvent -FilterXml $StifleRLastConnectedFromEventLogQuery | Sort -Descending TimeCreated | Select -first 1 TimeCreated,ID,Message).TimeCreated

    $StifleRLastConnectedFromRegistry = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\2Pint Software\StifleR\Client\Connection" -Name "LastConnectionSuccess"


    $StiflerConfigItems = ($xml.Configuration.appsettings.add | Measure-Object).count
    
    # four lines for the Filter driver status
    $FilterStatusAll = sc.exe query type= driver
    $StiflersLineNumber = ($FilterStatusAll | Select-String -Pattern "SERVICE_NAME: stiflers").LineNumber
    $StiflersStatusLine = $FilterStatusAll | Select -Index ($stiflerslinenumber + 2)
    $stiflerFilterService = ( -split "$StiflersStatusLine")[3].Trim()

    $stiflerFilterVersion = (Get-Item "C:\Windows\System32\Drivers\stiflers.sys").VersionInfo.ProductVersion

}
if(!(Test-Path -Path $path)){
    #Set all returned variables to NA
    $timer = "NA"
    $StiflerServers = "NA"
    $rulezurl = "NA"
    $dblog = "NA"
    $StiflerService = "NA"
    $Stiflerversion = "NA"
    $StifleRLastConnectedFromRegistry = "NA"
    $StifleRLastConnectedFromEventLog = "NA"
    $StiflerConfigItems = "NA"
    $stiflerFilterService = "NA"
    $stiflerFilterVersion = "NA"
}

#EndRegion StifleR

# DO Check
$DOGroupID = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization").dogroupid
$DOdlmode = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization").dodownloadmode


# Check C:\Windows\Temp folder
$TempFolder = "C:\Windows\Temp"
$TempFilesCount = ( Get-ChildItem $TempFolder | Measure-Object ).Count
$TempFolderSizeInGB = "{0}" -f ((Get-ChildItem $TempFolder -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1GB)
$TempFolderSizeInGB = [math]::Round($TempFolderSizeInGB,4)

# Check .NET Framework version
$Version = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
Get-ItemProperty -name Release -EA 0 |
#Where { $_.PSChildName -match '^(?![SW])\p{L}'} |
Where { $_.PSChildName -eq "Full"} |
Select PSChildName, Version, Release, @{
  name="Product"
  expression={
      switch -regex ($_.Release) {
        "378389" { [Version]"4.5" }
        "378675|378758" { [Version]"4.5.1" }
        "379893" { [Version]"4.5.2" }
        "393295|393297" { [Version]"4.6" }
        "394254|394271" { [Version]"4.6.1" }
        "394802|394806" { [Version]"4.6.2" }
        "460798|460805" { [Version]"4.7" }
        "461308|461310" { [Version]"4.7.1" }
        "461808|461814" { [Version]"4.7.2" }
        "528040|528049" { [Version]"4.8" }
        {$_ -gt 528049} { [Version]"Undocumented version (> 4.8), please update script" }
      }
    }
}

$FrameworkVersion = $Version.Product.ToString() 


$ExportPath = "$($ExportPath)\$($computername).CSV"
if(test-path -Path $EXPORTPATH) {
    remove-item -path $EXPORTPATH
    }

$HASH = New-Object System.Collections.Specialized.OrderedDictionary
$Hash.Add("COMPUTERNAME",$computername)
$Hash.Add("Date_Collected",$Date)
$Hash.Add("BC_ServiceStatus", $BC_BranchCacheServiceStatus)
$Hash.Add("BC_ServiceStartType", $BC_BranchCacheServiceStartType)
$Hash.Add("BC_ContentDownloadListenPort", $BC_ContentDownloadListenPort)
$Hash.Add("BC_CurrentClientMode", $BC_CurrentClientMode)
$Hash.Add("BC_PreferredVersion", $BC_PreferredContentInformationVersion)
$Hash.Add("BC_MaxCacheSizeAsPercentage", $BC_MaxCacheSizeAsPercentageOfDiskVolume)
$Hash.Add("BC_MaxCacheSizeInGB", $BC_MaxCacheSizeInGB)
$Hash.Add("BC_CurrentSizeOnDiskInGB", $BC_CurrentSizeOnDiskInGB)
$Hash.Add("BC_CurrentActiveCacheSizeInGB", $BC_CurrentActiveCacheSizeInGB)
$Hash.Add("DefaultGty", $DefaultGty[0])
$Hash.Add("IPAddress", $IPAddress[0])
$Hash.Add("CONNECTIONTYPE", $ConnectionType)
$Hash.Add("Disk_Free", $Disk_Free)
$Hash.Add("Disk_Total", $Disk_Total)
$Hash.Add("RAM", $RAM)
$Hash.Add("OS", $OS)
$Hash.Add("ccmcachetotal", $ccmcachetotal)
$Hash.Add("ccmcacheused", $ccmcacheused)
$Hash.Add("CMVersion",$CMVersion)
$Hash.Add("CMBGID", $CMBGID[0])
$Hash.Add("LastDP", $LastDP)
$Hash.Add("StiflerRulesTimer", $timer)
$Hash.Add("StiflerServers", $StiflerServers)
$Hash.Add("StiflerRulesUrl", $rulezurl)
$Hash.Add("StiflerDebuglog", $dblog)
$Hash.Add("StiflerService", $StiflerService)
$Hash.Add("Stiflerversion", $Stiflerversion)
$Hash.Add("StifleRLastConnectedFromRegistry", $StifleRLastConnectedFromRegistry)
$Hash.Add("StifleRLastConnectedFromEventLog", $StifleRLastConnectedFromEventLog)
$Hash.Add("StiflerConfigItems", $StiflerConfigItems)
$Hash.Add("stiflerFilterService", $stiflerFilterService)
$Hash.Add("stiflerFilterVersion", $stiflerFilterVersion)
$Hash.Add("DOGroupID", $DOGroupID)
$Hash.Add("DOdlmode", $DOdlmode)
$Hash.Add("TempFilesCount", $TempFilesCount)
$Hash.Add("TempFolderSizeInGB", $TempFolderSizeInGB)
$Hash.Add("NETFrameworkVersion", $FrameworkVersion)

$CSVObject = New-Object -TypeName psobject -Property $HASH
$CSVObject | Export-Csv -Path $EXPORTPATH -NoTypeInformation

Return 0