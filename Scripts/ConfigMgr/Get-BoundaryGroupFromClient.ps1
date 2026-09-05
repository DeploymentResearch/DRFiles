<#
.SYNOPSIS
    Returns the boundary group IDs a ConfigMgr client currently belongs to.
.DESCRIPTION
    Reads the boundary group cache from the client location services WMI namespace, which is
    the fastest way to confirm boundary group assignment on the device itself.
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
      1.0.0 - 2026-06-05 - Initial release
#>

$CMBGIDs = (Get-WmiObject -NameSpace Root\CCM\locationservices -Class boundarygroupcache).BoundaryGroupIDs 
$CMBGID = $CMBGIDs -join " "
$CMBGID
