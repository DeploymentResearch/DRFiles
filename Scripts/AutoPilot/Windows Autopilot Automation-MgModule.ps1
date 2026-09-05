<#
.SYNOPSIS
    Autopilot automation samples using the Graph PowerShell Module.
.DESCRIPTION
    The Graph PowerShell Module version of the Autopilot automation snippets, covering profile
    listing, JSON export, and device import.
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
      1.0.0 - 2024-10-01 - Initial release
#>

# Import the PowerShell modules
Import-Module WindowsAutopilotIntuneCommunity -MinimumVersion 2.5
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
