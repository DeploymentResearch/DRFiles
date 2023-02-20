# Run data collector on all DPs

$HealthCheckPath  = "\\CM01\HealthCheck$"
$DPCollectorResultsPath = "$HealthCheckPath\BranchCacheError13DPs"
$LocalExportPath = "C:\Windows\Temp"
$DataCollector = "Get-BranchCacheError13FileList.ps1"
$ts = $(get-date -f MMddyyyy_hhmmss)
$SummaryReport = "$HealthCheckPath\results\BranchCacheError13Summary_$ts.csv"

# DP List updated 2022-02-18
$DPs = @(
    "DP01"
    "DP02"
)

# Copy the script to each DP
write-host "Starting to copy script to each DP..."
write-host ""
foreach ($DP in $DPs){
    write-host "Copying script to $DP"
    Copy-Item "$HealthCheckPath\Scripts\$DataCollector" "\\$DP\C`$\Windows\Temp" -Force
}

# Run the script omn each DP and save output locally
write-host "Running script on each DP, and save output locally..."
write-host ""
Invoke-Command -ScriptBlock {write-host $ENV:ComputerName; & C:\Windows\Temp\$using:DataCollector -LocalExportPath $using:LocalExportPath } -ComputerName $DPs 

# Make sure all scripts finished writing to the local CSV file
write-host "Waiting 300 seconds..."
write-host ""
Start-Sleep -Seconds 300

# Copy the result back to the Health Check folder
write-host "Copy the result back to the Health Check folder..."
write-host ""
foreach ($DP in $DPs){
    write-host "Copying the result from $DP"
    Copy-Item "\\$DP\C`$\Windows\Temp\$DP.CSV" $DPCollectorResultsPath -Force
}

# Combine the result in a summary report
write-host "Combining the result in a summary report..."

$CSVFiles = Get-ChildItem -Path $DPCollectorResultsPath -Filter "*.CSV" 
$CSVFiles | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv "$SummaryReport" -NoTypeInformation
$NumberOfCSVFiles = ($CSVFiles | Measure-Object).Count

Write-Host "Summarized $NumberOfCSVFiles CSV files into $SummaryReport"