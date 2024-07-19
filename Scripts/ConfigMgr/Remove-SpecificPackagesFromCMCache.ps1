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
