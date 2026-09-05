<#
.SYNOPSIS
    Tests the ConfigMgr AdminService PowerShell module.
.DESCRIPTION
    Imports the module, initialises the AdminService connection with credentials, and runs a
    device query to confirm the service is reachable and authenticating.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark / deploymentresearch.com
    Credits: ConfigMgr.AdminService module by Adam Gross, @AdamGrossTX
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2024-03-19 - Initial release
#>

# Testing the Johan Edition of the ConfigMgr.AdminService module
# Download the module from https://github.com/AdamGrossTX/ConfigMgr.AdminService/tree/JohanEdition
# Run the build.ps1 script to build the module and copy the result to a folder, C:\Setup in my example

# Import the module (Execution Policy must be configured to allow unsigned scripts)
Import-Module C:\Setup\ConfigMgr.AdminService\ConfigMgr.AdminService.psd1 -Verbose

# Specify the SMS Provider (typically the site server, but not always)
$SMSProvider = "cm01.corp.viamonstra.com"	

# Specify the credentials to use (will prompt)
$Cred = Get-Credential

# Initialize the AdminService
Initialize-CMAdminService -AdminServiceProviderURL "https://$SMSProvider/AdminService" -UseLocalAuth -LocalAuthCreds $Cred 

# Use the AdminService to get a device
Get-CMDevice -Name "PC0002"
