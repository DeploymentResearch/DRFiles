# Get ConfigMgr Cache content older than 5 days
try {

    $MinDays = 5
    $UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr -ErrorAction Stop
    $Cache = $UIResourceMgr.GetCacheInfo()

    $CacheElements = ($Cache.GetCacheElements() | Where-Object {[datetime]$_.LastReferenceTime -lt (Get-Date).adddays(-$MinDays)} | Measure-Object -Property CacheElementId).Count
    
}
Catch{
    # No ConfigMgr Client
    Write-Host "No ConfigMgr Client"
}


If($CacheElements)
{
    If($CacheElements -eq 0)
    {
        Write-Host "Compliant"
    }
    Else
    {
        Write-Host "Non-compliant"
    }
}
else
{
    Write-Host "Compliant"
}