<#
.SYNOPSIS
    Reports file counts per ConfigMgr inbox folder.
.DESCRIPTION
    Groups the files under the site server inboxes folder by directory, which is the quickest
    way to spot a backlog building up in a specific inbox.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark / deploymentresearch.com
    Credits: Tip from Phil Schwan, @philschwan
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2025-12-17 - Initial release
#>

# Tip from Phil Schwan (@philschwan on Twitter)
Get-ChildItem "E:\Program Files\Microsoft Configuration Manager\inboxes" -recurse | 
Where {!$_.PSIsContainer} | Group Directory | Format-Table Name, Count -autosize

# Check for Empty files in policypv.box
Get-ChildItem "E:\Program Files\Microsoft Configuration Manager\inboxes\policypv.box" | Where-Object Length -eq 0

# WMI Option
Get-WmiObject -Class Win32_PerfFormattedData_SMSINBOXMONITOR_SMSInbox | Select-Object -Property PSComputerName, Name, FileCurrentCount
