<#
.SYNOPSIS
    Sets share and NTFS permissions on the MDT Build Lab deployment share.
.DESCRIPTION
    Grants the MDT build account read and execute on the folder, tightens the share level
    access, and removes the default Everyone permissions.
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
      1.0.0 - 2024-11-30 - Initial release
#>

#Requires -RunAsAdministrator

# Configure NTFS Permissions for the MDT Build Lab deployment share
$DeploymentShareNTFS = "E:\MDTBuildLab"
icacls $DeploymentShareNTFS /grant '"VIAMONSTRA\MDT_BA":(OI)(CI)(RX)'
icacls $DeploymentShareNTFS /grant '"Users":(OI)(CI)(RX)'
icacls $DeploymentShareNTFS /grant '"Administrators":(OI)(CI)(F)'
icacls $DeploymentShareNTFS /grant '"SYSTEM":(OI)(CI)(F)'
icacls "$DeploymentShareNTFS\Captures" /grant '"VIAMONSTRA\MDT_BA":(OI)(CI)(M)'

# Configure Sharing Permissions for the MDT Build Lab deployment share
$DeploymentShare = "MDTBuildLab$"
Grant-SmbShareAccess -Name $DeploymentShare -AccountName "EVERYONE" -AccessRight Change -Force
Revoke-SmbShareAccess -Name $DeploymentShare -AccountName "CREATOR OWNER" -Force
