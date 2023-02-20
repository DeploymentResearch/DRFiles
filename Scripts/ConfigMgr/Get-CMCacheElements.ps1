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

