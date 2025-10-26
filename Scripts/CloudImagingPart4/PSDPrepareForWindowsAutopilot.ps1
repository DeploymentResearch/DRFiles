<#
.SYNOPSIS
    Client-Side script for Cloud OS Deployment, Part 4

.DESCRIPTION
    Script to download the PSD Autopilot integration from PSDResources\Autopilot
    This includes a customized Splash Screen and other supporting scripts

.NOTES
    Author: Johan Arwidmark / deploymentresearch.com
    Twitter (X): @jarwidmark
    License: MIT
    Source:  https://github.com/DeploymentResearch/DRFiles

.DISCLAIMER
    This script is provided "as is" without warranty of any kind, express or implied.
    Use at your own risk — the author and DeploymentResearch assume no responsibility for any
    issues, damages, or data loss resulting from its use or modification.

    This script is shared in the spirit of community learning and improvement.
    You are welcome to adapt and redistribute it under the terms of the MIT License.

.VERSION
    1.0.2
    Released: 2025-10-01
    Change history:
      1.0.2 - 2025-10-01 - Simplified script to only download Autopilot integration
      1.0.1 - 2021-09-10 - Integration release for the PSD Cloud OS Deployment solution
      1.0.0 - 2020-05-12 - Initial release
#>

# Set scriptversion for logging
$ScriptVersion = "1.0"

# Load core modules
Import-Module Microsoft.BDD.TaskSequenceModule -Scope Global -Verbose:$false
Import-Module PSDUtility -Verbose:$false
Import-Module PSDDeploymentShare -Verbose:$false

# Check for debug in PowerShell and TSEnv
if($TSEnv:PSDDebug -eq "YES"){
    $Global:PSDDebug = $true
}
if($PSDDebug -eq $true)
{
    $verbosePreference = "Continue"
}

Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Starting: $($MyInvocation.MyCommand.Name) - Version $ScriptVersion"
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): The task sequencer log is located at $("$TSEnv:_SMSTSLogPath\SMSTS.LOG"). For task sequence failures, please consult this log."

# Download the PSD Autopilot integration from PSDResources\Autopilot
$Download = Get-PSDContent -Content "PSDResources\Autopilot"

