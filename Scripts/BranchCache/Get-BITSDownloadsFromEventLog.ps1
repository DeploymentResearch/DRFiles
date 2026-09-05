<#
.SYNOPSIS
    Reports peer to peer efficiency from BITS event log entries.
.DESCRIPTION
    Reads event ID 60 from the BITS operational log, filters for ConfigMgr distribution point
    transfers, and extracts the bytes transferred for each job.
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
      1.0.0 - 2024-12-18 - Initial release
#>

# Check P2P efficiency via the Event Log
$Events = (Get-WinEvent -FilterHashTable @{ LogName='*Bits*'; ID=60 } -ErrorAction SilentlyContinue  ) | 
    Where { ($_.Message -like "*BITS stopped transferring the CCMDTS Job transfer*") -and ($_.Message -like "*SMS_DP*")}| 
    Sort-Object -Descending TimeCreated | foreach {
$_ | Add-Member -MemberType NoteProperty -Name name -Value $_.Properties[1].Value;
$_ | Add-Member -MemberType NoteProperty -Name url -Value $_.Properties[3].Value;
$_ | Add-Member -MemberType NoteProperty -Name bytesTotal -Value $_.Properties[8].Value;
$_ | Add-Member -MemberType NoteProperty -Name bytesTransferred -Value $_.Properties[9].Value;
$_ | Add-Member -MemberType NoteProperty -Name bytesTransferredFromPeer -Value $_.Properties[12].Value -PassThru;
} 
$events | Sort-Object TimeCreated -Descending | Select TimeCreated, url, bytesTotal, bytesTransferred, bytesTransferredFromPeer
