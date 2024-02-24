# Import the PowerShell modules
Import-Module WindowsAutopilotIntuneCommunity -MinimumVersion 3.0
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Identity.DirectoryManagement

# Connect to Micosoft Graph
# Note #1: Using the Connect-MgGraph cmdlet instead of older Connect-AutopilotIntune and Connect-MSGraph
# Note #2: Using Scopes limits the permissions available to an application.
$Scopes = @(
    "Device.ReadWrite.All", 
    "DeviceManagementManagedDevices.ReadWrite.All", 
    "DeviceManagementServiceConfig.ReadWrite.All", 
    "Domain.ReadWrite.All", 
    "Group.ReadWrite.All", 
    "GroupMember.ReadWrite.All", 
    "User.Read"
)
Connect-MgGraph -Scopes $Scopes

# List all Windows Autopilot deployment profiles
(Get-AutopilotProfile).displayName

# Select on of the supported Autopilot deployment profiles
# Note: In my lab, the profile I wanted to use is named UserDriven Scenario Standard User
$ProfileName = "UserDriven Scenario Standard User" 
$id = (Get-AutopilotProfile | Where-Object { $_.displayName -eq $ProfileName }).id

# Download the selected profile, convert it to JSON format, and save as ANSI file (By setting encoding to ASCII)
$OutPutFile = "C:\Windows\Temp\AutopilotConfigurationFile.json"
Get-AutopilotProfile -id $id | ConvertTo-AutopilotConfigurationJSON | Out-File $OutPutFile -Encoding ascii 
