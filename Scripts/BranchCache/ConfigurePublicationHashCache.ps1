<#
.SYNOPSIS
    Moves and resizes the BranchCache publication hash cache.
.DESCRIPTION
    Relocates the hash cache to a dedicated folder and sets a larger size, which is what a
    ConfigMgr distribution point normally needs.
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

# Configure Publication Hash Cache
$NewHashFolder = "E:\BCPublicationCache"
$NewHashSize = 10GB

New-Item -Path $NewHashFolder -ItemType Directory
$BCCache = Get-BCStatus
Set-BCCache -Path $BCCache.HashCache.CacheFileDirectoryPath -MoveTo $NewHashFolder -Force

$BCHashCache = Get-BCHashCache
$BCHashCache | Set-BCCache -SizeBytes $NewHashSize -Force
