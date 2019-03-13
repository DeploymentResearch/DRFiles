# Script to enable BranchCache on Windows 7 and Windows 10 clients

$BCPort = "1337"
$BCTTL = "365"

# Reset BranchCache
netsh branchcache reset

# Set BranchCache ConnectPort
REG ADD "HKLM\Software\Microsoft\Windows NT\CurrentVersion\PeerDist\DownloadManager\Peers\Connection" /v ConnectPort /t REG_DWORD /d $BCPort /f

# Set BranchCache ListenPor
REG ADD "HKLM\Software\Microsoft\Windows NT\CurrentVersion\PeerDist\DownloadManager\Peers\Connection" /v ListenPort /t REG_DWORD /d $BCPort /f

# Set BranchCache Cache Time To Live for cached data
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PeerDist\Retrieval" /v SegmentTTL /t REG_DWORD /d $BCTTL /f

# Enable BranchCache in Distributed Mode and to serve peers with content while on battery
netsh branchcache set service mode=distributed serveonbattery=true

# Set BranchCache Cache Size to 50% of disk space
netsh branchcache set cachesize size=50 percent=TRUE

# Set BranchCache service start mode to Automatic
Set-Service –Name peerdistsvc –StartupType Automatic
