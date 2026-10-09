<#
Created:	 2013-01-08
Updated:     2026-06-02 - Added -Type parameter to support computer principals
Updated:     2026-10-04 - dsacls errors are now shown instead of hidden, all operations use the same domain controller, and the result is verified
Updated:     2026-10-04 - Added syntax validation of -TargetOU
Updated:     2026-10-04 - Errors are reported as single-line warnings
Version:	 1.4
Author       Mikael Nystrom and Johan Arwidmark
Homepage:    http://www.deploymentfundamentals.com

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and
is not supported by the authors or DeploymentArtist.

Author - Mikael Nystrom
    Twitter: @mikael_nystrom
    Blog   : http://deploymentbunny.com

Author - Johan Arwidmark
    Twitter: @jarwidmark
    Blog   : http://deploymentresearch.com

Usage examples:
    # Delegate to a user account (original behavior)
    .\Set-OUPermissions.ps1 -Account CM_JD -TargetOU "OU=Workstations,OU=ViaMonstra" -Type User

    # Delegate to a computer account (e.g., a server running an unattended service)
    .\Set-OUPermissions.ps1 -Account DEPLOYR01 -TargetOU "OU=Workstations,OU=ViaMonstra" -Type Computer
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

# Validate the syntax of the target OU: one or more OU=name (or CN=name) parts, without the domain part
$TargetOU = "$TargetOU".Trim().Trim(',')
if ($TargetOU -match '(^|,)\s*DC=') {
    Write-Warning "TargetOU '$TargetOU' includes the domain (DC=...). Specify only the part below the domain, for example ""OU=Workstations,OU=ViaMonstra"". Aborting."
    return
}
if ($TargetOU -notmatch '^\s*(OU|CN)=[^,=]+(\s*,\s*(OU|CN)=[^,=]+)*$') {
    # Suggest the most likely intended value, for example ViaMonstra -> OU=ViaMonstra
    $Suggestion = (($TargetOU -split ',') | ForEach-Object { $Part = $_.Trim(); if ($Part -match '^(OU|CN)=') { $Part } else { "OU=" + ($Part -replace '^.*=') } }) -join ','
    Write-Warning "TargetOU '$TargetOU' is not a valid distinguished name. Each part must start with OU= (or CN=), separated by commas. Did you mean ""$Suggestion""? Aborting."
    return
}

try {
    $CurrentDomain = Get-ADDomain -ErrorAction Stop
}
catch {
    Write-Warning "Could not read the domain information. Check that the ActiveDirectory PowerShell module is installed and that a domain controller is reachable. $($_.Exception.Message) Aborting."
    return
}

# Use one domain controller for everything. A newly created account may not have
# replicated yet, and dsacls would otherwise be free to pick a different DC than the lookups.
$DC = $CurrentDomain.PDCEmulator
Write-Host "Domain controller is" $DC

$OrganizationalUnitDN = $TargetOU + "," + $CurrentDomain.DistinguishedName

# Get-ADObject finds both organizational units (OU=) and containers (CN=)
$TargetObject = $null
try {
    $TargetObject = Get-ADObject -Identity $OrganizationalUnitDN -Server $DC -ErrorAction Stop
}
catch {
    # Not found, or not reachable: handled below
}
if (-not $TargetObject) {
    Write-Warning "Could not find '$OrganizationalUnitDN' in Active Directory. Check the spelling and the order of the OUs (innermost first). Aborting."
    return
}

# Look up the principal based on its type
$SearchAccount = $null
try {
    switch ($Type) {
        "User" {
            $SearchAccount = Get-ADUser $Account -Server $DC -ErrorAction Stop
        }
        "Computer" {
            # Strip a trailing $ if the caller passed the SAM form (e.g. CM01$)
            $ComputerName = "$Account".TrimEnd('$')
            $SearchAccount = Get-ADComputer $ComputerName -Server $DC -ErrorAction Stop
        }
    }
}
catch {
    # Not found: handled below
}

if (-not $SearchAccount) {
    Write-Warning "Could not find a $Type principal named '$Account' in $($CurrentDomain.DNSRoot). Aborting."
    return
}

$SAM = $SearchAccount.SamAccountName
$Principal = $CurrentDomain.NetBIOSName + "\" + $SAM

# \\server\DN makes dsacls use the same domain controller as the lookups above
$DsaclsTarget = "\\" + $DC + "\" + $OrganizationalUnitDN

Write-Host "Principal is = $Principal"
Write-host "OU is =" $OrganizationalUnitDN

# Permissions to grant: dsacls permission string, and inheritance (T = this object and sub objects, S = sub objects only)
$Permissions = @(
    @{ Permission = "CCDC;Computer";                                             Inheritance = "T" }
    @{ Permission = "LC;;Computer";                                              Inheritance = "S" }
    @{ Permission = "RC;;Computer";                                              Inheritance = "S" }
    @{ Permission = "WD;;Computer";                                              Inheritance = "S" }
    @{ Permission = "WP;;Computer";                                              Inheritance = "S" }
    @{ Permission = "RP;;Computer";                                              Inheritance = "S" }
    @{ Permission = "CA;Reset Password;Computer";                                Inheritance = "S" }
    @{ Permission = "CA;Change Password;Computer";                               Inheritance = "S" }
    @{ Permission = "WS;Validated write to service principal name;Computer";     Inheritance = "S" }
    @{ Permission = "WS;Validated write to DNS host name;Computer";              Inheritance = "S" }
)

$Failed = 0
foreach ($Item in $Permissions) {
    $Grant  = $Principal + ":" + $Item.Permission
    $Output = dsacls.exe $DsaclsTarget /G $Grant "/I:$($Item.Inheritance)" 2>&1 | Out-String

    if ($LASTEXITCODE -ne 0 -or $Output -notmatch 'completed successfully') {
        $Failed++
        # Show the last lines of the dsacls output, which hold the error text
        $Reason = (($Output -split "`r?`n" | Where-Object { $_.Trim() }) | Select-Object -Last 3) -join " | "
        Write-Warning "FAILED: $Grant (exit code $LASTEXITCODE): $Reason"
    }
    else {
        Write-Host "OK: $Grant"
    }
}

# Verify by reading the ACL back and counting the entries for the principal
$AclEntries = @(dsacls.exe $DsaclsTarget 2>&1 | Select-String -SimpleMatch $Principal)
Write-Host "Entries for $Principal on the OU after the change: $($AclEntries.Count)"

if ($Failed -gt 0) {
    Write-Warning "$Failed of $($Permissions.Count) permissions could not be set. See the warnings above."
}

Write-host (get-date -Format u)" - Done"
