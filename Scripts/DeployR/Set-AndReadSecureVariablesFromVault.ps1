<#
.SYNOPSIS
    Sets and reads DeployR secrets from the secret vault.
.DESCRIPTION
    Shows how to store a password on the DeployR server with Set-Secret, and how to read it
    back from a task sequence step with Get-Secret, without ever writing it to disk.
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
      1.0.0 - 2026-08-25 - Initial release
#>

# On the DeployR Server
# Prompting for a secret via Read-Host (Great)
$password = Read-Host -Prompt 'Enter the admin password' -AsSecureString
Set-Secret -Vault DeployR -Name AdminPassword -Secret $password -Verbose

# In the TS (run on the client)

try {
    ${TSEnv:AdminPassword} = Get-Secret -Vault DeployR -Name "AdminPassword" | ConvertFrom-SecureString -AsPlainText -ErrorAction Stop
}
catch {
    Write-Warning "AdminPassword secret not found. Checking task sequence environment variable fallback."
}
