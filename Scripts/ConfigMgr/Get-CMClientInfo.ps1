$resman = new-object -com "UIResource.UIResourceMgr"; $cacheInfo = $resman.GetCacheInfo()

$ccmcachetotal = ($cacheinfo.TotalSize)/1024
$ccmcachetotal = [math]::Round($ccmcachetotal,2)

$ccmcachefree = ($cacheinfo.FreeSize)/1024
$ccmcacheused = $ccmcachetotal - $ccmcachefree

$ccmcacheused = [math]::Round($ccmcacheused,2)
$ccmcachefree = [math]::Round($ccmcachefree,2)

Write-Host "Total Cache Space: $ccmcachetotal GB"
Write-Host "Used Cache Space: $ccmcacheused GB"
Write-Host "Free Cache Space: $ccmcachefree GB"

$CMClientGUID = (Get-WmiObject -Namespace root\ccm -Class CCM_Client).ClientId
$CMVersion = (Get-WmiObject -NameSpace Root\CCM -Class Sms_Client).clientversion
$CMBGID = (Get-WmiObject -NameSpace Root\CCM\locationservices -Class boundarygroupcache).BoundaryGroupIDs

Write-Host "ConfigMgr Client GUID: $CMClientGUID"
Write-Host "ConfigMgr Client Version: $CMVersion"
Write-Host "ConfigMgr Boundary Group: $CMBGID"
