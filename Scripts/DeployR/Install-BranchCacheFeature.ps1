<#
.SYNOPSIS
    Installs and configures the BranchCache feature on a DeployR server.
.DESCRIPTION
    Adds the BranchCache Windows feature, then moves and resizes the publication hash cache to
    a dedicated folder.
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
      1.0.0 - 2026-05-31 - Initial release
#>

# Add the BranchCache Feature
Add-WindowsFeature BranchCache

# Moving and resizing the BranchCache Publication Cache
$NewHashFolder = "E:\BCPublicationCache"
$NewHashSize = 5GB

New-Item -Path $NewHashFolder -ItemType Directory
$BCCache = Get-BCStatus
Set-BCCache -Path $BCCache.HashCache.CacheFileDirectoryPath -MoveTo $NewHashFolder -Force

$BCHashCache = Get-BCHashCache
$BCHashCache | Set-BCCache -SizeBytes $NewHashSize -Force
