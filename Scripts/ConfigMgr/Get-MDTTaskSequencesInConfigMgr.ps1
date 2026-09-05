<#
.SYNOPSIS
    Finds MDT integrated task sequences among exported task sequence XML files.
.DESCRIPTION
    Searches the exported task sequence XML files for MDT template markers and reports which
    files still depend on the MDT integration.
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
      1.0.0 - 2025-10-01 - Initial release
#>

# Search for MDT Templates
$SearchString = "BDD"
$Path = "E:\Demo\ExportedTaskSequences"
$FilesWithMDTThings = Get-ChildItem -Path $Path -Filter *.XML -recurse | Select-String -pattern $SearchString | Group-Object path | Select-Object name

$FilesWithMDTThings.count
