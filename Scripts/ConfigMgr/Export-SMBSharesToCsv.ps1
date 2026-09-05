<#
.SYNOPSIS
    Exports the list of SMB shares to a CSV file.
.DESCRIPTION
    Enumerates every non special share and writes the name, path, description, and folder
    enumeration mode to a CSV file.
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
$ExportFile = "$ExportPath\SmbShares.csv"

If (!(Test-Path $ExportPath)){New-Item -Path $ExportPath -ItemType Directory -Force  }

Get-SmbShare |
    Where-Object Special -eq $false |
    Select-Object Name, Path, Description, ScopeName, FolderEnumerationMode, CachingMode, ConcurrentUserLimit |
    Export-Csv -Path $ExportFile -NoTypeInformation
