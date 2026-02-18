$SiteCode = "PS1"
$ExportPath = "C:\Temp\ExportedTaskSequences"

# Create path if needed  
If (!(Test-Path $ExportPath)){New-Item -Path $ExportPath -ItemType Directory -Force }


# List all task sequences
Get-WmiObject SMS_TaskSequencePackage -Namespace root\sms\site_$SiteCode | Select-Object Name, PackageID

# List a specific task sequence
Get-WmiObject SMS_TaskSequencePackage -Namespace root\sms\site_$SiteCode | 
    Where-Object { $_.Name -eq "Windows 11 Enterprise x64 23H2 Native"} | 
    Select-Object Name, PackageID

# Export all task sequences (remove comment to specify specifc task sequence)
Set-Location $ExportPath

$TsList = Get-WmiObject SMS_TaskSequencePackage -Namespace root\sms\site_$SiteCode # | Where-Object { $_.Name -eq "Windows 11 Enterprise x64 23H2 Native MDM SQL"}
ForEach ($Ts in $TsList){
    $Ts = [wmi]"$($Ts.__PATH)"
    Set-Content -Path "$($ts.PackageId).xml" -Value $Ts.Sequence
}


# Search for MDT Templates
$SearchString = "BDD_"
$FilesWithMDTThings = Get-ChildItem -Path $ExportPath -Filter *.XML -recurse | Select-String -pattern $SearchString | Group-Object path | Select-Object name

$FilesWithMDTThings.count
