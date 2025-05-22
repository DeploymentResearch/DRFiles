# After uninstalling, close any PowerShell sessions

# Uninstall other Modules that may use it
Uninstall-Module IntuneStuff -AllVersions
Uninstall-Module WindowsAutoPilotIntune -AllVersions
Uninstall-Module WindowsAutopilotIntuneCommunity -AllVersions
Uninstall-Module IntuneDeviceInventory -AllVersions

# Uninstall Microsoft Graph (first all modules except Authentication, then the Authentication module)
Get-InstalledModule Microsoft.Graph.* | ForEach-Object { if($_.Name -ne "Microsoft.Graph.Authentication") { Uninstall-Module $_.Name -AllVersions } }
Uninstall-Module Microsoft.Graph.Authentication -AllVersions

# Close PowerShell sessions here....

# Install the latest version
Install-Module Microsoft.Graph -Verbose

# Get number of Modules
(Get-InstalledModule Microsoft.Graph.*).count