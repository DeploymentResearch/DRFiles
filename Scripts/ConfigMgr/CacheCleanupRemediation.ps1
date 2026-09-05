<#
.SYNOPSIS
    Remediation script that clears stale ConfigMgr cache content.
.DESCRIPTION
    Deletes cache elements older than the configured age threshold, including persisted items,
    by using DeleteCacheElementEx rather than DeleteCacheElement.
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
      1.0.0 - 2026-04-30 - Initial release
#>

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

