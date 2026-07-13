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
