$SiteCode = "PS1"

# List Task Sequences
Get-WmiObject SMS_TaskSequencePackage -Namespace root\sms\site_$SiteCode  | Select *

# Export Task Sequences
cd E:\Demo\ExportedTaskSequences
$TsList = Get-WmiObject SMS_TaskSequencePackage -Namespace root\sms\site_$SiteCode
ForEach ($Ts in $TsList)
 {
 $Ts = [wmi]“$($Ts.__PATH)”
Set-Content -Path “$($ts.PackageId).xml” -Value $Ts.Sequence
 }