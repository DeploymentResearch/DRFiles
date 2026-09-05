<#
.SYNOPSIS
    Removes a specific package from the ConfigMgr client cache.
.DESCRIPTION
    Lists the cache elements, then deletes the element matching the specified content ID rather
    than flushing the entire cache.
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
      1.0.0 - 2024-07-19 - Initial release
#>

$resman = New-Object -ComObject "UIResource.UIResourceMgr"
$cacheInfo = $resman.GetCacheInfo()

# List all packages
$cacheinfo.GetCacheElements()  

# Delete specific pacakge
$ContentID = "b74e8bb6-36ac-409c-8e9f-54127fe01ae0"
$cacheinfo.GetCacheElements() | 
    Where-Object {$_.ContentId -eq $ContentID } |
    where-object {$_.LastReferenceTime -lt (get-date).AddDays(-7)} | 
    foreach {
        $cacheInfo.DeleteCacheElement($_.CacheElementID)
    }
