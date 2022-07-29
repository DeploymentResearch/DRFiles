# Clear ConfigMgr Cache
$UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
$Cache = $UIResourceMgr.GetCacheInfo()
$CacheElements = $Cache.GetCacheElements() 
foreach ($Element in $CacheElements) { 	$Cache.DeleteCacheElementEx($Element.CacheElementID, $true) }

# Clear BranchCache cache
Clear-BCCache -Force