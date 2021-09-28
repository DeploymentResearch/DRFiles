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
