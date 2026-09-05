<#
.SYNOPSIS
    Clears both the ConfigMgr client cache and the BranchCache cache.
.DESCRIPTION
    Removes every element from the ConfigMgr cache using the UIResourceMgr COM object, then
    flushes the BranchCache cache, to give a clean starting point for a benchmark run.
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
      1.0.0 - 2021-06-17 - Initial release
#>

# Clear ConfigMgr Cache
$UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
$Cache = $UIResourceMgr.GetCacheInfo()
$CacheElements = $Cache.GetCacheElements() 
foreach ($Element in $CacheElements) { 	$Cache.DeleteCacheElementEx($Element.CacheElementID, $true) }

# Clear BranchCache cache
Clear-BCCache -Force
