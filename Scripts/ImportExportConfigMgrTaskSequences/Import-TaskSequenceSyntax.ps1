# Syntax example for Import-TaskSequence.ps1 script
$TSImportFile = "E:\Demo\ExportedTaskSequences\PS100320.xml"
$NewTSName = "Windows 10 Enterprise x64 20HD From Export"

Set-Location "E:\Demo\Import and Export TS"
.\Import-TaskSequence.ps1 -SiteCode PS1 -TaskSequenceName $NewTSName -InputFile $TSImportFile 