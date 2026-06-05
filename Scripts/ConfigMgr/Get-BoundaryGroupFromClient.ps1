$CMBGIDs = (Get-WmiObject -NameSpace Root\CCM\locationservices -Class boundarygroupcache).BoundaryGroupIDs 
$CMBGID = $CMBGIDs -join " "
$CMBGID
