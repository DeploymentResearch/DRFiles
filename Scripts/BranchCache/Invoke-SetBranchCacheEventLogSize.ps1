# Run Set-BranchCacheEventLogSize.ps1 on all DPs, sets the BranchCache operational log size to 20 MB

$HealthCheckPath  = "\\CM01\HealthCheck$"
$ExportPath = "C:\Windows\Temp"

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
    Copy-Item "$HealthCheckPath\Scripts\Set-BranchCacheEventLogSize.ps1" "\\$DP\C`$\Windows\Temp" -Force
}

# Run the script omn each DP and save output locally
write-host "Running script on each DP, and save output locally..."
write-host ""
Invoke-Command -command { C:\Windows\Temp\Set-BranchCacheEventLogSize.ps1 } -ComputerName $DPs 

write-host "Done!"
