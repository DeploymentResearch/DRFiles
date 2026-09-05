<#
.SYNOPSIS
    Triggers installation of available ConfigMgr packages on a client.
.DESCRIPTION
    Clears the BITS event log, then starts the listed packages and programs so download
    behaviour can be measured from a known state. A user must be logged on.
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

#
# Note: A user must be logged on for the script to work.
# 

# Clear the BITS eventlog
# Get-WinEvent -ListLog *BITS* -Force | % { Wevtutil.exe cl $_.LogName }


# ConfigMgr Packages/Programs to run (ProgramID = Program Name)
$Batch = @()
$Batch += [pscustomobject]@{ PackageID = "PS1000E4"; ProgramID = "P2P Test Package - 100 MB Multiple Files" }
$Batch += [pscustomobject]@{ PackageID = "PS1000E5"; ProgramID = "P2P Test Package - 100MB Single File" }
$Batch += [pscustomobject]@{ PackageID = "PS1000E6"; ProgramID = "P2P Test Package - 10MB Single File" }
$Batch += [pscustomobject]@{ PackageID = "PS1000E7"; ProgramID = "P2P Test Package - 1GB Multiple Files" }
$Batch += [pscustomobject]@{ PackageID = "PS1000E8"; ProgramID = "P2P Test Package - 1GB Single File" }
$Batch += [pscustomobject]@{ PackageID = "PS1000E9"; ProgramID = "P2P Test Package - 200 MB Multiple Files" }
$Batch += [pscustomobject]@{ PackageID = "PS1000EA"; ProgramID = "P2P Test Package - 200MB Single File" }
$Batch += [pscustomobject]@{ PackageID = "PS1000EB"; ProgramID = "P2P Test Package - 2GB Multiple File" }
$Batch += [pscustomobject]@{ PackageID = "PS1000EC"; ProgramID = "P2P Test Package - 2MB Single File" }
$Batch += [pscustomobject]@{ PackageID = "PS1000ED"; ProgramID = "P2P Test Package - 300 MB Multiple Files" }
$Batch += [pscustomobject]@{ PackageID = "PS1000EE"; ProgramID = "P2P Test Package - 300 MB Single File" }
$Batch += [pscustomobject]@{ PackageID = "PS1000EF"; ProgramID = "P2P Test Package - 3MB Single File" }
$Batch += [pscustomobject]@{ PackageID = "PS1000F0"; ProgramID = "P2P Test Package - 4 MB Multiple Files" }
$Batch += [pscustomobject]@{ PackageID = "PS1000F1"; ProgramID = "P2P Test Package - 400 MB Multiple Files" }
$Batch += [pscustomobject]@{ PackageID = "PS1000F2"; ProgramID = "P2P Test Package - 5 MB Multiple Files" }
$Batch += [pscustomobject]@{ PackageID = "PS1000F3"; ProgramID = "P2P Test Package - 5GB Single File" }
$Batch += [pscustomobject]@{ PackageID = "PS1000F4"; ProgramID = "P2P Test Package - 5MB Single File" }
$Batch += [pscustomobject]@{ PackageID = "PS1000F5"; ProgramID = "P2P Test Package - 70 MB Multiple Files" }


# Run the programs
[cimclass]$CimClass = (Get-CimClass -Namespace 'Root\ccm\clientsdk' -ClassName 'CCM_ProgramsManager' -ErrorAction 'Stop')
foreach($Item in $Batch){

    [hashtable]$Arguments = @{
        'PackageID' = $Item.PackageID
        'ProgramID' = $Item.ProgramID
    }

    Try {
        Invoke-CimMethod -CimClass $CimClass -MethodName 'ExecuteProgram' –Arguments $Arguments -ErrorAction 'Stop'
    }
    Catch {
        $ErrorMessage = "Could not run Program $($Item.ProgramID). `n $_.ErrorMessage"
    }
}
