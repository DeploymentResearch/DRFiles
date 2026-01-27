<#
.SYNOPSIS
  This script collects useful health information on multiple distribution points. 

.DESCRIPTION
  This script copies and executes DPInfo.PS1 to each server in a list of DPs
  Each DP will return the resulting .CSV file to the folder \DPs
  Then once all DPs complete the script run - the resulting .CSV are combined into a single CSV in the /Results folder

  
.LINK
  https://P2intSoftware.com

.NOTES
          FileName: DPInfo.ps1
          Contact: @2PintSoftware
          Created: 2019-07-11
          Modified: 2019-07-11

          Version - v1.0.0 - (2019-07-11)
.USAGE
        Requires folder structure as follows:
        \DPInfo - shared as DPInfo
        \DPInfo\DPs
        \DPInfo\Results
        \DPInfo\Scripts

 .Example
  .\Get-DPHealth.PS1 

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
