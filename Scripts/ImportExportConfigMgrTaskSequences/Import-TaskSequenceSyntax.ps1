<#
.SYNOPSIS
    Syntax example for the Import-TaskSequence script.
.DESCRIPTION
    Reference snippet showing the parameters used when importing an exported task sequence XML
    file back into a ConfigMgr site.
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

# Syntax example for Import-TaskSequence.ps1 script
$TSImportFile = "E:\Demo\ExportedTaskSequences\PS100320.xml"
$NewTSName = "Windows 10 Enterprise x64 20HD From Export"

Set-Location "E:\Demo\Import and Export TS"
.\Import-TaskSequence.ps1 -SiteCode PS1 -TaskSequenceName $NewTSName -InputFile $TSImportFile 
