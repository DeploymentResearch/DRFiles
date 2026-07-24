Get-WindowsPackage -Online | Where-Object PackageName -like '*RollupFix*' |
    Select-Object PackageName, PackageState, InstallTime

Remove-WindowsPackage -Online -PackageName 'Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.8875.1.28' -NoRestart