# Get the BranchCache Log size in Event Viewer
$BCLog = Get-LogProperties 'Microsoft-Windows-BranchCache/Operational'

# Check BranchCache Log max size, if not 20MB, set it to 20MB
If (!($BCLog.MaxLogSize -eq 20MB )){
    $BCLog.MaxLogSize = 20MB
    Set-LogProperties -LogDetails $BCLog
}

Return "BranchCache log on $env:ComputerName set to $($BCLog.MaxLogSize / 1MB) MB"


