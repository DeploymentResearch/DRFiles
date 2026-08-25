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
