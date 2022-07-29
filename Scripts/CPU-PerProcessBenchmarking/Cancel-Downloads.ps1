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


