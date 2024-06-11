# After uninstalling, close any PowerShell sessions
Uninstall-Module Microsoft.Graph -AllVersions
Uninstall-Module Microsoft.Graph.Beta -AllVersions # Assuming you have beta modules installed.

Uninstall-Module IntuneStuff -AllVersions
Uninstall-Module WindowsAutoPilotIntune -AllVersions
Uninstall-Module WindowsAutopilotIntuneCommunity -AllVersions

Get-InstalledModule Microsoft.Graph.* | ForEach-Object { if($_.Name -ne "Microsoft.Graph.Authentication") { Uninstall-Module $_.Name -AllVersions } }
Uninstall-Module Microsoft.Graph.Authentication -AllVersions


# Install the latest version
Install-Module Microsoft.Graph -Verbose
