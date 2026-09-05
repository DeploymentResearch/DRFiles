<#
.SYNOPSIS
    Lists the contents of the ConfigMgr client cache.
.DESCRIPTION
    Reports the number of cache elements and their details using the UIResourceMgr COM object,
    and exits early when the cache is empty.
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
      1.0.0 - 2021-12-12 - Initial release
#>

$UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
$Cache = $UIResourceMgr.GetCacheInfo()
$CacheElements = $Cache.GetCacheElements() 

If (!($CacheElements)){Write-Output "Nothing in the cache, aborting...";Break}
Write-Output "Number of elements in the cache are: $(($CacheElements | Measure-Object).count)"

foreach ($Element in $CacheElements){
        Write-Output "ContentId is: $($Element.ContentId)"
        Write-Output "ContentVersion is: $($Element.ContentVersion)"
        Write-Output "Location is: $($Element.Location)"
        Write-Output "LastReferenceTime is: $($Element.LastReferenceTime)"
        Write-Output "ReferenceCount is: $($Element.ReferenceCount)"
        Write-Output "ContentSize is: $($Element.ContentSize)"
        Write-Output "CacheElementId is: $($Element.CacheElementId)"
        Write-Output ""
}


# read the next available Cache ID (next folder name) using WMI
$CacheConfig = Get-CimInstance -Namespace "ROOT\ccm\SoftMgmtAgent" -ClassName CacheConfig 
Write-Output "NextAvailableID is: $($CacheConfig.NextAvailableID)"

