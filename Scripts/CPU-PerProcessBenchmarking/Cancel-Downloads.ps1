<#
.SYNOPSIS
    Cancels running ConfigMgr package downloads on a client.
.DESCRIPTION
    Triggers cancellation for the listed packages and programs. A user must be logged on for
    the script to work.
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
      1.0.0 - 2022-07-26 - Initial release
#>

#
# Note: A user must be logged on for the script to work.
# 

# ConfigMgr Packages/Programs to run (ProgramID = Program Name)
$Batch = @()
$Batch += [pscustomobject]@{ PackageID = "PS100127"; ProgramID = "P2P Test Package - 2 GB Multiple Files" }

# Run the programs
[cimclass]$CimClass = (Get-CimClass -Namespace 'Root\ccm\clientsdk' -ClassName 'CCM_ProgramsManager' -ErrorAction 'Stop')
foreach($Item in $Batch){

    [hashtable]$Arguments = @{
        'PackageID' = $Item.PackageID
        'ProgramID' = $Item.ProgramID
    }

    Try {
        Invoke-CimMethod -CimClass $CimClass -MethodName 'CancelDownload' –Arguments $Arguments -ErrorAction 'Stop'
    }
    Catch {
        $ErrorMessage = "Could not cancel download"
    }
}


