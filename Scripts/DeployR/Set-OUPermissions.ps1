<#
.SYNOPSIS
    Delegates the permissions needed for offline domain join on a target OU.
.DESCRIPTION
    Grants an account create and delete computer objects, read and write all properties, change
    and reset password, and validated write to DNS host name and service principal name.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Mikael Nystrom and Johan Arwidmark / deploymentresearch.com
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.1.0

    Change history:
      1.1.0 - 2026-06-02 - Initial release
#>

Param
(
    [parameter(mandatory=$true,HelpMessage="Please, provide a name.")]
    [ValidateNotNullOrEmpty()]
    $Account,

    [parameter(mandatory=$true,HelpMessage="Please, provide the target OU (DN below the domain).")]
    [ValidateNotNullOrEmpty()]
    $TargetOU,

    [parameter(mandatory=$true,HelpMessage="Specify whether the principal is a User or a Computer.")]
    [ValidateSet("User","Computer")]
    [string]$Type
)

# Start logging to screen
Write-host (get-date -Format u)" - Starting"

# This is what we typed in
Write-host "Account to search for is" $Account
Write-Host "OU to search for is" $TargetOU
Write-Host "Principal type is" $Type

$CurrentDomain = Get-ADDomain

$OrganizationalUnitDN = $TargetOU + "," + $CurrentDomain

# Look up the principal based on its type
switch ($Type) {
    "User" {
        $SearchAccount = Get-ADUser $Account
    }
    "Computer" {
        # Strip a trailing $ if the caller passed the SAM form (e.g. CM01$)
        $ComputerName = $Account.TrimEnd('$')
        $SearchAccount = Get-ADComputer $ComputerName
    }
}

if (-not $SearchAccount) {
    Write-Error "Could not find a $Type principal named '$Account' in $($CurrentDomain.DNSRoot). Aborting."
    return
}

$SAM = $SearchAccount.SamAccountName
$Principal = $CurrentDomain.NetBIOSName + "\" + $SAM

Write-Host "Principal is = $Principal"
Write-host "OU is =" $OrganizationalUnitDN

dsacls.exe $OrganizationalUnitDN /G $Principal":CCDC;Computer" /I:T | Out-Null
dsacls.exe $OrganizationalUnitDN /G $Principal":LC;;Computer" /I:S | Out-Null
dsacls.exe $OrganizationalUnitDN /G $Principal":RC;;Computer" /I:S | Out-Null
dsacls.exe $OrganizationalUnitDN /G $Principal":WD;;Computer" /I:S  | Out-Null
dsacls.exe $OrganizationalUnitDN /G $Principal":WP;;Computer" /I:S  | Out-Null
dsacls.exe $OrganizationalUnitDN /G $Principal":RP;;Computer" /I:S | Out-Null
dsacls.exe $OrganizationalUnitDN /G $Principal":CA;Reset Password;Computer" /I:S | Out-Null
dsacls.exe $OrganizationalUnitDN /G $Principal":CA;Change Password;Computer" /I:S | Out-Null
dsacls.exe $OrganizationalUnitDN /G $Principal":WS;Validated write to service principal name;Computer" /I:S | Out-Null
dsacls.exe $OrganizationalUnitDN /G $Principal":WS;Validated write to DNS host name;Computer" /I:S | Out-Null

Write-host (get-date -Format u)" - Done"
