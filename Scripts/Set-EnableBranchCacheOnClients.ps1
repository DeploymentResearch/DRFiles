<#
.SYNOPSIS
    Enables and configures BranchCache on Windows clients.
.DESCRIPTION
    Resets BranchCache, sets a custom connect port and content time to live, enables distributed
    cache mode, and sets the service to start automatically.
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

# Script to enable BranchCache on Windows 7 and Windows 10 clients

$BCPort = "1337"
$TTL = "365"

# Reset BranchCache
netsh branchcache reset

# Set BranchCache ConnectPort
REG ADD "HKLM\Software\Microsoft\Windows NT\CurrentVersion\PeerDist\DownloadManager\Peers\Connection" /v ConnectPort /t REG_DWORD /d $BCPort /f

# Set BranchCache ListenPor
REG ADD "HKLM\Software\Microsoft\Windows NT\CurrentVersion\PeerDist\DownloadManager\Peers\Connection" /v ListenPort /t REG_DWORD /d $BCPort /f

# Set BranchCache Cache Time To Live for cached data
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PeerDist\Retrieval" /v SegmentTTL /t REG_DWORD /d $TTL /f

# Enable BranchCache in Distributed Mode and to serve peers with content while on battery
netsh branchcache set service mode=distributed serveonbattery=true

# Set BranchCache Cache Size to 50% of disk space
netsh branchcache set cachesize size=50 percent=TRUE

# Set BranchCache service start mode to Automatic
Set-Service –Name peerdistsvc –StartupType Automatic
