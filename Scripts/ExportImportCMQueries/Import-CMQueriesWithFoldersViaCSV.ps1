# Import script for ConfigMgr queries, including folder structure

$ImportPath = "E:\ExportedQueries"
$ImportFile = "ExportedQueries.csv"
$Logfile = "$ExportPath\QueryImport.log"
$SiteServer = "CM01"
$SiteCode = "PS1"

# Validate the path for good measure
If (!(Test-Path -Path $ImportPath)){ 
    Write-Warning "Export path $ImportPath does not exist, aborting..."
    break
}

# Delete any existing logfile if it exists
If (Test-Path $Logfile){Remove-Item $Logfile -Force -ErrorAction SilentlyContinue -Confirm:$false}

Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
   )

   $TimeGenerated = $(Get-Date -UFormat "%D %T")
   $Line = "$TimeGenerated : $Message"
   Add-Content -Value $Line -Path $LogFile -Encoding Ascii

}

# Connect to ConfigMgr 
Write-Log "Connecting to ConfigMgr"
Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
cd "$SiteCode`:"

# Get previously exported queries
$ImportFiles = Get-ChildItem -Path "$ExportPath" -Recurse -Filter "*.mof"
$NumberOfQueries = ($ImportFiles | Measure-Object).Count
Write-Log "Number of Custom ConfigMgr Queries found in $ImportPath is $NumberOfQueries"

$Queries = Import-Csv -Path "$ImportPath\$ImportFile"
foreach($Query in $Queries){
    
    # Create a new query
    Write-Log "Creating query: New$($Query.Name) from import. Target folder is $($Query.Folder)"
    $Import = New-CMQuery -Name $Query.Name -Expression $Query.Expression  -TargetClassName $Query.TargetClassName -Comment $Query.Comment 

    
    # Section for moving object if needed
    If ($Query.Folder -eq "Root"){
        # Target folder is Root, no need to move
        Write-Log "Target folder is Root, no need to move"
        }
    Else{
        # Target folder is not Root, go ahead with move

        # Make sure target folder exists
        $FormattedFolderName = ($Query.Folder).Replace("Root\","")
        $TargetFolder = "$SiteCode`:\Query\$FormattedFolderName"

        if (test-path -path $TargetFolder){
            # All OK, proceed with move
            Write-Log "Moving query: $($Query.Name) to $TargetFolder"
            Move-CMObject -FolderPath $TargetFolder -InputObject $Import
        }
        Else{
            # Folder did not exist, creating folder structure
            # Ugly workaround since the CM Drive cannot create nested folders in one go
            $FoldersToCreate = $FormattedFolderName -split '[\\/]'
            $FolderDepth = ($FoldersToCreate | Measure-Object).Count

            # Limiting to five folder levels deep for now
            If ($FolderDepth -gt 5){
                Write-Log "More than five folder levels detected, you have to move $($Query.Name) manually, skipping..."
                Break
            }
            Else{
            
                # Yes again, its ugly, but it works...

                $RootFolder = "$SiteCode`:\Query"

                # Create folder level 0
                If ($FoldersToCreate[0]){
                    $FolderLevel0="$RootFolder\$($FoldersToCreate[0])"
                    If (!(Test-Path -Path $FolderLevel0)){
                        New-Item -Path $FolderLevel0 -ItemType directory
                    }
                }

                # Create folder level 1
                If ($FoldersToCreate[1]){
                    $FolderLevel1="$FolderLevel0\$($FoldersToCreate[1])"
                    If (!(Test-Path -Path $FolderLevel1)){
                        New-Item -Path $FolderLevel1 -ItemType directory
                    }
                }

                # Create folder level 2
                If ($FoldersToCreate[2]){
                    $FolderLevel2="$FolderLevel1\$($FoldersToCreate[2])"
                    If (!(Test-Path -Path $FolderLevel2)){
                        New-Item -Path $FolderLevel2 -ItemType directory
                    }
                }


                # Create folder level 3
                If ($FoldersToCreate[3]){
                    $FolderLevel3="$FolderLevel2\$($FoldersToCreate[3])"
                    If (!(Test-Path -Path $FolderLevel3)){
                        New-Item -Path $FolderLevel3 -ItemType directory
                    }
                }

                # Create folder level 4
                If ($FoldersToCreate[4]){
                    $FolderLevel4="$FolderLevel3\$($FoldersToCreate[4])"
                    If (!(Test-Path -Path $FolderLevel4)){
                        New-Item -Path $FolderLevel4 -ItemType directory
                    }
                }
         
            }
  
        Write-Log "Moving query: $($Query.Name) to $TargetFolder"
        Move-CMObject -FolderPath $TargetFolder -InputObject $Import

        }
    }

}