<#
.SYNOPSIS
    Exports ConfigMgr task sequences to XML files.
.DESCRIPTION
    Lists the task sequence packages in the site and writes the task sequence XML for each one
    to an export folder.
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
      1.0.0 - 2022-01-02 - Initial release
#>

$SiteCode = "PS1"

# List Task Sequences
Get-WmiObject SMS_TaskSequencePackage -Namespace root\sms\site_$SiteCode  | Select *

# Export Task Sequences
cd E:\Demo\ExportedTaskSequences
$TsList = Get-WmiObject SMS_TaskSequencePackage -Namespace root\sms\site_$SiteCode
ForEach ($Ts in $TsList)
 {
 $Ts = [wmi]"$($Ts.__PATH)"
Set-Content -Path "$($ts.PackageId).xml" -Value $Ts.Sequence
 }
