<#

************************************************************************************************************************

Created:	2015-03-01
Version:	1.1

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and 
is not supported by the author or DeploymentArtist.

Credits: 
Original ACL code snippet by Michael Niehaus (@mniehaus)
Additional ACL updates by Olaf Gradin (@gradindotcom)
http://blogs.technet.com/b/mniehaus/archive/2012/01/05/creating-the-configmgr-system-management-container-with-powershell.aspx

Author - Johan Arwidmark
    Twitter: @jarwidmark
    Blog   : http://deploymentresearch.com

************************************************************************************************************************

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