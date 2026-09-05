<#
.SYNOPSIS
    Triggers evaluation of the Secure Boot update data inventory baseline.
.DESCRIPTION
    Finds the named configuration baseline in the client DCM namespace and starts an
    evaluation, so the compliance result refreshes without waiting for the schedule.
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
      1.0.0 - 2026-04-30 - Initial release
#>

$BaselineName = "CB - Secure Boot Update Data Inventory"
$ComputerName = "Localhost"

$Baselines = Get-WmiObject -ComputerName $ComputerName -Namespace root\ccm\dcm -Class SMS_DesiredConfiguration | Where-Object {$_.DisplayName -like $BaselineName}
$Baselines | % { ([wmiclass]"\\$ComputerName\root\ccm\dcm:SMS_DesiredConfiguration").TriggerEvaluation($_.Name, $_.Version) }
