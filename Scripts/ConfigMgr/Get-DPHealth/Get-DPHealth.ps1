<#
.SYNOPSIS
    Collects health information from multiple ConfigMgr distribution points.
.DESCRIPTION
    Copies DPInfo.ps1 to each distribution point in the list, runs it remotely, and combines the
    returned CSV files into a single summary report.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  2Pint Software health check series
    Credits: Original 2Pint Software health check series
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2019-11-20 - Initial release
#>

# Runs DPInfo.ps1 on all listed DPs

$HealthCheckPath  = "\\cm02\DPInfo"
$ExportPath = "C:\Windows\Temp"

$DPs = @(
	"CM02"


)

# Copy the script to each DP
write-host "Starting to copy script to each DP..."
write-host ""
foreach ($DP in $DPs){
    write-host "Copying script to $DP"
    Copy-Item "$HealthCheckPath\Scripts\DPInfo.ps1" "\\$DP\C`$\Windows\Temp" -Force
}

# Run the script on each DP and save output locally
write-host "Running script on each DP, and save output locally..."
write-host ""
Invoke-Command -command {param ($ExportPath);write-host $ENV:ComputerName;C:\Windows\Temp\DPInfo.ps1 -ExportPath $ExportPath } -ComputerName $DPs -ArgumentList $ExportPath

# Make sure all scripts finished writing to the log
write-host "Waiting 10 seconds..."
write-host ""
Start-Sleep -Seconds 10

# Copy the result back to the Health Check folder
write-host "Copy the result back to the Health Check folder..."
write-host ""
foreach ($DP in $DPs){
    write-host "Copying the result from $DP"
    Copy-Item "\\$DP\C`$\Windows\Temp\$DP.CSV" "$HealthCheckPath\DPs" -Force
}

# Combine the result in a summary report
write-host "Combining the result in a summary report..."
write-host ""
$Command = [scriptblock]::create("$HealthCheckPath\Scripts\CombineDPCSVs.ps1 -HealthCheckPath $HealthCheckPath")
Invoke-Command -ScriptBlock $Command
write-host "Done!"
