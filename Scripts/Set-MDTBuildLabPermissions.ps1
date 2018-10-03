<#

************************************************************************************************************************

Created:	September 15, 2015
Version:	1.1

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and 
is not supported by the author or DeploymentArtist.

Author - Johan Arwidmark
    Twitter: @jarwidmark
    Blog   : http://deploymentresearch.com

************************************************************************************************************************

#>

# Check for elevation
Write-Host "Checking for elevation"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
    Write-Warning "Aborting script..."
    Break
}

# Configure NTFS Permissions for the MDT Build Lab deployment share
$DeploymentShareNTFS = "E:\MDTBuildLab"
icacls $DeploymentShareNTFS /grant '"VIAMONSTRA\MDT_BA":(OI)(CI)(RX)'
icacls $DeploymentShareNTFS /grant '"Administrators":(OI)(CI)(F)'
icacls $DeploymentShareNTFS /grant '"SYSTEM":(OI)(CI)(F)'
icacls "$DeploymentShareNTFS\Captures" /grant '"VIAMONSTRA\MDT_BA":(OI)(CI)(M)'

# Configure Sharing Permissions for the MDT Build Lab deployment share
$DeploymentShare = "MDTBuildLab$"
Grant-SmbShareAccess -Name $DeploymentShare -AccountName "EVERYONE" -AccessRight Change -Force
Revoke-SmbShareAccess -Name $DeploymentShare -AccountName "CREATOR OWNER" -Force


 