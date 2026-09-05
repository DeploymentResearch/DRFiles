<#
.SYNOPSIS
    Detects whether the device is on a wired, wireless, or VPN connection.
.DESCRIPTION
    Checks the active network adapters and returns the connection type. Uses Get-CimInstance on
    PowerShell 3.0 and above, and falls back to Get-WmiObject on older versions.
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
      1.0.0 - 2022-01-02 - Initial release
#>

#Get Connection Type
$WirelessConnected = $null
$WiredConnected = $null
$VPNConnected = $null

# Detecting PowerShell version, and call the best cmdlets
if ($PSVersionTable.PSVersion.Major -gt 2)
{
    # Using Get-CimInstance for PowerShell version 3.0 and higher
    $WirelessAdapters =  Get-CimInstance -Namespace "root\WMI" -Class MSNdis_PhysicalMediumType -Filter `
        'NdisPhysicalMediumType = 9'
    $WiredAdapters = Get-CimInstance -Namespace "root\WMI" -Class MSNdis_PhysicalMediumType -Filter ` 
        "NdisPhysicalMediumType = 0 and `
        (NOT InstanceName like '%pangp%') and `
        (NOT InstanceName like '%cisco%') and `
        (NOT InstanceName like '%juniper%') and `
        (NOT InstanceName like '%vpn%') and `
        (NOT InstanceName like 'Hyper-V%') and `
        (NOT InstanceName like 'VMware%') and `
        (NOT InstanceName like 'VirtualBox Host-Only%')" 
    $ConnectedAdapters =  Get-CimInstance -Class win32_NetworkAdapter -Filter `
        'NetConnectionStatus = 2'
    $VPNAdapters =  Get-CimInstance -Class Win32_NetworkAdapterConfiguration -Filter `
        "Description like '%pangp%' ` 
        or Description like '%cisco%'  `
        or Description like '%juniper%' `
        or Description like '%vpn%'" 
}
else
{
    # Needed this script to work on PowerShell 2.0 (don't ask)
    $WirelessAdapters = Get-WmiObject -Namespace "root\WMI" -Class MSNdis_PhysicalMediumType -Filter `
        'NdisPhysicalMediumType = 9'
    $WiredAdapters = Get-WmiObject -Namespace "root\WMI" -Class MSNdis_PhysicalMediumType -Filter `
        "NdisPhysicalMediumType = 0 and `
        (NOT InstanceName like '%pangp%') and `
        (NOT InstanceName like '%cisco%') and `
        (NOT InstanceName like '%juniper%') and `
        (NOT InstanceName like '%vpn%') and `
        (NOT InstanceName like 'Hyper-V%') and `
        (NOT InstanceName like 'VMware%') and `
        (NOT InstanceName like 'VirtualBox Host-Only%')" 
    $ConnectedAdapters = Get-WmiObject -Class win32_NetworkAdapter -Filter `
        'NetConnectionStatus = 2'
    $VPNAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter `
        "Description like '%pangp%' ` 
        or Description like '%cisco%'  `
        or Description like '%juniper%' `
        or Description like '%vpn%'" 
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

Write-Output "Connection type is: $ConnectionType"
