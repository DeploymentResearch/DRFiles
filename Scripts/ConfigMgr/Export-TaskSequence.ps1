$SiteCode = "PS1"

# List Task Sequences
Get-WmiObject SMS_TaskSequencePackage -Namespace root\sms\site_$SiteCode | Where-Object { $_.Name -eq "Windows 11 Enterprise x64 23H2 Native"}

# Export Task Sequences
Set-Location E:\Demo\ExportedTaskSequences

$TsList = Get-WmiObject SMS_TaskSequencePackage -Namespace root\sms\site_$SiteCode # | Where-Object { $_.Name -eq "Windows 11 Enterprise x64 23H2 Native MDM SQL"}
ForEach ($Ts in $TsList){
    $Ts = [wmi]"$($Ts.__PATH)"
    Set-Content -Path "$($ts.PackageId).xml" -Value $Ts.Sequence
}



# Search for MDT Templates
$SearchString = "BDD"
$Path = "E:\Demo\ExportedTaskSequences"
$FilesWithMDTThings = Get-ChildItem -Path $Path -Filter *.XML -recurse | Select-String -pattern $SearchString | Group-Object path | Select-Object name

$FilesWithMDTThings.count
