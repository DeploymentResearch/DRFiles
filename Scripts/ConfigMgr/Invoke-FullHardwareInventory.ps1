$strAction = "{00000000-0000-0000-0000-000000000001}"

Get-WmiObject -Namespace "root\ccm\invagt" -Class InventoryActionStatus | where {$_.InventoryActionID -eq "$strAction"} | Remove-WmiObject

try {
Invoke-WmiMethod -ComputerName $env:computername -Namespace root\ccm -Class SMS_Client -Name TriggerSchedule -ArgumentList $strAction -ErrorAction Stop | Out-Null
}
catch {
write-host "$env:computername`: $_" -ForegroundColor Red
}