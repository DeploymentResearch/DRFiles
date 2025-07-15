$SiteCode = "PS1"

# List Task Sequences
Get-WmiObject SMS_TaskSequencePackage -Namespace root\sms\site_$SiteCode | Where-Object { $_.Name -eq "Windows 11 Enterprise x64 23H2 Native"}

# Export Task Sequences
Set-Location E:\Demo\ExportedTaskSequences

$TsList = Get-WmiObject SMS_TaskSequencePackage -Namespace root\sms\site_$SiteCode | Where-Object { $_.Name -eq "Windows 11 Enterprise x64 23H2 Native"}
ForEach ($Ts in $TsList){
    $Ts = [wmi]"$($Ts.__PATH)"
    Set-Content -Path "$($ts.PackageId).xml" -Value $Ts.Sequence
}