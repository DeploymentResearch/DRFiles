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
