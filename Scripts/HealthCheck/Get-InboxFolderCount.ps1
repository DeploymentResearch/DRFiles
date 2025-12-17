# Tip from Phil Schwan (@philschwan on Twitter)
Get-ChildItem "E:\Program Files\Microsoft Configuration Manager\inboxes" -recurse | 
Where {!$_.PSIsContainer} | Group Directory | Format-Table Name, Count -autosize

# Check for Empty files in policypv.box
Get-ChildItem "E:\Program Files\Microsoft Configuration Manager\inboxes\policypv.box" | Where-Object Length -eq 0

# WMI Option
Get-WmiObject -Class Win32_PerfFormattedData_SMSINBOXMONITOR_SMSInbox | Select-Object -Property PSComputerName, Name, FileCurrentCount