<#
.SYNOPSIS
    Deletes ConfigMgr cache content older than two weeks.
.DESCRIPTION
    Removes every cache element whose last reference time is older than the configured age
    threshold.
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
      1.0.0 - 2022-01-02 - Initial release
#>

$MinDays = 14
$UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
$Cache = $UIResourceMgr.GetCacheInfo()

$Cache.GetCacheElements() |
where-object {[datetime]$_.LastReferenceTime -lt (get-date).adddays(-$MinDays)} |
foreach {
    $Cache.DeleteCacheElement($_.CacheElementID)
}
