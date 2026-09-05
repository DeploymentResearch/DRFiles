<#
.SYNOPSIS
    Dumps task sequence variables to a log file, excluding sensitive ones.
.DESCRIPTION
    Enumerates the task sequence environment and writes the values to the task sequence log
    path, skipping the reserved and password bearing variables.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Schrewelius, Onevinn AB
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 2.0.0

    Change history:
      2.0.0 - 2025-07-29 - Initial release
#>

# Config Start

$HideVariables = @('_OSDOAF','_SMSTSReserved','_SMSTSTaskSequence', '_TSSub')

# Config End

$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
$logPath = $tsenv.Value("_SMSTSLogPath")
$now = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$logFile = "TSVariables-$now.log"
$logFileFullName = Join-Path -Path $logPath -ChildPath $logFile

function MatchArrayItem {
    param (
        [array]$Arr,
        [string]$Item
        )

    $result = ($null -ne ($Arr | ? { $Item -match $_ }))
    return $result
}

$varNames = $tsenv.GetVariables()

foreach ($varName in $varNames) {

    if ($varName.EndsWith("_HiddenValueFlag")) {
        continue;
    }

    $value = $tsenv.Value($varName)

    if ($varNames.Contains("$($varName)_HiddenValueFlag") -or (MatchArrayItem -Arr $HideVariables -Item $varName)) {
        $value = "Hidden value"
    }

    "$varName = $value" | Out-File -FilePath $logFileFullName -Append
}
