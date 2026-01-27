<#
.SYNOPSIS
  This script collects useful health information on distribution points. 

.DESCRIPTION
  This script retrieves information on distribution points into a .CSV file.
  The result of this script produces a CSV that is stored in a network share. There a consolidation script is executed to merge all of the CSV's together. The script uses a path variable 
  called "ExportPath" to export all of the needed infromation.
  
.LINK
  https://P2intSoftware.com

.NOTES
          FileName: DPInfo.ps1
          Contact: @2PintSoftware
          Created: 2019-07-11
          Modified: 2019-07-11

          Version - v1.0.0 - (2019-07-11)
            - Updated to use hash table structure
            - Updated to fix the gateway information
            - updated to fix the DNS to use the .NET class to gather the info

.PARAMETER EXPORTPATH
    The export path variable is required and determines WHERE the content will go. If you would like to remove the parameter it is recommended that you instead change mandatory to FALSE and set the default value of ExportPath
    instead. 

 .Example
  .\DPInfo.PS1 -ExportPath "\\ServerName.DomainName.Com\DPInfo"

#>

[cmdletbinding()]
param(
    [Parameter(HelpMessage = "Enter the path you would like the CSV to be exported to.", Mandatory = $true)]
    [string]$ExportPath
)
begin { }
process {
    
    $ComputerName = ([System.Net.Dns]::GetHostByName(($env:computerName))).Hostname

    # OS Version
    $OS = (Get-WmiObject win32_operatingsystem).caption


    # System Disk 
    $SystemDisk_Free = ((Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'").freespace / 1GB)
    $SystemDisk_Free = [math]::Round($SystemDisk_Free, 2)

    $SystemDisk_Total = ((Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'").size / 1GB)
    $SystemDisk_Total = [math]::Round($SystemDisk_Total, 2)
    $SystemDisk_Total = [decimal]$SystemDisk_Total


    # Content Library Disk 

    $ContentLibraryDriveLetter = Get-PSDrive | Where {$_.Root -match ":"} |% {if (Test-Path ($_.Root + "SCCMContentLib")){$_.Root}}
    $ContentLibraryDriveLetter = $ContentLibraryDriveLetter.TrimEnd('\')

    $ContentLibraryDisk_Free = ((Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$ContentLibraryDriveLetter'").freespace / 1GB)
    $ContentLibraryDisk_Free = [math]::Round($ContentLibraryDisk_Free, 2)

    $ContentLibraryDisk_Total = ((Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$ContentLibraryDriveLetter'").size / 1GB)
    $ContentLibraryDisk_Total = [math]::Round($ContentLibraryDisk_Total, 2)
    $ContentLibraryDisk_Total = [decimal]$ContentLibraryDisk_Total



    IF ($OS -inotlike "*2008*") {
        $BC_BranchCacheServiceStatus = (Get-BCStatus).BranchCacheServiceStatus
        $BC_BranchCacheServiceStartType = (Get-BCStatus).BranchCacheServiceStartType
        $BC_ContentServerIsEnabled = (Get-BCContentServerConfiguration).contentserverisenabled
        $BC_MaxCacheSizeAsPercentageOfDiskVolume = (Get-BCHashCache).MaxCacheSizeAsPercentageOfDiskVolume
        $BC_MaxCacheSizeAsNumberOfBytes = ((Get-BCHashCache).MaxCacheSizeAsNumberOfBytes / 1GB) 
        $BC_MaxCacheSizeAsNumberOfBytes = [math]::Round($BC_MaxCacheSizeAsNumberOfBytes, 4)
        $BC_CurrentActiveCacheSize = ((Get-BCHashCache).CurrentActiveCacheSize / 1GB)
        $BC_CurrentActiveCacheSize = [math]::Round($BC_CurrentActiveCacheSize, 4)
        $BC_PublicationCacheFileDirectoryPath = (Get-BCHashCache).CacheFileDirectoryPath
    }
    ELSE {
        $ShowStatusAll = netsh br show status all
        if (@($ShowStatusAll | Select-String -SimpleMatch -Pattern "Current Status")[0].ToString() -match "Running") {
            $BC_BranchCacheServiceStatus = "Running"
        }
        else {
            $BC_BranchCacheServiceStatus = "Stopped"
        }

        if (@($ShowStatusAll | Select-String -SimpleMatch -Pattern "Service Start Type")[0].ToString() -match "Automatic") {
            $BC_BranchCacheServiceStartType = "Automatic"
        }
        else {
            $BC_BranchCacheServiceStartType = "Manual"
        }

        if (@($ShowStatusAll | Select-String -SimpleMatch -Pattern "Service Mode")[0].ToString() -match "Local Caching") {
            $BC_ContentServerIsEnabled = "Local Caching"
        }
        else {
            $BC_ContentServerIsEnabled = "Disabled"
        }

        $PublicationSectionLineNumber = ($ShowStatusAll | Select-String -Pattern "Publication Cache Status").LineNumber
        $PublicationCacheMaxSizeLine = $ShowStatusAll | Select -Index ($PublicationSectionLineNumber + 1)
        $PublicationCacheMaxSizePercent = ( -split "$PublicationCacheMaxSizeLine")[4].Trim()
        $BC_MaxCacheSizeAsPercentageOfDiskVolume = $PublicationCacheMaxSizePercent.Substring(0, $PublicationCacheMaxSizePercent.Length - 1)

        $PublicationSectionLineNumber = ($ShowStatusAll | Select-String -Pattern "Publication Cache Status").LineNumber
        $PublicationCacheMaxSizeLine = $ShowStatusAll | Select -Index ($PublicationSectionLineNumber + 1)
        $PublicationCacheMaxSizePercent = ( -split "$PublicationCacheMaxSizeLine")[4].Trim()
        $PublicationCacheMaxSizePercent = $PublicationCacheMaxSizePercent.Substring(0, $PublicationCacheMaxSizePercent.Length - 1)
        $PublicationCacheMaxSizePercentNumber = [int]::Parse($PublicationCacheMaxSizePercent)
        $BC_MaxCacheSizeAsNumberOfBytes = ($PublicationCacheMaxSizePercentNumber * $SystemDisk_Total) / 100

        $PublicationSectionLineNumber = ($ShowStatusAll | Select-String -Pattern "Publication Cache Status").LineNumber
        $PublicationActiveCacheSizeLine = $ShowStatusAll | Select -Index ($PublicationSectionLineNumber + 2)
        $PublicationActiveCacheSize = (( -split "$PublicationActiveCacheSizeLine")[5].Trim()) / 1GB
        $BC_CurrentActiveCacheSize = [math]::Round($PublicationActiveCacheSize, 4)
        $BC_CurrentActiveCacheSize = [decimal]$BC_CurrentActiveCacheSize

        $PublicationCacheFileDirectoryPathLine = $ShowStatusAll | Select-String -Pattern "Publication Cache Location"
        $BC_PublicationCacheFileDirectoryPath = ( -split "$PublicationCacheFileDirectoryPathLine")[4].Trim()

    }

    $DefaultGty = ((Get-wmiObject Win32_networkAdapterConfiguration | ? { $_.IPEnabled }).DefaultIPGateway)
    $IPAddress = ((Get-wmiObject Win32_networkAdapterConfiguration | ? { $_.IPEnabled }).IPAddress)

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

    #RAM
    $RAM = ((Get-WMIObject win32_physicalmemory | Measure-Object -Property Capacity -Sum).sum) / 1GB

    #CPUs
    $CPUS = (Get-WMIObject win32_processor | Measure-Object -Property numberoflogicalprocessors -Sum).sum
    $ExportPath = "$($ExportPath)\$($env:computerName).CSV"

# Using New-Object since $HASH = [ordered]@ is not supported on older PowerShell versions
$HASH = New-Object System.Collections.Specialized.OrderedDictionary
$Hash.Add("COMPUTERNAME",$ComputerName)
$Hash.Add("BC_BranchCacheServiceStatus",$BC_BranchCacheServiceStatus)
$Hash.Add("BC_BranchCacheServiceStartType",$BC_BranchCacheServiceStartType)
$Hash.Add("BC_ContentServerIsEnabled",$BC_ContentServerIsEnabled)
$Hash.Add("BC_MaxPublicationCacheSizeAsPercentageOfDiskVolume",$BC_MaxCacheSizeAsPercentageOfDiskVolume)
$Hash.Add("BC_MaxPublicationCacheSize_GB", $BC_MaxCacheSizeAsNumberOfBytes)
$Hash.Add("BC_CurrentActiveCacheSize_GB",$BC_CurrentActiveCacheSize)
$Hash.Add("BC_PublicationCacheFileDirectoryPath",$BC_PublicationCacheFileDirectoryPath)
$Hash.Add("DefaultGty",$DefaultGty[0])
$Hash.Add("IPAddress",$IPAddress[0])
$Hash.Add("CONNECTIONTYPE",$CONNECTIONTYPE)
$Hash.Add("RAM_GB",$RAM)
$Hash.Add("OSVersion",$OS)
$Hash.Add("Number_Of_CPUS",$CPUS)
$Hash.Add("SystemDisk_Free_GB",$SystemDisk_Free)
$Hash.Add("SystemDisk_Total_GB",$SystemDisk_Total)
$Hash.Add("ContentLibraryDisk_Free_GB",$ContentLibraryDisk_Free)
$Hash.Add("ContentLibraryDisk_Total_GB",$ContentLibraryDisk_Total)

    $CSVObject = New-Object -TypeName psobject -Property $HASH
    $CSVObject | Export-Csv -Path $EXPORTPATH -NoTypeInformation
}