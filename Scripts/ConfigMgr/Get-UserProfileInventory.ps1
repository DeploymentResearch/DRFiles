# Run Scripts: enumerate user profiles with last logon and logoff times

$IncludeSizes = $true   # Calculate profile folder sizes (slow on machines with many or large profiles)
$ProfileList  = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'

# Combines the Low/High DWORD pair into a FILETIME and converts to local time
$ConvertTime = {
    param($Key, $Name)
    $Low  = $Key.GetValue("${Name}Low")
    $High = $Key.GetValue("${Name}High")
    if ($null -eq $Low -or $null -eq $High) { return $null }
    $Low  = [BitConverter]::ToUInt32([BitConverter]::GetBytes([int]$Low), 0)
    $High = [BitConverter]::ToUInt32([BitConverter]::GetBytes([int]$High), 0)
    $FileTime = ([uint64]$High -shl 32) -bor $Low
    if ($FileTime -eq 0) { return $null }
    [DateTime]::FromFileTime([long]$FileTime)
}

$Profiles = @(Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special })

$Results = foreach ($UserProfile in $Profiles) {
    # Resolve the SID to an account name; deleted or orphaned accounts fall back to the SID
    try {
        $Account = ([System.Security.Principal.SecurityIdentifier]$UserProfile.SID).Translate([System.Security.Principal.NTAccount]).Value
    }
    catch {
        $Account = $UserProfile.SID
    }

    $Key = Get-Item "$ProfileList\$($UserProfile.SID)" -ErrorAction SilentlyContinue
    $Logon = $null; $Logoff = $null
    if ($Key) {
        $Logon  = & $ConvertTime $Key 'LocalProfileLoadTime'
        $Logoff = & $ConvertTime $Key 'LocalProfileUnloadTime'
    }

    $SizeMB = $null
    if ($IncludeSizes) {
        $SizeMB = (Get-ChildItem $UserProfile.LocalPath -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB
    }

    [pscustomobject]@{ Account = $Account; Logon = $Logon; Logoff = $Logoff; Loaded = $UserProfile.Loaded; SizeMB = $SizeMB }
}

'Profiles: {0}' -f $Results.Count

foreach ($Item in ($Results | Sort-Object Logon -Descending)) {
    $LogonText  = if ($Item.Logon)  { $Item.Logon.ToString('yyyy-MM-dd HH:mm') }  else { 'Unknown' }
    $LogoffText = if ($Item.Logoff) { $Item.Logoff.ToString('yyyy-MM-dd HH:mm') } else { 'Unknown' }
    $SizeText   = if ($IncludeSizes) { '{0,8:N0} MB' -f $Item.SizeMB } else { '' }
    '  {0,-30} Logon {1,-16}  Logoff {2,-16} {3,-6} {4}' -f $Item.Account, $LogonText, $LogoffText,
        $(if ($Item.Loaded) { 'Loaded' } else { '' }), $SizeText
}