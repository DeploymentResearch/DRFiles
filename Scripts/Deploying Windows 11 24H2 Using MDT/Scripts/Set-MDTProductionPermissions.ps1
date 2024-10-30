#Requires -RunAsAdministrator

# Configure NTFS Permissions for the MDT Production deployment share
$DeploymentShareNTFS = "E:\MDTProduction"
icacls $DeploymentShareNTFS /grant '"VIAMONSTRA\MDT_BA":(OI)(CI)(RX)'
icacls $DeploymentShareNTFS /grant '"Users":(OI)(CI)(RX)'
icacls $DeploymentShareNTFS /grant '"Administrators":(OI)(CI)(F)'
icacls $DeploymentShareNTFS /grant '"SYSTEM":(OI)(CI)(F)'

# Configure Sharing Permissions for the MDT Build Lab deployment share
$DeploymentShare = "MDTProduction$"
Grant-SmbShareAccess -Name $DeploymentShare -AccountName "EVERYONE" -AccessRight Change -Force
Revoke-SmbShareAccess -Name $DeploymentShare -AccountName "CREATOR OWNER" -Force
