<#
.SYNOPSIS
    Clears the entire ConfigMgr client cache.
.DESCRIPTION
    Removes every cache element using the UIResourceMgr COM object, including items that have
    been persisted in the cache.
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

# Clear ConfigMgr Cache
$UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
$Cache = $UIResourceMgr.GetCacheInfo()
$CacheElements = $Cache.GetCacheElements() 
foreach ($Element in $CacheElements) { 	$Cache.DeleteCacheElementEx($Element.CacheElementID, $true) }

# Clear BranchCache cache
Clear-BCCache -Force
