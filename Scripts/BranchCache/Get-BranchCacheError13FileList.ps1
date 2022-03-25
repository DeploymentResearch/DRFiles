# Get all the event 13 from the BC event log and returns the URL of each file

[cmdletbinding()]
param(
    [Parameter(HelpMessage = "Enter the path you would like the CSV to be exported to.", Mandatory = $true)]
    [string]$LocalExportPath
)

$ExportFile = "$($LocalExportPath)\$($env:computerName).CSV"

# Delete any existing export file if it exists
If (Test-Path $ExportFile){Remove-Item $ExportFile -Force -ErrorAction SilentlyContinue -Confirm:$false}

# Query the BranchCache Event log

$AllEntries = try { 
    Get-WinEvent -LogName "Microsoft-Windows-BranchCache/Operational" | Where-Object {$_.ID -eq 13}
               }
    catch [Exception] {
        if ($_.Exception -match "There is not an event log") {
        #$(TimeStamp) + " No BranchCache Event Log found, exiting" | Out-File -FilePath $ExportFile -Append -Encoding ascii;
        Exit 0
    }
}

If (!$AllEntries){
    #$(TimeStamp) + " No BranchCache Event ID 13 found, exiting" | Out-File -FilePath $ExportFile -Append -Encoding ascii;
    Exit 0
}

# Get the data and build a new arraylist
[System.Collections.ArrayList]$EventInfo = @()
Foreach ($evt in $AllEntries){ 
    $TimeCreated = $evt.TimeCreated
    $event = [xml]$evt.ToXml()
    $url = $event.Event.UserData.PublishFailedEvent.ContentId
    # Create/Decode the URL from the hex content ID
    $DecodedURL = -join (
  
    $url | Select-String ".." -AllMatches | 
    ForEach-Object Matches | 

        ForEach-Object {
        If ([string]$_ -eq "00") {}
        Else{[char]+"0x$_"}
        }
    )

    $obj = [PSCustomObject]@{

        # Add values to arraylist
        TimeCreated = $TimeCreated
        ComputerName = $Env:ComputerName
        URL = $DecodedURL
    }

    # Add all the values
    $EventInfo.Add($obj)|Out-Null
}

$EventInfo | Export-Csv -Path $ExportFile -NoTypeInformation


