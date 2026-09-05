<#
.SYNOPSIS
    Gets the package ID of the ConfigMgr application currently running.
.DESCRIPTION
    Reads the available applications from the UIResourceMgr COM object and returns the package
    ID of the one that is currently executing, useful inside an install script.
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
      1.0.0 - 2022-01-02 - Initial release
#>

# Get Package ID from Running Script via Package
$SCCMClient = New-Object -ComObject UIResource.UIResourceMgr 
$PackageID = ($SCCMClient.GetAvailableApplications() | Where-Object { ($_.IsCurrentlyRunning -eq $true) }).PackageId
$PackageID | Out-file C:\Windows\Temp\PackageID.txt

# Get Application Details, including Package ID from Running Script via Package
$SCCMClient = New-Object -ComObject UIResource.UIResourceMgr 
$AppInfo = $SCCMClient.GetAvailableApplications() | Where-Object { ($_.IsCurrentlyRunning -eq $true) }
$AppInfo | Out-file C:\Windows\Temp\AppInfo.txt
