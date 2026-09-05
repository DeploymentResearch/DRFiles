<#
.SYNOPSIS
    Discovery script for a ConfigMgr configuration baseline that finds stale cache content.
.DESCRIPTION
    Returns the number of cache elements older than the configured age threshold, so the
    baseline can report which clients need cache cleanup.
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
