<#
.SYNOPSIS
    Forces a full ConfigMgr hardware inventory cycle.
.DESCRIPTION
    Removes the stored inventory action state so the next cycle sends a full inventory rather
    than a delta, then triggers the cycle.
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
      1.0.0 - 2026-03-17 - Initial release
#>

$strAction = "{00000000-0000-0000-0000-000000000001}"

Get-WmiObject -Namespace "root\ccm\invagt" -Class InventoryActionStatus | where {$_.InventoryActionID -eq "$strAction"} | Remove-WmiObject

try {
Invoke-WmiMethod -ComputerName $env:computername -Namespace root\ccm -Class SMS_Client -Name TriggerSchedule -ArgumentList $strAction -ErrorAction Stop | Out-Null
}
catch {
write-host "$env:computername`: $_" -ForegroundColor Red
}
