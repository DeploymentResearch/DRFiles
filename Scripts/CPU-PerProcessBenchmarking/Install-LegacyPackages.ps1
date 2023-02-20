#
# Note: A user must be logged on for the script to work.
# 

# Clear the BITS eventlog
Get-WinEvent -ListLog *BITS* -Force | % { Wevtutil.exe cl $_.LogName }

# Wait a bit
Start-Sleep -Seconds 5

# ConfigMgr Packages/Programs to run (ProgramID = Program Name)
$Batch = @()
#$Batch += [pscustomobject]@{ PackageID = "PS100127"; ProgramID = "P2P Test Package - 2 GB Multiple Files" }
$Batch += [pscustomobject]@{ PackageID = "PS100130"; ProgramID = "P2P Test Package - 5 GB Single File" }

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


