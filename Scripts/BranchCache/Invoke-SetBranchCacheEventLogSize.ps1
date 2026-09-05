<#
.SYNOPSIS
    Sets the BranchCache operational log size on all distribution points.
.DESCRIPTION
    Copies the log sizing script to each distribution point and runs it remotely, so that the
    BranchCache operational log is large enough to survive a busy deployment window.
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
      1.0.0 - 2022-03-25 - Initial release
#>

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
