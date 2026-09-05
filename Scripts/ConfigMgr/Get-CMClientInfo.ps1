<#
.SYNOPSIS
    Reports ConfigMgr client cache size and free space.
.DESCRIPTION
    Reads total, free, and used cache size from the UIResourceMgr COM object and returns the
    values in megabytes.
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
      1.0.0 - 2021-03-10 - Initial release
#>

$resman = new-object -com "UIResource.UIResourceMgr"; $cacheInfo = $resman.GetCacheInfo()

$ccmcachetotal = ($cacheinfo.TotalSize)/1024
$ccmcachetotal = [math]::Round($ccmcachetotal,2)

$ccmcachefree = ($cacheinfo.FreeSize)/1024
$ccmcacheused = $ccmcachetotal - $ccmcachefree

$ccmcacheused = [math]::Round($ccmcacheused,2)
$ccmcachefree = [math]::Round($ccmcachefree,2)

Write-Host "Total Cache Space: $ccmcachetotal GB"
Write-Host "Used Cache Space: $ccmcacheused GB"
Write-Host "Free Cache Space: $ccmcachefree GB"

$CMClientGUID = (Get-WmiObject -Namespace root\ccm -Class CCM_Client).ClientId
$CMVersion = (Get-WmiObject -NameSpace Root\CCM -Class Sms_Client).clientversion
$CMBGID = (Get-WmiObject -NameSpace Root\CCM\locationservices -Class boundarygroupcache).BoundaryGroupIDs

Write-Host "ConfigMgr Client GUID: $CMClientGUID"
Write-Host "ConfigMgr Client Version: $CMVersion"
Write-Host "ConfigMgr Boundary Group: $CMBGID"
