<#
.SYNOPSIS
    Combines multiple single entry Autopilot CSV files into one file.
.DESCRIPTION
    Reads every CSV in the source folder and writes a single consolidated file, which makes
    bulk upload of hardware hashes to Intune much easier.
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
      1.0.0 - 2023-06-12 - Initial release
#>

# Sample Script to combine CSV Files with a single Autopilot entry, to a file with multiple entries.

# Sety generic variables
$APCSVFolder = "C:\APCSVFiles"
$APCSVFileAllMachines = "$APCSVFolder\AutoPilot_AllMachines.csv"

# Combine the CSV files for easy upload
$CSVFiles = Get-ChildItem -Path $APCSVFolder -Filter "*.CSV" 
$CSVFiles | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $APCSVFileAllMachines -NoTypeInformation -Encoding ASCII   
