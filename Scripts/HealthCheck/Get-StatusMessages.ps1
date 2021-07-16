# Increase Query Maximum (default is 1000)
# Set-CMQueryResultMaximum -Maximum 5000
# $Date = "2015-01-16"
# Get-CMSiteStatusMessage -ViewingPeriod $Date | Where-Object { $_.MessageID -eq "11170" } | Select Component, MachineName,Time

$Site= 'PS1'
$SiteServer = 'CM01'
$OutputPath = "E:\Setup"

Start-Transcript -Path $OutputPath\StatusMessages.txt

$StatusMessages = @()
# Server Health
$StatusMessages += @{"MessageID" = "5203"; "MessageDescription" = "Counts of Active Directory System Discovery: Warning"}
$StatusMessages += @{"MessageID" = "2542"; "MessageDescription" = "Counts of Collection Evaluator failed to update query: Warning"}
$StatusMessages += @{"MessageID" = "2543"; "MessageDescription" = "Counts of Collection Evaluator failed to update the query rule of collectionServer: Warning"}
# Client Health
$StatusMessages += @{"MessageID" = "10815"; "MessageDescription" = "Client(s) reporting certificate maintenance failures"}
# Client deployments
$StatusMessages += @{"MessageID" = "10018"; "MessageDescription" = "Client(s) is reporting Platform is not supported for this advertisement"}
$StatusMessages += @{"MessageID" = "11135"; "MessageDescription" = "Client(s) reported that a task sequence failed to execute an action"}
$StatusMessages += @{"MessageID" = "10803"; "MessageDescription" = "Client(s) reporting failures downloading policy"}
$StatusMessages += @{"MessageID" = "10091"; "MessageDescription" = "Client(s) reporting inability to update Windows Installer package source path(s)"}
$StatusMessages += @{"MessageID" = "10006"; "MessageDescription" = "Client(s) reporting problems executing advertised program(s)"}
$StatusMessages += @{"MessageID" = "10056"; "MessageDescription" = "Client(s) reporting problems executing advertised program(s)"}
# Client Task Sequence progress
$StatusMessages += @{"MessageID" = "11170"; "MessageDescription" = "Client(s) reporting task sequence step failure"}
$StatusMessages += @{"MessageID" = "10093"; "MessageDescription" = "Counts of The Windows Installer source paths failed to update: Warning"}
$StatusMessages += @{"MessageID" = "2302"; "MessageDescription" = "Counts of Distribution Manager failed to process packages"}
$StatusMessages += @{"MessageID" = "2306"; "MessageDescription" = "Counts of Package source folder does not exist or not enough permissions"}
$StatusMessages += @{"MessageID" = "11138"; "MessageDescription" = "Client(s) reporting task sequence step failure"}
$StatusMessages += @{"MessageID" = "11135"; "MessageDescription" = "Client(s) reported that a task sequence failed to execute an action"}

# Output summary
Write-Output ""
Write-Output "----------------- Report Summary -----------------"
Write-Output ""
foreach ($StatusMessage in $StatusMessages) {
    $Status = Get-WmiObject -ComputerName $SiteServer -Query "SELECT * FROM SMS_StatusMessage WHERE MessageID=$($StatusMessage.MessageID)" -Namespace "root\sms\site_$Site" | Select-Object Component,MachineName,@{label='Time';expression={$_.ConvertToDateTime($_.Time)}} 
    Write-Output "MessageID: $($StatusMessage.MessageID) - $($Status.Count) $($StatusMessage.MessageDescription)"
    Write-Output ""
}

# Output details
Write-Output ""
Write-Output "----------------- Report Details -----------------"
Write-Output ""

foreach ($StatusMessage in $StatusMessages) {
    Write-Host "$($StatusMessage.MessageID) - $($StatusMessage.MessageDescription)"
    Get-WmiObject -ComputerName $SiteServer -Query "SELECT * FROM SMS_StatusMessage WHERE MessageID=$($StatusMessage.MessageID)" -Namespace "root\sms\site_$Site" | Select-Object Component,MachineName,@{label='Time';expression={$_.ConvertToDateTime($_.Time)}} 
    Write-Output ""
}

Stop-Transcript