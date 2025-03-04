$URL = "http://dp01.corp.viamonstra.com/500MB.zip"

$Job = Start-BitsTransfer -Source $URL -Destination C:\Temp -Priority Foreground -Asynchronous

while (($Job.JobState -eq "Transferring") -or ($Job.JobState -eq "Connecting")) {
       If ($Job.JobState -eq "Connecting"){
           #Write-Host "BITS Job state is: $($Job.JobState)"
       }
       If ($Job.JobState -eq "Transferring"){
           Write-Host "BITS Job state is: $($Job.JobState). $($Job.BytesTransferred) bytes transferred of $($Job.BytesTotal) total"
       }

       Start-Sleep -second 1
   } 
   Switch($Job.JobState){
       "Transferred" {
           Write-Host "BITS Job state is: $($Job.JobState). $($Job.BytesTransferred) bytes transferred of $($Job.BytesTotal) total"
           Complete-BitsTransfer -BitsJob $Job
           }
       "Error" {Write-Warning "File did not download"} # List the failure
       default {Write-Host "Default action"} #  Perform corrective action.
   }
