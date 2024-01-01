$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$ExportFile = "C:\Windows\Temp\OSDNTPDeploymentTime.csv"
# Write-Host $TSEnv.Value("OSDNTPStartTime")
# Write-Host $TSEnv.Value("OSDNTPFinishTime")

$OSDNTPStartTime = Get-Date($TSEnv.Value("OSDNTPStartTime"))
$OSDNTPFinishTime = Get-Date($TSEnv.Value("OSDNTPFinishTime"))
$OSDNTPDeploymentTime = [int]((New-TimeSpan -Start $OSDNTPStartTime -End $OSDNTPFinishTime).TotalMinutes)

$hash = New-Object System.Collections.Specialized.OrderedDictionary
$Hash.Add("OSDNTPStartTime",$OSDNTPStartTime)
$Hash.Add("OSDNTPFinishTime",$OSDNTPFinishTime)
$Hash.Add("OSDNTPDeploymentTime",$OSDNTPDeploymentTime)

$CSVObject = New-Object -TypeName psobject -Property $Hash
$CSVObject | Export-csv -path $ExportFile -Force -NoTypeInformation -Delimiter ";" 

Return $OSDNTPDeploymentTime 