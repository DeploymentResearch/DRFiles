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