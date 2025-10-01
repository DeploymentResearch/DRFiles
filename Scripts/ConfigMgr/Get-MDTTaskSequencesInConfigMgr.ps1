# Search for MDT Templates
$SearchString = "BDD"
$Path = "E:\Demo\ExportedTaskSequences"
$FilesWithMDTThings = Get-ChildItem -Path $Path -Filter *.XML -recurse | Select-String -pattern $SearchString | Group-Object path | Select-Object name

$FilesWithMDTThings.count