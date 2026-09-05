<#
.SYNOPSIS
    Combines the per distribution point health CSV files into one summary report.
.DESCRIPTION
    Reads every CSV produced by DPInfo.ps1 from the collection share and writes a single
    consolidated health summary file.
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
      1.0.0 - 2019-11-11 - Initial release
#>

$HealthCheckPath  = "\\cm02\dpinfo"
$SummaryReport = "DPHealthSummary.csv"

If (Test-path $HealthCheckPath\results\DPHealthSummary.csv){Remove-Item $HealthCheckPath\results\$SummaryReport -Force}
Get-ChildItem -Path "$HealthCheckPath\DPs" -Filter "*.CSV" -Recurse | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv "$HealthCheckPath\results\$SummaryReport" -NoTypeInformation -Append
