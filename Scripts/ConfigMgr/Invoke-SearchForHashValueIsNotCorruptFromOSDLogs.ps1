$Path = "E:\Logs\Archive"
$StartDate = (Get-Date).AddDays(-3000)
#$Search = "Hash could not be matched for the downloaded content"
$Search = "ProgramName is being logged"

$LogFiles = Get-ChildItem -Path $Path -Recurse -Filter smsts*.log | Where { $_.LastWriteTime -ge $StartDate }
$LogFilesWithError = $LogFiles | Select-String -pattern $Search | group path | select name
$ts = $(get-date -f MMddyyyy_hhmmss)
$ExportFile = "E:\HealthCheck\Results\HashErrorsFromOSDLogs_$ts.csv"

# Get computer info
[System.Collections.ArrayList]$ComputerInfo = @()
foreach ($LogFile in $LogFiles){
    $RootPath = ($LogFile.FullName).Replace($Path,"")
    $ComputerName = $RootPath.Split("\")[1]

    $obj = [PSCustomObject]@{

        # Add values to arraylist
        ComputerName  =  $ComputerName
        
    }

    # Add all the values
    $ComputerInfo.Add($obj)|Out-Null
}
$UniqeComputers = $ComputerInfo | Select ComputerName -Unique

# Get computer info for computers with errors
[System.Collections.ArrayList]$ComputerWithErrorInfo = @()
foreach ($LogFile in $LogFilesWithError){
    $RootPath = ($LogFile.Name).Replace($Path,"")
    $ComputerName = $RootPath.Split("\")[1]

    $obj = [PSCustomObject]@{

        # Add values to arraylist
        ComputerName  =  $ComputerName
        
    }

    # Add all the values
    $ComputerWithErrorInfo.Add($obj)|Out-Null
}
$UniqeComputersWithErrors = $ComputerWithErrorInfo | Select ComputerName -Unique


# Count of logs with since start date 
Write-Host "Number of log files since $($StartDate): $(($LogFiles | Measure-Object).Count)"
Write-Host "These logs are from $(($UniqeComputers | Measure-Object).Count) individual computers"
Write-Host ""

# Count of logs with Hash Value is not correct since start date
$Count = ($LogFilesWithError | Measure-Object).Count
Write-Host "Number of log files with errors since $($StartDate): $(($LogFilesWithError | Measure-Object).Count)"
Write-Host "These logs are from $(($UniqeComputersWithErrors | Measure-Object).Count) individual computers"
Write-Host ""

# Abort script if no errors found
If ($Count -eq 0){
    Write-host "No errors found, aborting script..."
    Break
}

If ($Count -gt 0){

    [System.Collections.ArrayList]$HashInfo = @()
    Foreach ($File in $LogFilesWithError){
     
        $StringWithPackageID = Get-Content $file.Name | Select-String -Pattern $Search -SimpleMatch -Context 0,1
        $PackageID = (($StringWithPackageID -split "Verify package ")[1]).SubString(0,8)

        # Get DP from BITSACP type log file
        $StringWithDP = Get-Content $file.Name | Select-String -Pattern $Search -SimpleMatch -Context 15,0
        $DP = ((($StringWithDP -split "Trying ")[1]) -split ".]LOG]")[0]

        # Get DP from Non-BITSACP log file
        If ($DP -eq ""){
            $DP = ((($StringWithDP -split "Downloaded file from ")[1]) -split " to")[0]
        }

        If ($DP -eq ""){
            write-host $File
        }
        Else{
            $DPName = ([uri]$DP).Host 
            #Write-Host "Package: $PackageID failed on DP: $DPName"    
        }

        $obj = [PSCustomObject]@{

            # Add values to arraylist
            PackageID  =  $PackageID
            DP = $DPName 
            Logfile = $file.Name
        
        }

        # Add all the values
        $HashInfo.Add($obj)|Out-Null

    }
}

# Export to CSV File
$HashInfo | Export-Csv -Path $ExportFile -NoTypeInformation

# Count of packages with Hash Issues
$HashInfo | group PackageID | Sort-Object Name | Select Count, Name

# Count of DPs with Hash Issues
$HashInfo | group DP | Sort-Object Name | Select Count, Name