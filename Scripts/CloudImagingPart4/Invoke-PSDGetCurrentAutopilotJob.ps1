<#
.SYNOPSIS
    Server-Side script for Cloud OS Deployment, Part 4

.DESCRIPTION
    Checks status for ongoing Windows Autopilot registration

.NOTES
    Author: Johan Arwidmark / deploymentresearch.com
    Twitter (X): @jarwidmark
    LinkedIn: https://www.linkedin.com/in/jarwidmark
    License: MIT
    Source:  https://github.com/DeploymentResearch/DRFiles

.DISCLAIMER
    This script is provided "as is" without warranty of any kind, express or implied.
    Use at your own risk — the author and DeploymentResearch assume no responsibility for any
    issues, damages, or data loss resulting from its use or modification.

    This script is shared in the spirit of community learning and improvement.
    You are welcome to adapt and redistribute it under the terms of the MIT License.

.VERSION
    1.0.0
    Released: 2025-11-23
    Change history:
      1.0.0 - 2025-11-23 - Initial release
#>

# GET /tasks/{id}/status
param(
    $RequestArgs
)

# Get job id
$jobid = $RequestArgs.split("=")[1]
$job = Get-Job -Name $jobid

switch ($job.State) {
    'Running'    { 
        Return "Running"
    }
    'Completed'  {
        Return "Completed"
    }
    'Failed'     {
        Return "Failed"
    }
    Default      {
        Return "Unknown"
    }
}
