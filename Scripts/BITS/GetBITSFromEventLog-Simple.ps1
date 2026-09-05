<#
.SYNOPSIS
    Reads BITS transfer details from the BITS operational event log.
.DESCRIPTION
    Extracts job title and bytes transferred from event ID 4 so BITS download volume can be
    checked without any additional tooling.
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

  Get-WinEvent -FilterHashTable @{ LogName='*Bits*'; ID=4 } | % {
    $_ | Add-Member -MemberType NoteProperty -Name jobTitle -Value $_.Properties[1].Value;
    $_ | Add-Member -MemberType NoteProperty -Name bytesTransferred -Value $_.Properties[5].Value;
    $_ | Add-Member -MemberType NoteProperty -Name bytesTransferredFromPeer -Value $_.Properties[6].Value -PassThru;
  } | ? {$_.bytesTransferredFromPeer -gt 0} | Select MachineName, TimeCreated, jobTitle, bytesTransferred, bytesTransferredFromPeer | FT
