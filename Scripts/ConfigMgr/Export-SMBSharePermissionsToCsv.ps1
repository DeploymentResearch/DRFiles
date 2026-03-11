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