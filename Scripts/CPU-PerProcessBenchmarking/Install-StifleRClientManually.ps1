# Find StifleR 2.6.9.0 install folder
$Length = 12288000 # Assume 2.6.9.0 version based on filesize 
$MSIName = "StifleR.ClientApp.Installer64.msi"
$Installer = "RunPS.cmd"
$FoldersToSearch = "C:\Windows\ccmcache","C:\Temp"

foreach ($Folder in $FoldersToSearch){
    Write-host "Checking folder: $Folder"
    $MSI = Get-ChildItem $Folder -Filter $MSIName -Recurse| Where-Object { $_.Length -eq $Length }
    If ($MSI){
        write-host "FFS1: $Folder"
        # Assume we found a match, stop the foreach loop and start the installer

        $InstallFolder = Split-Path $MSI.FullName
        $Result = Start-Process cmd.exe -ArgumentList "/c `"$InstallFolder\$Installer`"" -Wait

        if ($Result.ExitCode -eq 0) {
	        return "Success"
        } 
        elseif ($Result.ExitCode -gt 0) {
	        return "Failure, exit code is $($diskpart.ExitCode)"
        }
        else {
	        return "Failure, an unknown error occurred."
        }
        #Break
    }
    Else {
        return "Failure, no MSI file found"
    }
    write-host "FFS2: $Folder"
}

foreach ($Folder in $FoldersToSearch){
    Write-host "Checking folder: $Folder"
    $MSI = Get-ChildItem $Folder -Filter $MSIName -Recurse| Where-Object { $_.Length -eq $Length }
    write-host "FFS2: $Folder"
}

