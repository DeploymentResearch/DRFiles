<#
.SYNOPSIS
    Server-side script for Cloud OS Deployment, Part 4.
.DESCRIPTION
    Checks the status of an ongoing Windows Autopilot registration job and returns Running,
    Completed, Failed, or Unknown to the calling client.
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
