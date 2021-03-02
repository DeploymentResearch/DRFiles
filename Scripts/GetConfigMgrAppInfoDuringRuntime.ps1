# Get Package ID from Running Script via Package
$SCCMClient = New-Object -ComObject UIResource.UIResourceMgr 
$PackageID = ($SCCMClient.GetAvailableApplications() | Where-Object { ($_.IsCurrentlyRunning -eq $true) }).PackageId
$PackageID | Out-file C:\Windows\Temp\PackageID.txt

# Get Application Details, including Package ID from Running Script via Package
$SCCMClient = New-Object -ComObject UIResource.UIResourceMgr 
$AppInfo = $SCCMClient.GetAvailableApplications() | Where-Object { ($_.IsCurrentlyRunning -eq $true) }
$AppInfo | Out-file C:\Windows\Temp\AppInfo.txt