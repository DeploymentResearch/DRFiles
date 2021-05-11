param (
[string]$SiteCode,
[string]$TaskSequenceName,
[string]$InputFile
)


#########
# What does it do?
# Script imports a previously "exported" TaskSequence from CM12 to CM12
#
# Howto: Extract the TaskSequence with the following command:
# (Get-CMTaskSequence | where-object {$_.Name -eq $NameOfTaskSequence}).Sequence | Out-File $PathToExportFile
# This will be your $InputFile
#
# Author: David O'Brien, david.obrien@sepago.de
# Created: 28.09.2012
# Prerequisites: 
#               - Microsoft System Center Configuration Manager 2012 SP1 (beta)
#               - ConfigMgr Powershell to get your existing TaskSequence
#
#########

$Class = "SMS_TaskSequencePackage"

$Instance = $null
$TS = $null
$NewSequence = $null

$TS = [wmiclass]"\\.\root\sms\site_$($SiteCode):$($Class)"
$Instance = $TS.CreateInstance()

$SequenceFile = Get-Content $InputFile

$NewSequence = $Ts.ImportSequence($SequenceFile).TaskSequence
$Instance.Name = "$TaskSequenceName"

$NewTSPackageID = $TS.SetSequence($Instance, $NewSequence).SavedTaskSequencePackagePath