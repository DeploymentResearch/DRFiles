<#
.SYNOPSIS
    Disables every task sequence in an MDT deployment share.
.DESCRIPTION
    Backs up TaskSequences.xml, then sets every task sequence to disabled. Close the Deployment
    Workbench before running this.
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

# NOTE: Close the Deployment Workbench prior to running this

# Specify TaskSequences.xml to use
$TSXMLFile = "C:\DeploymentShare\Control\TaskSequences.xml"
 
# Make a backup copy just in case
$TimeStamp = "_"+$(get-date -f MMddyyyy)+"_"+$(get-date -f HHmmss)
Copy-Item $TSXMLFile $TSXMLFile$TimeStamp

# Load the TaskSequences.xml file as a XML object
[xml]$TSXML = Get-Content -Path $TSXMLFile

# Enable all task sequences
foreach ($TS in $TSXML.tss.ts)
{
    $TS.enable = "False"
}

# Save the changes
$TSXML.Save($TSXMLFile)
