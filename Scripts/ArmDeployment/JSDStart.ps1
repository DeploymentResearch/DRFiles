# Deployment Server Share
$DeployRoot = "\\DEV001\JurassicDeployment"

# Prompt for username and password 
$Cred = Get-Credential

# Connect to the server
try {
	New-PSDrive -Name Z -PSProvider FileSystem -Root $DeployRoot -Credential $Cred
}
catch {
	Write-Host "Could not connect to $DeployRoot, please run the JSDStart.ps1 script again"
    Break
}

# Start main deployment script
Z:\JSD.ps1