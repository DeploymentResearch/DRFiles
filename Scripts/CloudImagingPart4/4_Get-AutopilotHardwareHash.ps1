# Install Nuget
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Create working folder
$AutopilotFolder = "C:\AutoPilot"
If (!(Test-Path $AutopilotFolder)){ New-Item $AutopilotFolder -ItemType Directory -Force }

# Save Autopilot script
Save-Script -Name Get-WindowsAutoPilotInfo -Path $AutopilotFolder

# Get the hardware hash 
& "$AutopilotFolder\Get-WindowsAutoPilotInfo.ps1"-OutputFile "$AutopilotFolder\$($env:ComputerName)_HWID.csv"