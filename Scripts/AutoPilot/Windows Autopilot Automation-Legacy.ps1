# No registration scenario (Windows 10 v1809 or above)
Install-Module AzureAD -Force
Install-module WindowsAutopilotIntune -Force

# Connect to Windows Autopilot / Microsoft Intune
Connect-AutopilotIntune

# List all Windows Autopilot deployment profiles
Get-AutopilotProfile | Select DisplayName

# Import Autopilot HWID
Import-AutoPilotCSV -csvFile "C:\tmp\AutoPilot_VIAMONS-7NRR01E.csv"

# Get a single profile
Get-AutopilotProfile -id "032ffec8-b62b-4e7a-a881-e2c949949ee3" # User No Registration Autopilot Scenario
Get-AutopilotProfile -id "32bac56e-bcb2-4451-8c91-984a0f0b796b" # Admin No Registration Autopilot Scenario
Get-AutopilotProfile -id "6274230f-8643-4aa2-84a1-fe3db5ffba77" # User Standard Registration Autopilot Scenario
Get-AutopilotProfile -id "e466861d-d13e-455f-a059-40bce86475b9" # Admin Standard Registration Autopilot Scenario

# Get a single profile and convert it to JSON format
Get-AutopilotProfile -id "32bac56e-bcb2-4451-8c91-984a0f0b796b" | ConvertTo-AutopilotConfigurationJSON # Admin No Registration Autopilot Scenario

# Get a single profile, convert it to JSON format, and save as ANSI file (By setting encoding to ASCII)
Get-AutopilotProfile -id "32bac56e-bcb2-4451-8c91-984a0f0b796b" | ConvertTo-AutopilotConfigurationJSON | Out-File "C:\Setup\AutopilotConfigurationFile.json" -Encoding ascii # Admin No Registration Autopilot Scenario
