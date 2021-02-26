# Configure Publication Hash Cache
$NewHashFolder = "E:\BCPublicationCache"
$NewHashSize = 10GB

New-Item -Path $NewHashFolder -ItemType Directory
$BCCache = Get-BCStatus
Set-BCCache -Path $BCCache.HashCache.CacheFileDirectoryPath -MoveTo $NewHashFolder -Force

$BCHashCache = Get-BCHashCache
$BCHashCache | Set-BCCache -SizeBytes $NewHashSize -Force