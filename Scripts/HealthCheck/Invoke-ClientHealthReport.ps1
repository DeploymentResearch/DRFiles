<#
.SYNOPSIS
    Combines client health data points into a single summary report.
.DESCRIPTION
    Reads the per client CSV files from the health check share, removes data points older than
    the retention window, and writes a consolidated summary report.
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
      1.0.0 - 2021-02-12 - Initial release
#>

# Variables
$HealthCheckPath = "\\CM01\HealthCheck$"
$ts = $(get-date -f MMddyyyy_hhmmss)
$ReportFilePath = "$HealthCheckPath\Results\ConfigMgrClientHealthSummary_$ts.csv"

# Remove data points older than 30 days
$maxDaystoKeep = -30
$itemsToDelete = Get-ChildItem -Path "$HealthCheckPath\Clients" -Filter *.CSV | Where LastWriteTime -lt ((get-date).AddDays($maxDaystoKeep))
$itemsToDeleteCount = ($itemsToDelete | Measure-Object).Count

if ($itemsToDeleteCount -gt 0){
    Write-Output "There are $itemsToDeleteCount items to be deleted today, $($(Get-Date).DateTime)" 
    ForEach ($item in $itemsToDelete){
        Remove-Item $item.FullName -Force
    }
}
else{
        Write-Output "No items to be deleted today, $($(Get-Date).DateTime)" 
}

# Get the CSV files
$CSVFiles = Get-ChildItem -Path "$HealthCheckPath\Clients" -Filter "*.CSV"
Write-Output "Importing $($CSVFiles.count) CSV files. Sit tight, may take a while..."
Write-Output ""

# Export to a report
foreach ($CSVFile in $CSVFiles){
    (Import-CSV -Path $CSVFile.FullName) | Export-CSV -Path $ReportFilePath -NoTypeInformation -Append 
}
