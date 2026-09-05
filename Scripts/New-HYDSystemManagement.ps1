<#
.SYNOPSIS
    Creates the System Management container in Active Directory for ConfigMgr.
.DESCRIPTION
    Creates the container under the domain System container if it does not exist, and grants
    the site server full control, which ConfigMgr needs for site publishing.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark / deploymentresearch.com
    Credits: Original ACL code snippet by Michael Niehaus, @mniehaus
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.1.0

    Change history:
      1.1.0 - 2026-08-06 - Initial release
#>

Param(
    [Parameter(mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [String]
    $SiteServer
)

# Import AD module and set default domain
Import-Module ActiveDirectory
$root = (Get-ADRootDSE).defaultNamingContext

# Get or create the System Management container
$ou = $null
try
{
    $ou = Get-ADObject "CN=System Management,CN=System,$root"
}
catch
{
    Write-Verbose "System Management container does not currently exist."
}

if ($ou -eq $null)
{
    $ou = New-ADObject -Type Container -name "System Management" -Path "CN=System,$root" -Passthru
}

# Get the current ACL for the OU
$acl = get-acl "ad:CN=System Management,CN=System,$root"

# Get the computer's SID
$computer = get-adcomputer $SiteServer

# Create a new access control entry to allow access to the OU
$identity = [System.Security.Principal.IdentityReference] $computer.SID
$adRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
$type = [System.Security.AccessControl.AccessControlType] "Allow"
$inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"
$ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$inheritanceType

# Add the ACE to the ACL, then set the ACL to save the changes
$acl.AddAccessRule($ace)
Set-acl -aclobject $acl "ad:CN=System Management,CN=System,$root"
