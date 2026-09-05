<#
.SYNOPSIS
    Exports SMB share and NTFS permissions to a CSV file.
.DESCRIPTION
    Enumerates every non special share, reads both the share level access rules and the NTFS
    access control list on the underlying path, and exports the combined result.
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
      1.0.0 - 2026-03-11 - Initial release
#>

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
