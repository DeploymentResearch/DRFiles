$ExportPath = "C:\Temp8"
$ExportFile = "$ExportPath\SmbShares.csv"

If (!(Test-Path $ExportPath)){New-Item -Path $ExportPath -ItemType Directory -Force  }

Get-SmbShare |
    Where-Object Special -eq $false |
    Select-Object Name, Path, Description, ScopeName, FolderEnumerationMode, CachingMode, ConcurrentUserLimit |
    Export-Csv -Path $ExportFile -NoTypeInformation