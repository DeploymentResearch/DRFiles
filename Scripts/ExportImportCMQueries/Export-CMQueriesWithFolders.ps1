# Export script for ConfigMgr queries, including folder structure
# Credits to Peter van der Woude (@pvanderwoude) for original Get-ObjectLocation function

$ExportPath = "E:\ExportedQueries"
$Logfile = "$ExportPath\QueryExport.log"
$SiteServer = "CM01"
$SiteCode = "PS1"

# Create path if not existing
If (!(Test-Path -Path $ExportPath)){ 
    # Export path $ExportPath does not esist, creating it"
    New-Item -Path $ExportPath -ItemType Directory
}

# Validate the path for good measure
If (!(Test-Path -Path $ExportPath)){ 
    Write-Warning "Export path $ExportPath does not exist, aborting..."
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

function Get-ObjectLocation {
    param (
    [string]$InstanceKey
    )
    $ObjectType = "7" # Queries are object type 7
    $ContainerNode = Get-WmiObject -Namespace root/SMS/site_$SiteCode -ComputerName $SiteServer -Query "SELECT ocn.* FROM SMS_ObjectContainerNode AS ocn JOIN SMS_ObjectContainerItem AS oci ON ocn.ContainerNodeID=oci.ContainerNodeID WHERE oci.ObjectType = '$ObjectType' and oci.InstanceKey='$InstanceKey'"
    if ($ContainerNode -ne $null) {
        $ObjectFolder = $ContainerNode.Name
        if ($ContainerNode.ParentContainerNodeID -eq 0) {
            $ParentFolder = $false
        }
        else {
            $ParentFolder = $true
            $ParentContainerNodeID = $ContainerNode.ParentContainerNodeID
        }
        while ($ParentFolder -eq $true) {
            $ParentContainerNode = Get-WmiObject -Namespace root/SMS/site_$SiteCode -ComputerName $SiteServer -Query "SELECT * FROM SMS_ObjectContainerNode WHERE ContainerNodeID = '$ParentContainerNodeID'"
            $ObjectFolder =  $ParentContainerNode.Name + "\" + $ObjectFolder
            if ($ParentContainerNode.ParentContainerNodeID -eq 0) {
                $ParentFolder = $false
            }
            else {
                $ParentContainerNodeID = $ParentContainerNode.ParentContainerNodeID
            }
        }
        $ObjectFolder = "Root\" + $ObjectFolder
        Write-Output $ObjectFolder
    }
    else {
        $ObjectFolder = "Root"
        Write-Output $ObjectFolder
    }
}

# Connect to ConfigMgr 
Write-Log "Connecting to ConfigMgr"
Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
cd "$SiteCode`:"

# Enumerating Custom ConfigMgr Queries (excluding the built-in queries)
Write-Log "Enumerating Custom ConfigMgr Queries"
$Queries = Get-CMQuery -Name * | Where-Object {$_.QueryID -inotlike 'SMS*'}
$NumberOfQueries = ($Queries | Measure-Object).Count
Write-Log "Number of Custom ConfigMgr Queries found is $NumberOfQueries"

# Abort if no custom queries found
If ($NumberOfQueries -eq 0){
    Write-warning "No custom queries found, aborting export..."
    Break
}

Foreach ($Query in $Queries){

    Write-Log  "Working on query: $Folder\$($Query.Name)"
    $Folder = Get-ObjectLocation -InstanceKey $($Query.QueryID)
    $TargetFolder = "$ExportPath\$Folder"
    If (!(Test-Path -Path $TargetFolder)){ 
        Write-Log "Target folder $TargetFolder does not esist, creating it..."
        New-Item -Path $TargetFolder -ItemType Directory | Out-Null
    } 
    $ExportFilePath = "$TargetFolder\$($Query.Name).mof"
    Write-Log "Exporting query: $Folder\$($Query.Name) to $TargetFolder"
    $Query | Export-CMQuery -ExportFilePath $ExportFilePath

}

