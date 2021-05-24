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