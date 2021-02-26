  Get-WinEvent -FilterHashTable @{ LogName='*Bits*'; ID=4 } | % {
    $_ | Add-Member -MemberType NoteProperty -Name jobTitle -Value $_.Properties[1].Value;
    $_ | Add-Member -MemberType NoteProperty -Name bytesTransferred -Value $_.Properties[5].Value;
    $_ | Add-Member -MemberType NoteProperty -Name bytesTransferredFromPeer -Value $_.Properties[6].Value -PassThru;
  } | ? {$_.bytesTransferredFromPeer -gt 0} | Select MachineName, TimeCreated, jobTitle, bytesTransferred, bytesTransferredFromPeer | FT
