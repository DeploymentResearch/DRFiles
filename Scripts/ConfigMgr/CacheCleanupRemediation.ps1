# Clear ConfigMgr Cache content older than 5 days
# Including persisted cache items (DeleteCacheElementEx vs. DeleteCacheElement)
try {

    $MinDays = 5
    $UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr -ErrorAction Stop
    $Cache = $UIResourceMgr.GetCacheInfo()

    $CacheElements = $Cache.GetCacheElements() | Where-Object {[datetime]$_.LastReferenceTime -lt (Get-Date).adddays(-$MinDays)}
    foreach ($Element in $CacheElements) { $Cache.DeleteCacheElementEx($Element.CacheElementID, $true) }
    
}
Catch{
    # No ConfigMgr Client
    Write-Host "No ConfigMgr Client"
}

