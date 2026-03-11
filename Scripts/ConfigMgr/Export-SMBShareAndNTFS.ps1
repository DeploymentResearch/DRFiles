$ExportPath = "C:\Temp"
$ExportFile = "$ExportPath\SmbShareAndNTFS.csv"


$shares = Get-SmbShare | Where-Object { $_.Special -eq $false -and $_.Path }

$results = foreach ($share in $shares) {
    $ntfsAcl = Get-Acl -Path $share.Path -ErrorAction SilentlyContinue

    foreach ($shareAce in Get-SmbShareAccess -Name $share.Name) {
        if ($ntfsAcl) {
            foreach ($ntfsAce in $ntfsAcl.Access) {
                [PSCustomObject]@{
                    ShareName         = $share.Name
                    SharePath         = $share.Path
                    ShareAccount      = $shareAce.AccountName
                    ShareAccessType   = $shareAce.AccessControlType
                    ShareAccessRight  = $shareAce.AccessRight
                    NTFSIdentity      = $ntfsAce.IdentityReference
                    NTFSRights        = $ntfsAce.FileSystemRights
                    NTFSType          = $ntfsAce.AccessControlType
                    Inherited         = $ntfsAce.IsInherited
                }
            }
        }
        else {
            [PSCustomObject]@{
                ShareName         = $share.Name
                SharePath         = $share.Path
                ShareAccount      = $shareAce.AccountName
                ShareAccessType   = $shareAce.AccessControlType
                ShareAccessRight  = $shareAce.AccessRight
                NTFSIdentity      = $null
                NTFSRights        = $null
                NTFSType          = $null
                Inherited         = $null
            }
        }
    }
}

$results | Export-Csv -Path $ExportFile -NoTypeInformation