<#
.SYNOPSIS
    Exports SMB share level permissions to a CSV file.
.DESCRIPTION
    Enumerates every non special share and writes the share access rules to a CSV file.
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
$ExportFile = "$ExportPath\SmbSharePermissions.csv"

$shares = Get-SmbShare | Where-Object Special -eq $false

$results = foreach ($share in $shares) {
    foreach ($ace in Get-SmbShareAccess -Name $share.Name) {
        [PSCustomObject]@{
            ShareName     = $share.Name
            Path          = $share.Path
            Description   = $share.Description
            AccountName   = $ace.AccountName
            AccessControl = $ace.AccessControlType
            AccessRight   = $ace.AccessRight
        }
    }
}

$results | Export-Csv -Path $ExportFile -NoTypeInformation
