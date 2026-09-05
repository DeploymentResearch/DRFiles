<#
.SYNOPSIS
    Imports a previously exported ConfigMgr task sequence from XML.
.DESCRIPTION
    Reads a task sequence XML file exported with Get-CMTaskSequence and creates a new task
    sequence from it under the specified name.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  David O'Brien, sepago
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2022-01-02 - Initial release
#>

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
