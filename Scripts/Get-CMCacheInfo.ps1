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
      1.0.0 - 2022-01-02 - Initial release
#>

$resman = new-object -com "UIResource.UIResourceMgr"; $cacheInfo = $resman.GetCacheInfo()

$ccmcachetotal = ($cacheinfo.TotalSize)/1024
$ccmcachetotal = [math]::Round($ccmcachetotal,2)

$ccmcachefree = ($cacheinfo.FreeSize)/1024
$ccmcachefree = [math]::Round($ccmcachefree,2)

$ccmcacheused = $ccmcachetotal - $ccmcachefree
$ccmcacheused = [math]::Round($ccmcacheused,2)

Write-Host "Total Cache Space: $ccmcachetotal GB"
Write-Host "Used Cache Space: $ccmcacheused GB"
Write-Host "Free Cache Space: $ccmcachefree GB"
