<#
.SYNOPSIS
    Sets the BranchCache operational event log to 20 MB.
.DESCRIPTION
    Checks the current maximum size of the BranchCache operational log and increases it if it
    is smaller than 20 MB.
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

# Get the BranchCache Log size in Event Viewer
$BCLog = Get-LogProperties 'Microsoft-Windows-BranchCache/Operational'

# Check BranchCache Log max size, if not 20MB, set it to 20MB
If (!($BCLog.MaxLogSize -eq 20MB )){
    $BCLog.MaxLogSize = 20MB
    Set-LogProperties -LogDetails $BCLog
}

Return "BranchCache log on $env:ComputerName set to $($BCLog.MaxLogSize / 1MB) MB"


