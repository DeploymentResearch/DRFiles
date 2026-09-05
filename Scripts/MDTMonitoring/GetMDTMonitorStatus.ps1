<#
.SYNOPSIS
    Reads deployment status from the MDT monitoring web service.
.DESCRIPTION
    Queries the MDTMonitorData endpoint and displays the computer name and percent complete for
    each monitored deployment in a grid view.
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

$URL = "http://MDT01:9801/MDTMonitorData/Computers"

function GetMDTData {
  $Data = Invoke-RestMethod $URL

  foreach($property in ($Data.content.properties) ) {
    New-Object PSObject -Property @{
      Name = $($property.Name);
      PercentComplete = $($property.PercentComplete.'#text');
      Warnings = $($property.Warnings.'#text');
      Errors = $($property.Errors.'#text');
      DeploymentStatus = $(
        Switch ($property.DeploymentStatus.'#text') {
        1 { "Active/Running" }
        2 { "Failed" }
        3 { "Successfully completed" }
        Default { "Unknown" }
        }
      );
      StartTime = $($property.StartTime.'#text') -replace "T"," ";
      EndTime = $($property.EndTime.'#text') -replace "T"," ";
    }
  }
} 

GetMDTData | Select Name, DeploymentStatus, PercentComplete, Warnings, Errors, StartTime, EndTime  | Out-GridView
