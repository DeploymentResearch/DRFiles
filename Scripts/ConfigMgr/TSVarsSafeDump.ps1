<#
    Name: TSVarsSafeDump.ps1
    Version: 2.0
    Author: Johan Schrewelius, Onevinn AB
    Date: 2020-09-03
    Command: powershell.exe -executionpolicy bypass -file TSVarsSafeDump.ps1
    Usage:  Run in MEMCM Task Sequence to Dump TS-Varibles to disk ("_SMSTSLogPath").
            Variables known to contain sensitive information will be hidden.
    Config: List of variables to exclude, edit as needed:
            $HideVariables = @('_OSDOAF','_SMSTSReserved','_SMSTSTaskSequence')
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
