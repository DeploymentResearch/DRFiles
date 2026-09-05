<#
.SYNOPSIS
    Creates and shares the MDT logs folder.
.DESCRIPTION
    Creates the logs folder, shares it as a hidden share, and grants the MDT build account
    modify permissions so deployments can write their logs centrally.
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
      1.0.0 - 2023-06-20 - Initial release
#>

#Requires -RunAsAdministrator

# Create and share the Logs folder
New-Item -Path E:\Logs -ItemType directory
New-SmbShare –Name Logs$ –Path E:\Logs -ChangeAccess EVERYONE
icacls E:\Logs /grant '"MDT_BA":(OI)(CI)(M)'
