<#
.SYNOPSIS
    Delegates computer object permissions on an Active Directory OU.
.DESCRIPTION
    Grants the specified account the rights needed to create, delete, and manage computer
    objects in the target OU, which is what a deployment service account requires.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Mikael Nystrom and Johan Arwidmark / deploymentresearch.com
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2022-01-02 - Initial release
#>

Param
(
[parameter(mandatory=$true,HelpMessage="Please, provide the account name.")][ValidateNotNullOrEmpty()]$Account,
[parameter(mandatory=$true,HelpMessage="Please, provide the target OU.")][ValidateNotNullOrEmpty()]$TargetOU
)

# Start logging to screen
Write-host (get-date -Format u)" - Starting"

# This i what we typed in
Write-host "Account to search for is" $Account
Write-Host "OU to search for is" $TargetOU

if ($TargetOU -like '*dc=*')
{ 
    Write-Warning "Oupps, only specify the OU path. We get the domain for you..."
    Break
} 

$CurrentDomain = Get-ADDomain

$OrganizationalUnitDN = $TargetOU+","+$CurrentDomain
$SearchAccount = Get-ADUser $Account

$SAM = $SearchAccount.SamAccountName
$UserAccount = $CurrentDomain.NetBIOSName+"\"+$SAM

Write-Host "Account is = $UserAccount"
Write-host "OU is =" $OrganizationalUnitDN

dsacls.exe $OrganizationalUnitDN /G $UserAccount":CCDC;Computer" /I:T | Out-Null
dsacls.exe $OrganizationalUnitDN /G $UserAccount":LC;;Computer" /I:S | Out-Null
dsacls.exe $OrganizationalUnitDN /G $UserAccount":RC;;Computer" /I:S | Out-Null
dsacls.exe $OrganizationalUnitDN /G $UserAccount":WD;;Computer" /I:S  | Out-Null
dsacls.exe $OrganizationalUnitDN /G $UserAccount":WP;;Computer" /I:S  | Out-Null
dsacls.exe $OrganizationalUnitDN /G $UserAccount":RP;;Computer" /I:S | Out-Null
dsacls.exe $OrganizationalUnitDN /G $UserAccount":CA;Reset Password;Computer" /I:S | Out-Null
dsacls.exe $OrganizationalUnitDN /G $UserAccount":CA;Change Password;Computer" /I:S | Out-Null
dsacls.exe $OrganizationalUnitDN /G $UserAccount":WS;Validated write to service principal name;Computer" /I:S | Out-Null
dsacls.exe $OrganizationalUnitDN /G $UserAccount":WS;Validated write to DNS host name;Computer" /I:S | Out-Null
dsacls.exe $OrganizationalUnitDN
