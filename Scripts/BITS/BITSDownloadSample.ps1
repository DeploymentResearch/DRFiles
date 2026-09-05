<#
.SYNOPSIS
    Downloads a file with BITS and reports transfer progress.
.DESCRIPTION
    Starts an asynchronous BITS transfer, polls the job state until it completes, and then
    finalises the job. Useful for testing peer to peer download behaviour.
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
      1.0.0 - 2025-03-04 - Initial release
#>

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
