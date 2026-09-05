<#
.SYNOPSIS
    Connects WinPE to the Jurassic Deployment server share.
.DESCRIPTION
    Prompts for credentials and maps the deployment share to drive Z so the deployment script
    can be started from it.
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
      1.0.0 - 2022-11-03 - Initial release
#>

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
