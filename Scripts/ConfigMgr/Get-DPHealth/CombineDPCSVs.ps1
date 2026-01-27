$HealthCheckPath  = "\\cm02\dpinfo"
$SummaryReport = "DPHealthSummary.csv"

If (Test-path $HealthCheckPath\results\DPHealthSummary.csv){Remove-Item $HealthCheckPath\results\$SummaryReport -Force}
Get-ChildItem -Path "$HealthCheckPath\DPs" -Filter "*.CSV" -Recurse | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv "$HealthCheckPath\results\$SummaryReport" -NoTypeInformation -Append
