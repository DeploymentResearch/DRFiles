<#
.SYNOPSIS
    Calculates deployment duration from task sequence NTP timestamps.
.DESCRIPTION
    Reads the start and finish time variables set during the task sequence, works out the
    elapsed time, and exports the result to a CSV file.
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
      1.0.0 - 2023-12-31 - Initial release
#>

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
