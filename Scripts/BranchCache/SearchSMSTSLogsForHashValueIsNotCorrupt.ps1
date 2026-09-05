<#
.SYNOPSIS
    Searches archived smsts.log files for BranchCache content hash mismatches.
.DESCRIPTION
    Scans a log archive share for the hash mismatch message, groups the hits by log file, and
    exports the affected machines to a CSV file.
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
      1.0.0 - 2022-03-25 - Initial release
#>

$Path = "\\CM01\Logs$"
$Search = "Hash could not be matched for the downloaded content"
$LogFilesWithError = Get-ChildItem -Path $Path -Recurse -Filter smsts*.log | Select-String -pattern $Search | group path | select name
$ExportFile = "E:\HealthCheck\Results\Result from failed packages search in SMSTSLog Logfiles.csv"

# Export list to CSV for future (faster) lookup
#$ExportLogfileList = "E:\HealthCheck\Results\Hash value is not correct - Troubleshooting\SMSTS Logfiles List.csv" 
#$LogFilesWithError | Export-Csv -Path $ExportLogfileList -NoTypeInformation 

# Rerun import from saved list
#$LogFilesWithError = Import-Csv -LiteralPath $ExportLogfileList


# Count of Past two Months of Hash Value is not correct deployments
($LogFilesWithError | Measure-Object).Count

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

# Export to CSV File
$HashInfo | Export-Csv -Path $ExportFile -NoTypeInformation

# Count of packages with Hash Issues
$HashInfo | group PackageID | Sort-Object Name | Select Count, Name

# Count of DPs with Hash Issues
$HashInfo | group DP | Sort-Object Name | Select Count, Name
