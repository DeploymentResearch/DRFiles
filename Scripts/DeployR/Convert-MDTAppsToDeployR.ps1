<#
.SYNOPSIS
    Enumerates applications in an MDT deployment share, lets you review and select
    them in a UI, and creates the corresponding Application content items in DeployR.

.DESCRIPTION
    The script reads Control\Applications.xml directly from the MDT deployment share,
    so MDT itself does not need to be installed and the MDT PowerShell snap-in is not
    required. Each application is analysed and classified:

        Ready    The install command line is self contained and the source folder
                 exists, so it can be created in DeployR as is.
        Review   The application can be created, but something needs a human decision
                 (MDT script tokens in the command line, dependencies, no source files,
                 the application is disabled in MDT, and so on).
        Blocked  There is no sensible one to one mapping. Application bundles fall in
                 this category because DeployR models a bundle as a task sequence step
                 that installs a list of applications, not as a content item.

    Everything can be edited in the grid before creation. The DeployR name, version
    and installation command line columns are all editable.

    Creation in DeployR uses the documented pattern:

        New-DeployRContentItem -Type Folder -Purpose Application
        New-DeployRContentItemVersion -ContentItemId <id> -SourceFolder <path>
                                      -InstallationCommandLine <cmd>

    The new version is then set to Active with Set-DeployRMetadata, since a version
    is not Active when it is created and an inactive version will not deploy.

.PARAMETER DeploymentShare
    Path to the MDT deployment share root, for example D:\MDTProduction or
    \\MDT01\DeploymentShare$. The script expects Control\Applications.xml below it.

.PARAMETER ShareCredential
    Credential used to reach a remote MDT deployment share over UNC. The script
    establishes a Windows authenticated session to the share with WNetAddConnection2,
    which is what "net use" does, so the path stays a UNC path for every caller
    including the DeployR module. No drive letter is mapped. The session is torn
    down when the window closes.

    Omit this and the script uses your current Windows identity, which is fine when
    you already have access.

.PARAMETER DeployRUrl
    DeployR server URL, for example https://deployr01.corp.viamonstra.com:7281.
    Leave this out and the field is prepopulated with the local server's fully
    qualified name in that form, which is what you want when running on the DeployR
    server itself. A bare host name is accepted and normalised: type deployr01 and
    you get https://deployr01:7281.

.PARAMETER DeployRPort
    Port used when building the default URL. Defaults to 7281.

.PARAMETER Passcode
    Passcode used by Connect-DeployR. If omitted you can type it in the UI.

.PARAMETER DeployRModulePath
    Folder holding the DeployR.Utility module, or a direct path to the .psd1.
    Normally leave this out. The script is intended to run on the DeployR server,
    where the module is always installed, so it loads automatically at startup from
    the standard install locations and shows the version in the UI. Use this only to
    point at a non standard location.

.PARAMETER SourcesRoot
    Local folder that content is copied into before the DeployR content item is
    created, for example D:\DeployRSources\Applications. This is not optional. Every
    application is copied to <SourcesRoot>\<DeployR name>\<version>, which matches
    the layout used in the 2Pint documentation, and the content item is always built
    from that local copy rather than from the MDT share.

    The result is a clean local source tree you can maintain going forward, and an
    MDT share you can decommission afterwards without breaking DeployR.

    Leave this out and the field is prefilled with a suggestion based on the fixed
    drive with the most free space.

.PARAMETER ReportPath
    Default path offered when exporting the analysis to CSV.

.PARAMETER SkipSizeCalculation
    Skips the recursive size and file count calculation for each application source
    folder. Useful when the deployment share is remote and slow.

.EXAMPLE
    .\Convert-MDTAppsToDeployR.ps1 -DeploymentShare D:\MDTProduction

.EXAMPLE
    .\Convert-MDTAppsToDeployR.ps1 -DeploymentShare \\MDT01\DeploymentShare$ -Passcode 'P@ssw0rd' -SkipSizeCalculation

.EXAMPLE
    .\Convert-MDTAppsToDeployR.ps1 -DeploymentShare \\MDT01\DeploymentShare$ `
                                   -ShareCredential (Get-Credential VIAMONSTRA\svc-mdt) `
                                   -DeployRUrl 'https://deployr01.corp.viamonstra.com:7281'

.NOTES
    Author: Johan Arwidmark / deploymentresearch.com
    Twitter (X): @jarwidmark
    License: MIT
    LinkedIn: https://www.linkedin.com/in/jarwidmark
    Source:  https://github.com/DeploymentResearch/DRFiles

    Requires: PowerShell 7 (DeployR.Utility requirement), Windows with the .NET
              Desktop runtime for WPF, and STA. The script relaunches itself in STA
              if it detects an MTA apartment.

    Run this on the DeployR server. The DeployR.Utility module is installed there
    already, so it loads automatically at startup and the version is shown in the
    UI. The account needs read access to the MDT deployment share and write access
    in DeployR.

    Analysis and CSV export work without a DeployR connection, so you can survey a
    customer share before touching anything.

    DISCLAIMER: 
    This script is provided "as is" without warranty of any kind, express or implied.
    Use at your own risk — the author and DeploymentResearch assume no responsibility for any
    issues, damages, or data loss resulting from its use or modification.

    This script is shared in the spirit of community learning and improvement.
    You are welcome to adapt and redistribute it under the terms of the MIT License.    
#>

#Requires -Version 7.0

[CmdletBinding()]
param(
    [string]$DeploymentShare,

    [System.Management.Automation.PSCredential]$ShareCredential,

    [Alias('DeployRServer')]
    [string]$DeployRUrl,

    [int]$DeployRPort = 7281,

    [string]$Passcode,

    [string]$DeployRModulePath,

    [string]$SourcesRoot,

    [string]$ReportPath = (Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'MDT-To-DeployR-Report.csv'),

    [switch]$SkipSizeCalculation
)

# ---------------------------------------------------------------------------
# Apartment state guard
# ---------------------------------------------------------------------------
# PowerShell 7.1 and later default to STA on Windows, but a host or a profile can
# still put us in MTA, and WPF will not start there. Relaunch ourselves if needed.

if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne [System.Threading.ApartmentState]::STA) {

    if (-not $PSCommandPath) {
        throw 'This script must run in STA. Start pwsh.exe with -STA and run the script from a file.'
    }

    Write-Host 'Current apartment state is MTA. Relaunching in STA.' -ForegroundColor Yellow

    $relaunchArgs = @('-STA', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath)

    foreach ($key in $PSBoundParameters.Keys) {
        $value = $PSBoundParameters[$key]
        if ($value -is [switch]) {
            if ($value.IsPresent) { $relaunchArgs += "-$key" }
        }
        else {
            $relaunchArgs += "-$key"
            $relaunchArgs += [string]$value
        }
    }

    Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList $relaunchArgs
    return
}

if ($IsWindows -eq $false) {
    throw 'This script requires Windows. WPF and the DeployR.Utility module are Windows only.'
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml

# ---------------------------------------------------------------------------
# Script scope state
# ---------------------------------------------------------------------------

$script:Rows              = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$script:GuidLookup        = @{}
$script:DeployRConnected  = $false
$script:ExistingApps      = @()
$script:Window            = $null
$script:Controls          = @{}
$script:ConnectedShares   = New-Object System.Collections.Generic.List[string]
$script:AuthSummary       = ''
$script:TokenExpiry       = ''

# Status colours, matched to the dark theme. The named brushes such as DarkGreen
# are far too dim to read against a navy background.
$script:BrushOk    = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(0x3D, 0xD6, 0x8C))
$script:BrushBad   = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(0xE0, 0x48, 0x3E))
$script:BrushWarn  = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(0xF0, 0xA9, 0x3B))
$script:BrushMuted = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(0x8F, 0xA3, 0xBF))


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-UILog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Info', 'Warn', 'Error', 'Success')][string]$Level = 'Info'
    )

    $stamp = (Get-Date).ToString('HH:mm:ss')
    $line  = '{0}  [{1}]  {2}' -f $stamp, $Level.ToUpper().PadRight(7), $Message

    if ($script:Controls.ContainsKey('TxtLog') -and $script:Controls.TxtLog) {
        $script:Controls.TxtLog.AppendText($line + [Environment]::NewLine)
        $script:Controls.TxtLog.ScrollToEnd()
    }

    switch ($Level) {
        'Warn'    { Write-Host $line -ForegroundColor Yellow }
        'Error'   { Write-Host $line -ForegroundColor Red }
        'Success' { Write-Host $line -ForegroundColor Green }
        default   { Write-Host $line }
    }
}

function Invoke-UIRefresh {
    # The classic WPF equivalent of DoEvents. Keeps the window responsive while we
    # run a long synchronous loop on the UI thread.
    [CmdletBinding()]
    param()

    if (-not $script:Window) { return }

    $frame = New-Object System.Windows.Threading.DispatcherFrame
    $callback = [System.Windows.Threading.DispatcherOperationCallback] {
        param($state)
        $state.Continue = $false
        return $null
    }
    $null = $script:Window.Dispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Background,
        $callback,
        $frame)
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
}

function Get-XmlNodeText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Node,
        [Parameter(Mandatory)][string]$Name
    )

    $child = $Node.SelectSingleNode($Name)
    if ($null -eq $child) { return '' }
    return ([string]$child.InnerText).Trim()
}

function Resolve-MdtPath {
    # MDT stores paths relative to the deployment share root, for example
    # .\Applications\Adobe Reader. Turn that into a real path.
    [CmdletBinding()]
    param(
        [string]$RelativePath,
        [Parameter(Mandatory)][string]$ShareRoot
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) { return '' }

    $value = $RelativePath.Trim()

    if ($value.StartsWith('.\')) {
        return (Join-Path -Path $ShareRoot -ChildPath $value.Substring(2))
    }
    if ($value.StartsWith('.')) {
        return (Join-Path -Path $ShareRoot -ChildPath $value.TrimStart('.', '\'))
    }
    if ($value.StartsWith('\\') -or $value -match '^[A-Za-z]:\\') {
        return $value
    }

    return (Join-Path -Path $ShareRoot -ChildPath $value)
}

# ---------------------------------------------------------------------------
# Credentialed access to a remote deployment share
# ---------------------------------------------------------------------------
# PowerShell cannot pass a credential to Test-Path, Get-Content or Get-ChildItem
# for a UNC path, and New-PSDrive -Credential only helps PowerShell provider
# cmdlets, not .NET calls or the DeployR module.
#
# So we do what "net use \\server\share /user:..." does and call WNetAddConnection2
# with no local device name. That authenticates the session to that server, after
# which every caller in this process, including DeployR.Utility, can read the plain
# UNC path with no drive letter involved.

if (-not ('DeployRMigration.NativeMethods' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace DeployRMigration
{
    public static class NativeMethods
    {
        [StructLayout(LayoutKind.Sequential)]
        public struct NETRESOURCE
        {
            public int dwScope;
            public int dwType;
            public int dwDisplayType;
            public int dwUsage;
            [MarshalAs(UnmanagedType.LPWStr)] public string lpLocalName;
            [MarshalAs(UnmanagedType.LPWStr)] public string lpRemoteName;
            [MarshalAs(UnmanagedType.LPWStr)] public string lpComment;
            [MarshalAs(UnmanagedType.LPWStr)] public string lpProvider;
        }

        [DllImport("mpr.dll", CharSet = CharSet.Unicode)]
        public static extern int WNetAddConnection2(
            ref NETRESOURCE lpNetResource, string lpPassword, string lpUsername, int dwFlags);

        [DllImport("mpr.dll", CharSet = CharSet.Unicode)]
        public static extern int WNetCancelConnection2(string lpName, int dwFlags, bool fForce);

        [DllImport("dwmapi.dll", PreserveSig = true)]
        public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
    }
}
'@
}

function Set-WindowChrome {
    <#
    .SYNOPSIS
        Applies a dark title bar and rounded corners to the window.

    .DESCRIPTION
        Rather than going down the WindowStyle None and AllowsTransparency route,
        which means hand rolling drag, resize, snap and maximise behaviour, this
        asks the desktop window manager to restyle the standard frame. The window
        keeps every bit of normal Windows behaviour and just looks right.

        Every call is best effort. Older builds return a failure code for
        attributes they do not know about, which is fine, the window simply keeps
        the default frame.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.Windows.Window]$Window)

    $DWMWA_USE_IMMERSIVE_DARK_MODE = 20   # Windows 10 2004 and later
    $DWMWA_WINDOW_CORNER_PREFERENCE = 33  # Windows 11
    $DWMWA_BORDER_COLOR             = 34  # Windows 11
    $DWMWA_CAPTION_COLOR            = 35  # Windows 11
    $DWMWA_TEXT_COLOR               = 36  # Windows 11

    $DWMWCP_ROUND = 2

    try {
        $handle = (New-Object System.Windows.Interop.WindowInteropHelper($Window)).Handle
        if ($handle -eq [IntPtr]::Zero) { return }

        # COLORREF is 0x00BBGGRR, so the byte order is reversed from HTML.
        $captionColor = 0x0020120B   # #0B1220
        $borderColor  = 0x003F2A1F   # #1F2A3F
        $textColor    = 0x00F7EDE6   # #E6EDF7

        $enable = 1

        $null = [DeployRMigration.NativeMethods]::DwmSetWindowAttribute($handle, $DWMWA_USE_IMMERSIVE_DARK_MODE, [ref]$enable, 4)

        $corner = $DWMWCP_ROUND
        $null = [DeployRMigration.NativeMethods]::DwmSetWindowAttribute($handle, $DWMWA_WINDOW_CORNER_PREFERENCE, [ref]$corner, 4)

        $null = [DeployRMigration.NativeMethods]::DwmSetWindowAttribute($handle, $DWMWA_CAPTION_COLOR, [ref]$captionColor, 4)
        $null = [DeployRMigration.NativeMethods]::DwmSetWindowAttribute($handle, $DWMWA_BORDER_COLOR,  [ref]$borderColor,  4)
        $null = [DeployRMigration.NativeMethods]::DwmSetWindowAttribute($handle, $DWMWA_TEXT_COLOR,    [ref]$textColor,    4)
    }
    catch {
        # Not fatal. The window just keeps the default light frame.
    }
}

function Get-ShareRoot {
    <#
    .SYNOPSIS
        Returns the \\server\share portion of a UNC path, or an empty string for
        anything that is not UNC.
    #>
    [CmdletBinding()]
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return '' }

    $value = $Path.Trim().Trim('"')
    if (-not $value.StartsWith('\\')) { return '' }

    $parts = $value.TrimStart('\').Split('\', [StringSplitOptions]::RemoveEmptyEntries)
    if ($parts.Count -lt 2) { return '' }

    return ('\\{0}\{1}' -f $parts[0], $parts[1])
}

function Get-WNetErrorText {
    [CmdletBinding()]
    param([int]$Code)

    $hint = switch ($Code) {
        5    { 'Access denied. The account is valid but has no rights on the share.' }
        53   { 'Network path not found. Check the server name and that it is reachable.' }
        67   { 'Network name not found. The server answered but the share name is wrong.' }
        86   { 'The password is not valid for this share.' }
        1219 { 'A connection to this server already exists under different credentials. Windows allows only one set of credentials per server.' }
        1326 { 'Logon failure. Check the user name and password.' }
        1327 { 'Logon restriction. Blank passwords and some account policies are refused for network logon.' }
        2202 { 'The user name is not valid. Try DOMAIN\user or user@domain.' }
        default { '' }
    }

    $native = ([System.ComponentModel.Win32Exception]::new($Code)).Message

    if ($hint) { return ('{0} (error {1}: {2})' -f $hint, $Code, $native) }
    return ('Error {0}: {1}' -f $Code, $native)
}

function Connect-NetworkShare {
    <#
    .SYNOPSIS
        Opens an authenticated session to a UNC share without mapping a drive.

    .PARAMETER Path
        Any path below the share. The \\server\share root is worked out from it.

    .PARAMETER Credential
        Credential to authenticate with. Omit to use the current identity, in which
        case this function does nothing and returns success.

    .PARAMETER Force
        On error 1219, drop the existing session to that server and try again.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [System.Management.Automation.PSCredential]$Credential,
        [switch]$Force
    )

    $shareRoot = Get-ShareRoot -Path $Path

    if (-not $shareRoot) {
        # Local path, nothing to authenticate against.
        return [pscustomobject]@{ Connected = $false; ShareRoot = ''; Code = 0; Message = 'Local path, no network session needed.' }
    }

    if (-not $Credential) {
        return [pscustomobject]@{ Connected = $false; ShareRoot = $shareRoot; Code = 0; Message = 'Using the current Windows identity.' }
    }

    $userName = $Credential.UserName
    $password = $Credential.GetNetworkCredential().Password

    $resource = New-Object DeployRMigration.NativeMethods+NETRESOURCE
    $resource.dwType       = 1          # RESOURCETYPE_DISK
    $resource.lpLocalName  = $null      # no drive letter, keep the path as UNC
    $resource.lpRemoteName = $shareRoot
    $resource.lpProvider   = $null

    Write-UILog -Message ("Connecting to {0} as {1}" -f $shareRoot, $userName)

    $code = [DeployRMigration.NativeMethods]::WNetAddConnection2([ref]$resource, $password, $userName, 0)

    if ($code -eq 1219 -and $Force) {
        Write-UILog -Message 'An existing session to this server is in the way. Dropping it and retrying.' -Level 'Warn'
        $null = [DeployRMigration.NativeMethods]::WNetCancelConnection2($shareRoot, 0, $true)
        $code = [DeployRMigration.NativeMethods]::WNetAddConnection2([ref]$resource, $password, $userName, 0)
    }

    # Blank the password out of memory as soon as we are done with it.
    $password = $null

    if ($code -eq 0) {
        if ($script:ConnectedShares -notcontains $shareRoot) { $script:ConnectedShares.Add($shareRoot) }
        Write-UILog -Message ("Connected to {0}" -f $shareRoot) -Level 'Success'
        return [pscustomobject]@{ Connected = $true; ShareRoot = $shareRoot; Code = 0; Message = 'Connected.' }
    }

    return [pscustomobject]@{
        Connected = $false
        ShareRoot = $shareRoot
        Code      = $code
        Message   = (Get-WNetErrorText -Code $code)
    }
}

function Disconnect-NetworkShares {
    <#
    .SYNOPSIS
        Tears down only the sessions this script established.
    #>
    [CmdletBinding()]
    param()

    foreach ($share in @($script:ConnectedShares)) {
        try {
            $code = [DeployRMigration.NativeMethods]::WNetCancelConnection2($share, 0, $true)
            if ($code -eq 0) { Write-UILog -Message ("Disconnected from {0}" -f $share) }
            else { Write-UILog -Message ("Could not disconnect from {0}. {1}" -f $share, (Get-WNetErrorText -Code $code)) -Level 'Warn' }
        }
        catch {
            Write-UILog -Message ("Could not disconnect from {0}. {1}" -f $share, $_.Exception.Message) -Level 'Warn'
        }
    }

    $script:ConnectedShares.Clear()
}

function Get-ShareCredentialFromUI {
    <#
    .SYNOPSIS
        Builds a PSCredential from the UI fields, or returns null when alternate
        credentials are switched off.
    #>
    [CmdletBinding()]
    param()

    if (-not $script:Controls.ChkUseShareCreds.IsChecked) { return $null }

    $user = $script:Controls.TxtShareUser.Text
    if ([string]::IsNullOrWhiteSpace($user)) {
        throw 'Alternate credentials are enabled but no user name was entered. Use DOMAIN\user or user@domain.'
    }

    $securePassword = $script:Controls.TxtSharePassword.SecurePassword
    return (New-Object System.Management.Automation.PSCredential($user.Trim(), $securePassword))
}

# ---------------------------------------------------------------------------
# MDT inventory
# ---------------------------------------------------------------------------

function Test-MdtCommandLine {
    <#
    .SYNOPSIS
        Works out whether an MDT install command line will still work once the
        application is a DeployR content item.

    .DESCRIPTION
        The naive approach is to look for cscript, wscript or a .wsf extension and
        call it a problem. That is wrong. MDT applications very often ship their own
        script inside the application folder, and DeployR extracts that content and
        runs the command line from it, so those work unchanged.

        What actually breaks is a reference to something outside the application
        folder:

          1. MDT path variables such as %SCRIPTROOT% and %DEPLOYROOT%, which point
             at the deployment share and do not exist in DeployR.
          2. A script that is not in the application source at all.
          3. A script that is in the application source but pulls in the MDT script
             library, ZTIUtility.vbs being the usual one, or talks to the MDT or
             ConfigMgr task sequence environment.

        The third case is the one worth the effort, because it looks completely
        self contained from the command line alone. So when the referenced script
        is present, it gets read.

    .OUTPUTS
        An object with Issues (status affecting) and Notes (informational).
    #>
    [CmdletBinding()]
    param(
        [string]$CommandLine,
        [string]$SourceFolder
    )

    $issues = New-Object System.Collections.Generic.List[string]
    $notes  = New-Object System.Collections.Generic.List[string]

    if ([string]::IsNullOrWhiteSpace($CommandLine)) {
        return [pscustomobject]@{ Issues = $issues; Notes = $notes }
    }

    # 1. MDT path variables. These are the ones that genuinely will not resolve.
    $mdtPathVars = @('%SCRIPTROOT%', '%DEPLOYROOT%', '%RESOURCEROOT%', '%DEPLOYDRIVE%', '%TOOLROOT%')
    $found = @($mdtPathVars | Where-Object { $CommandLine -match [regex]::Escape($_) })

    if ($found.Count -gt 0) {
        $issues.Add(('Command line uses the MDT path variable {0}, which points at the deployment share and does not exist in DeployR.' -f ($found -join ', ')))
    }
    else {
        # Any other percent delimited token is worth a mention but is often just a
        # normal Windows environment variable such as %ProgramFiles%.
        $others = @([regex]::Matches($CommandLine, '%[A-Za-z_][A-Za-z0-9_()]*%') | ForEach-Object { $_.Value } | Select-Object -Unique)
        if ($others.Count -gt 0) {
            $notes.Add(('Command line references {0}. Confirm it resolves on the target during deployment.' -f ($others -join ', ')))
        }
    }

    # 2 and 3. Find the script the command line runs, if any.
    $scriptPattern = '(?<file>[^\s"'']+\.(?:wsf|vbs|ps1|cmd|bat|js))'
    $match = [regex]::Match($CommandLine, $scriptPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    if (-not $match.Success) {
        return [pscustomobject]@{ Issues = $issues; Notes = $notes }
    }

    $scriptRef = $match.Groups['file'].Value.Trim('"', "'")

    # Only judge a script we can actually locate relative to the application.
    if ([string]::IsNullOrWhiteSpace($SourceFolder) -or -not (Test-Path -LiteralPath $SourceFolder -PathType Container)) {
        return [pscustomobject]@{ Issues = $issues; Notes = $notes }
    }

    # A rooted or variable driven reference is not relative to the application.
    if ($scriptRef -match '^[A-Za-z]:\\' -or $scriptRef.StartsWith('\\') -or $scriptRef -match '%') {
        return [pscustomobject]@{ Issues = $issues; Notes = $notes }
    }

    $scriptPath = Join-Path -Path $SourceFolder -ChildPath $scriptRef

    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        $found = @(Get-ChildItem -LiteralPath $SourceFolder -Filter ([System.IO.Path]::GetFileName($scriptRef)) -Recurse -File -ErrorAction SilentlyContinue |
                   Select-Object -First 1)
        if ($found.Count -eq 0) {
            $issues.Add(("The command line runs '{0}' but that file is not in the application source." -f $scriptRef))
            return [pscustomobject]@{ Issues = $issues; Notes = $notes }
        }
        $scriptPath = $found[0].FullName
    }

    # The script is here. Does it depend on MDT itself?
    try {
        $content = Get-Content -LiteralPath $scriptPath -Raw -ErrorAction Stop
    }
    catch {
        $notes.Add(("Could not read '{0}' to check for MDT dependencies." -f $scriptRef))
        return [pscustomobject]@{ Issues = $issues; Notes = $notes }
    }

    $libraryHits = @()
    foreach ($marker in @('ZTIUtility', 'ZTIDataAccess', 'ZTIConfigFile', 'ZTIGather', 'Microsoft.BDD', 'Microsoft.SMS.TSEnvironment')) {
        if ($content -match [regex]::Escape($marker)) { $libraryHits += $marker }
    }

    if ($libraryHits.Count -gt 0) {
        $issues.Add(("'{0}' pulls in the MDT script library ({1}). It will not run under DeployR without rework." -f $scriptRef, ($libraryHits -join ', ')))
    }
    else {
        $notes.Add(("Runs '{0}' from the application source, which is self contained." -f $scriptRef))
    }

    return [pscustomobject]@{ Issues = $issues; Notes = $notes }
}

function Get-MdtApplicationInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ShareRoot,
        [switch]$SkipSize
    )

    $controlFile = Join-Path -Path $ShareRoot -ChildPath 'Control\Applications.xml'

    if (-not (Test-Path -LiteralPath $controlFile)) {
        throw "Applications.xml was not found at '$controlFile'. Point -DeploymentShare at the share root, not the Control folder."
    }

    Write-UILog -Message "Reading $controlFile"

    [xml]$xml = Get-Content -LiteralPath $controlFile -Raw -ErrorAction Stop

    $nodes = $xml.SelectNodes('//application')
    if ($null -eq $nodes -or $nodes.Count -eq 0) {
        Write-UILog -Message 'No application nodes found in Applications.xml.' -Level 'Warn'
        return @()
    }

    Write-UILog -Message ('Found {0} node(s) in Applications.xml' -f $nodes.Count)

    # First pass, build a guid to name map so dependencies can be resolved by name.
    $script:GuidLookup = @{}
    foreach ($node in $nodes) {
        $guid = [string]$node.guid
        if ($guid) {
            $script:GuidLookup[$guid] = (Get-XmlNodeText -Node $node -Name 'Name')
        }
    }

    $results = New-Object System.Collections.Generic.List[object]
    $index   = 0

    foreach ($node in $nodes) {

        $index++

        # MDT keeps folder nodes in the same file. Skip them.
        $nodeType = [string]$node.type
        if ($nodeType -and $nodeType -match 'folder') { continue }

        $name = Get-XmlNodeText -Node $node -Name 'Name'
        if ([string]::IsNullOrWhiteSpace($name)) { continue }

        $shortName   = Get-XmlNodeText -Node $node -Name 'ShortName'
        $version     = Get-XmlNodeText -Node $node -Name 'Version'
        $publisher   = Get-XmlNodeText -Node $node -Name 'Publisher'
        $language    = Get-XmlNodeText -Node $node -Name 'Language'
        $commandLine = Get-XmlNodeText -Node $node -Name 'CommandLine'
        $workingDir  = Get-XmlNodeText -Node $node -Name 'WorkingDirectory'
        $source      = Get-XmlNodeText -Node $node -Name 'Source'
        $files       = Get-XmlNodeText -Node $node -Name 'Files'
        $comments    = Get-XmlNodeText -Node $node -Name 'Comments'
        $uninstall   = Get-XmlNodeText -Node $node -Name 'UninstallKey'
        $reboot      = Get-XmlNodeText -Node $node -Name 'Reboot'
        $guid        = [string]$node.guid

        $enabled = $true
        if ($node.enable -and [string]$node.enable -match '^(false|0)$') { $enabled = $false }

        $hidden = $false
        if ($node.hide -and [string]$node.hide -match '^(true|1)$') { $hidden = $true }

        # Dependencies. MDT stores these as repeated <Dependency> elements whose
        # text content is the GUID of the other application. Some tooling writes
        # nested <guid> children instead, so both shapes are handled.
        $dependencyGuids = @()

        foreach ($depNode in $node.SelectNodes('Dependency')) {

            $nested = $depNode.SelectNodes('guid')

            if ($nested -and $nested.Count -gt 0) {
                foreach ($g in $nested) {
                    $value = ([string]$g.InnerText).Trim()
                    if ($value) { $dependencyGuids += $value }
                }
            }
            else {
                $value = ([string]$depNode.InnerText).Trim()
                if ($value) { $dependencyGuids += $value }
            }
        }

        $dependencyNames  = @()
        $unresolvedDeps   = @()

        foreach ($g in $dependencyGuids) {
            if ($script:GuidLookup.ContainsKey($g)) { $dependencyNames += $script:GuidLookup[$g] }
            else {
                $dependencyNames += $g
                $unresolvedDeps  += $g
            }
        }

        # Supported platforms
        $platforms = @()
        $platformNode = $node.SelectSingleNode('SupportedPlatform')
        if ($platformNode) {
            foreach ($p in $platformNode.ChildNodes) {
                $value = ([string]$p.InnerText).Trim()
                if ($value) { $platforms += $value }
            }
        }

        # Work out where the content lives. WorkingDirectory is the authoritative
        # value in MDT, Source and Files are the fallbacks.
        $relativeSource = $workingDir
        if ([string]::IsNullOrWhiteSpace($relativeSource)) { $relativeSource = $source }
        if ([string]::IsNullOrWhiteSpace($relativeSource) -and $files) {
            $relativeSource = ".\Applications\$files"
        }

        $resolvedSource = Resolve-MdtPath -RelativePath $relativeSource -ShareRoot $ShareRoot

        $sourceExists = $false
        if ($resolvedSource) {
            $sourceExists = Test-Path -LiteralPath $resolvedSource -PathType Container
        }

        $fileCount = 0
        $sizeMB    = 0.0

        if ($sourceExists -and -not $SkipSize) {
            try {
                $measured = Get-ChildItem -LiteralPath $resolvedSource -Recurse -File -Force -ErrorAction SilentlyContinue |
                            Measure-Object -Property Length -Sum
                $fileCount = [int]$measured.Count
                if ($measured.Sum) { $sizeMB = [math]::Round($measured.Sum / 1MB, 2) }
            }
            catch {
                Write-UILog -Message ("Could not measure content for '{0}': {1}" -f $name, $_.Exception.Message) -Level 'Warn'
            }
        }

        # -------------------------------------------------------------------
        # Classification
        # -------------------------------------------------------------------
        # Two separate lists, and the distinction matters.
        #
        #   issues  Something that stops this application working in DeployR if
        #           imported as it stands. These set the status.
        #   notes   Something true about the application that you need to know
        #           when rebuilding the task sequence, but which does not affect
        #           whether the content item itself converts. These never change
        #           the status.
        #
        # Dependencies, reboot flags, platform filters and the MDT enable flag all
        # belong in the second group. An application is not broken because another
        # application has to install before it.
        $issues = New-Object System.Collections.Generic.List[string]
        $notes  = New-Object System.Collections.Generic.List[string]
        $status = 'Ready'

        $isBundle = ([string]::IsNullOrWhiteSpace($commandLine) -and $dependencyGuids.Count -gt 0)

        if ($isBundle) {
            $status = 'Blocked'
            $issues.Add('Application bundle. Recreate as a task sequence step that installs the list of applications.')
        }
        elseif ([string]::IsNullOrWhiteSpace($commandLine)) {
            $status = 'Blocked'
            $issues.Add('No install command line in MDT.')
        }

        if (-not $isBundle) {

            if (-not $sourceExists) {
                if ($status -ne 'Blocked') { $status = 'Review' }
                if ([string]::IsNullOrWhiteSpace($relativeSource)) {
                    $issues.Add('No source folder. This looks like a NoSource application, so the command line must be fully self contained.')
                }
                else {
                    $issues.Add("Source folder not found: $resolvedSource")
                }
            }
            elseif ($fileCount -eq 0 -and -not $SkipSize) {
                if ($status -ne 'Blocked') { $status = 'Review' }
                $issues.Add('Source folder exists but is empty.')
            }

            # Analyse the command line properly rather than pattern matching on the
            # name of an interpreter. Running cscript against a script that ships
            # inside the application folder is perfectly fine. What breaks is a
            # reference to the MDT share or the MDT script library.
            $analysis = Test-MdtCommandLine -CommandLine $commandLine -SourceFolder $resolvedSource

            foreach ($finding in $analysis.Issues) {
                if ($status -ne 'Blocked') { $status = 'Review' }
                $issues.Add($finding)
            }
            foreach ($finding in $analysis.Notes) { $notes.Add($finding) }

            # An unresolved dependency GUID points at an application that is not in
            # this share, so it is worth surfacing rather than silently listing a
            # bare GUID.
            if ($unresolvedDeps.Count -gt 0) {
                $notes.Add(('{0} dependency GUID(s) do not match any application in this share: {1}' -f $unresolvedDeps.Count, ($unresolvedDeps -join ', ')))
            }

            if ($dependencyGuids.Count -gt 0) {
                $notes.Add(('Installs after {0} other application(s) in MDT. Model as step order in the task sequence: {1}' -f $dependencyGuids.Count, ($dependencyNames -join ', ')))
            }

            if (-not $enabled) {
                $notes.Add('Disabled in the MDT Deployment Workbench.')
            }

            if ($hidden) {
                $notes.Add('Hidden in the MDT Deployment Wizard.')
            }

            if ($reboot -match '^(true|1)$') {
                $notes.Add('MDT reboot flag is set. Add an explicit restart step in the task sequence.')
            }

            if ($platforms.Count -gt 0) {
                $notes.Add(('Supported platform filter in MDT: {0}. Recreate as a step condition if needed.' -f ($platforms -join ', ')))
            }

            if ($uninstall) {
                $notes.Add(('MDT uninstall key: {0}. DeployR handles detection differently.' -f $uninstall))
            }
        }

        # Suggested DeployR name. Short name is usually cleaner than the MDT
        # "Publisher - Product - Version" convention.
        $suggestedName = if ($shortName) { $shortName } else { $name }

        # MDT often leaves Version empty. It has to become something, because the
        # version is a folder name in the sources tree, but it must not become a
        # sentence. "Imported from MDT" belongs on the content item description.
        $suggestedVersion = if ($version) { $version } else { '1.0' }

        # Everything the grid does not show, gathered for the row tooltip.
        $detail = New-Object System.Collections.Generic.List[string]
        $detail.Add(('MDT name: {0}' -f $name))
        if ($publisher) { $detail.Add('Publisher: ' + $publisher) }
        if ($language)  { $detail.Add('Language: ' + $language) }
        $detail.Add('Source: ' + $(if ($resolvedSource) { $resolvedSource } else { 'none' }))
        if ($comments)  { $detail.Add('Comments: ' + $comments) }

        if ($issues.Count -gt 0) {
            $detail.Add('')
            $detail.Add('Needs attention:')
            foreach ($issue in $issues) { $detail.Add('  - ' + $issue) }
        }

        if ($notes.Count -gt 0) {
            $detail.Add('')
            $detail.Add('For the task sequence:')
            foreach ($note in $notes) { $detail.Add('  - ' + $note) }
        }

        $row = [pscustomobject]@{
            Selected          = ($status -eq 'Ready')
            Status            = $status
            MdtName           = $name
            DeployRName       = $suggestedName
            TargetVersion     = $suggestedVersion
            InstallCommand    = $commandLine
            SourceFolder      = $resolvedSource
            FileCount         = $fileCount
            SizeMB            = $sizeMB
            IssueSummary      = if ($issues.Count -gt 0) { $issues[0] } elseif ($notes.Count -gt 0) { $notes[0] } else { '' }
            IssuesText        = ($issues -join [Environment]::NewLine)
            NotesText         = ($notes -join [Environment]::NewLine)
            Publisher         = $publisher
            MdtVersion        = $version
            ShortName         = $shortName
            Language          = $language
            Guid              = $guid
            Enabled           = $enabled
            Hidden            = $hidden
            IsBundle          = $isBundle
            Dependencies      = ($dependencyNames -join ', ')
            Platforms         = ($platforms -join ', ')
            UninstallKey      = $uninstall
            Comments          = $comments
            MdtWorkingDir     = $workingDir
            SourceExists      = $sourceExists
            StagedFolder      = ''
            DetailText        = ($detail -join [Environment]::NewLine)
            Result            = ''
        }

        $results.Add($row)

        if (($index % 25) -eq 0) { Invoke-UIRefresh }
    }

    return $results
}

# ---------------------------------------------------------------------------
# DeployR
# ---------------------------------------------------------------------------

function Import-DeployRModule {
    <#
    .SYNOPSIS
        Loads the DeployR.Utility module from a folder.

    .DESCRIPTION
        DeployR.Utility is not published to the PowerShell Gallery and is not on
        PSModulePath, so it has to be imported by path. This function accepts either
        the module folder itself, the PSModules parent folder, or a direct path to
        the .psd1 or .psm1, and works out the rest.

        If no path is supplied, or the supplied path does not pan out, it falls back
        to the standard install locations for a DeployR server and client.

        After import it verifies that the commands this script actually depends on
        are present, so a partial or wrong-version module fails here with a clear
        message rather than halfway through creating content items.

    .PARAMETER Path
        Folder or file to load from. Optional.

    .PARAMETER Force
        Re-import even if the module is already loaded. Useful after an upgrade.
    #>
    [CmdletBinding()]
    param(
        [string]$Path,
        [switch]$Force
    )

    $moduleName = 'DeployR.Utility'

    $requiredCommands = @(
        'Connect-DeployR',
        'Get-DeployRApplication',
        'New-DeployRContentItem',
        'New-DeployRContentItemVersion',
        'Set-DeployRMetadata'
    )

    # Already loaded and we are not being told to reload.
    $loaded = Get-Module -Name $moduleName
    if ($loaded -and -not $Force) {
        Write-UILog -Message ('{0} {1} is already loaded from {2}' -f $loaded.Name, $loaded.Version, $loaded.ModuleBase)
        return $loaded
    }

    # Build the candidate list. Explicit path first, then the usual install paths.
    $candidates = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        $candidates.Add($Path.Trim().Trim('"'))
    }

    # Built as strings rather than with Join-Path, because Join-Path resolves the
    # drive and will throw noisily if the root does not exist on this machine.
    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:ProgramData)) {
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        $trimmed = $root.TrimEnd('\')
        $candidates.Add("$trimmed\2Pint Software\DeployR\Client\PSModules\DeployR.Utility")
        $candidates.Add("$trimmed\2Pint Software\DeployR\Client\PSModules")
        $candidates.Add("$trimmed\2Pint Software\DeployR\PSModules\DeployR.Utility")
    }

    $manifest = $null
    $tried    = New-Object System.Collections.Generic.List[string]

    foreach ($candidate in $candidates) {

        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        if ($tried -contains $candidate) { continue }
        $tried.Add($candidate)

        if (-not (Test-Path -LiteralPath $candidate)) { continue }

        $item = Get-Item -LiteralPath $candidate -ErrorAction SilentlyContinue
        if (-not $item) { continue }

        # A direct file path was supplied.
        if (-not $item.PSIsContainer) {
            if ($item.Extension -in @('.psd1', '.psm1')) {
                $manifest = $item.FullName
                break
            }
            continue
        }

        # A folder was supplied. Look for the manifest, then the module file, then
        # go one level down in case we were handed the PSModules parent.
        $probe = @(
            (Join-Path $item.FullName "$moduleName.psd1"),
            (Join-Path $item.FullName "$moduleName.psm1"),
            (Join-Path $item.FullName "$moduleName\$moduleName.psd1"),
            (Join-Path $item.FullName "$moduleName\$moduleName.psm1")
        )

        foreach ($file in $probe) {
            if (Test-Path -LiteralPath $file -PathType Leaf) {
                $manifest = $file
                break
            }
        }
        if ($manifest) { break }

        # Versioned layout, for example ...\DeployR.Utility\1.2.0\DeployR.Utility.psd1
        $nested = Get-ChildItem -LiteralPath $item.FullName -Filter "$moduleName.psd1" -Recurse -File -Depth 3 -ErrorAction SilentlyContinue |
                  Sort-Object -Property FullName -Descending |
                  Select-Object -First 1

        if ($nested) {
            $manifest = $nested.FullName
            break
        }
    }

    if (-not $manifest) {
        $message = "Could not locate $moduleName. Paths tried:" + [Environment]::NewLine +
                   ($tried -join [Environment]::NewLine) + [Environment]::NewLine +
                   'Set the module folder in the UI, or pass -DeployRModulePath, or run this on the DeployR server.'
        throw $message
    }

    Write-UILog -Message "Importing $moduleName from $manifest"

    try {
        # Global scope so the imported commands are visible to every function here.
        Import-Module -Name $manifest -Global -Force:$Force -ErrorAction Stop
    }
    catch {
        throw ("Failed to import $moduleName from '$manifest'. $($_.Exception.Message)")
    }

    $module = Get-Module -Name $moduleName
    if (-not $module) {
        throw "Import reported success but $moduleName is not loaded. Check that the module is not blocked by execution policy or Mark of the Web."
    }

    $missing = @()
    foreach ($command in $requiredCommands) {
        if (-not (Get-Command -Name $command -ErrorAction SilentlyContinue)) { $missing += $command }
    }

    if ($missing.Count -gt 0) {
        throw ("{0} loaded from '{1}' but these required commands are missing: {2}. This is usually an older module version." -f `
               $moduleName, $module.ModuleBase, ($missing -join ', '))
    }

    Write-UILog -Message ('Loaded {0} version {1}' -f $module.Name, $module.Version) -Level 'Success'

    return $module
}

function Get-LocalFqdn {
    <#
    .SYNOPSIS
        Best effort fully qualified name for this machine.
    #>
    [CmdletBinding()]
    param()

    try {
        $entry = [System.Net.Dns]::GetHostEntry([string]$env:COMPUTERNAME)
        if ($entry -and $entry.HostName) { return $entry.HostName }
    }
    catch {
        # DNS not answering. Fall through to the environment variables.
    }

    if ($env:USERDNSDOMAIN) {
        return ('{0}.{1}' -f $env:COMPUTERNAME, $env:USERDNSDOMAIN.ToLower())
    }

    return $env:COMPUTERNAME
}

function Format-DeployRUrl {
    <#
    .SYNOPSIS
        Normalises whatever was typed into a URL that Connect-DeployR will accept.

    .DESCRIPTION
        Adds https when no scheme is given, adds the default port when none is
        specified, and trims trailing slashes. A bare host name such as deployr01
        becomes https://deployr01:7281.
    #>
    [CmdletBinding()]
    param(
        [string]$Value,
        [int]$DefaultPort = 7281
    )

    if ([string]::IsNullOrWhiteSpace($Value)) { return '' }

    $text = $Value.Trim().Trim('"').TrimEnd('/')

    if ($text -notmatch '^[a-zA-Z][a-zA-Z0-9+.\-]*://') { $text = "https://$text" }

    $uri = $null
    if (-not [System.Uri]::TryCreate($text, [System.UriKind]::Absolute, [ref]$uri)) {
        # Not parseable, hand it back untouched rather than mangling it.
        return $text
    }

    # IsDefaultPort is true both when no port was given and when the scheme default
    # was typed out, so confirm against the original text before adding one.
    $hasExplicitPort = $text -match ([regex]::Escape($uri.Host) + ':\d+')

    if (-not $hasExplicitPort) {
        $path = $uri.AbsolutePath.TrimEnd('/')
        if ($path -eq '/') { $path = '' }
        return ('{0}://{1}:{2}{3}' -f $uri.Scheme, $uri.Host, $DefaultPort, $path)
    }

    return $text
}

function Get-DefaultDeployRUrl {
    <#
    .SYNOPSIS
        Builds the URL to prepopulate the server field with.

    .DESCRIPTION
        The script is meant to run on the DeployR server, so the local fully
        qualified name plus the default port is almost always right. It is still
        presented as an editable field rather than assumed, because the port is
        configurable at install time and this function does not read it from the
        DeployR configuration.
    #>
    [CmdletBinding()]
    param([int]$Port = 7281)

    $fqdn = Get-LocalFqdn
    return (Format-DeployRUrl -Value $fqdn -DefaultPort $Port)
}

function Write-CapturedStreams {
    <#
    .SYNOPSIS
        Turns captured pipeline records into UI log lines.

    .DESCRIPTION
        The DeployR cmdlets report useful detail on the information and warning
        streams, for example the authentication result and how long the token is
        good for. Redirecting those streams into the success stream lets us show
        them in the UI instead of losing them to a console nobody is watching.

        Returns the plain text lines so the caller can pick facts out of them.
    #>
    [CmdletBinding()]
    param(
        [object[]]$Records,
        [string]$Prefix = 'DeployR'
    )

    $lines = New-Object System.Collections.Generic.List[string]

    foreach ($record in $Records) {

        if ($null -eq $record) { continue }

        $level = 'Info'
        $text  = $null

        if     ($record -is [System.Management.Automation.InformationRecord]) { $text = [string]$record.MessageData }
        elseif ($record -is [System.Management.Automation.WarningRecord])     { $text = $record.Message; $level = 'Warn' }
        elseif ($record -is [System.Management.Automation.VerboseRecord])     { $text = $record.Message }
        elseif ($record -is [System.Management.Automation.DebugRecord])       { $text = $record.Message }
        elseif ($record -is [System.Management.Automation.ErrorRecord])       { $text = $record.ToString(); $level = 'Error' }
        elseif ($record -is [string])                                         { $text = $record }
        else {
            # Most likely the connection object itself. Render it rather than
            # dropping it, since it usually carries the server and token detail.
            # Out-String on its own returns nothing for a PSCustomObject, it needs
            # an explicit formatter in the pipeline first.
            $text = ($record | Format-List | Out-String).Trim()
            if ([string]::IsNullOrWhiteSpace($text)) { $text = [string]$record }
        }

        if ([string]::IsNullOrWhiteSpace($text)) { continue }

        # A stray large object should not be allowed to flood the log.
        $recordLines = @($text -split "`r?`n")
        if ($recordLines.Count -gt 20) {
            $recordLines = $recordLines[0..19] + ('... {0} more line(s) suppressed' -f ($recordLines.Count - 20))
        }

        foreach ($line in $recordLines) {
            $trimmed = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
            $lines.Add($trimmed)
            Write-UILog -Message ('{0}: {1}' -f $Prefix, $trimmed) -Level $level
        }
    }

    return $lines
}

function Connect-DeployRServer {
    [CmdletBinding()]
    param(
        [string]$ModulePath,
        [string]$Url,
        [string]$Code
    )

    $null = Import-DeployRModule -Path $ModulePath

    $splat = @{}

    if (-not [string]::IsNullOrWhiteSpace($Url))  { $splat['Url'] = (Format-DeployRUrl -Value $Url -DefaultPort $DeployRPort) }
    if (-not [string]::IsNullOrWhiteSpace($Code)) { $splat['Passcode'] = $Code }

    if ($splat.ContainsKey('Url')) {
        Write-UILog -Message ('Connecting to {0}' -f $splat['Url'])
    }
    else {
        Write-UILog -Message 'Connecting to DeployR using the module default.'
    }

    # 6 is information (which is where Write-Host goes), 3 is warning, 4 is verbose.
    # The error stream is deliberately left alone so -ErrorAction Stop still throws.
    $captured = @()

    try {
        $captured = @(Connect-DeployR @splat -ErrorAction Stop -InformationAction Continue 6>&1 3>&1 4>&1)
    }
    catch [System.Management.Automation.ParameterBindingException] {
        # Older module builds may not take both at once. Retry with the URL only.
        if ($splat.ContainsKey('Passcode') -and $splat.ContainsKey('Url')) {
            Write-UILog -Message 'Retrying without the passcode parameter.' -Level 'Warn'
            $captured = @(Connect-DeployR -Url $splat['Url'] -ErrorAction Stop -InformationAction Continue 6>&1 3>&1 4>&1)
        }
        else { throw }
    }

    $lines = Write-CapturedStreams -Records $captured

    # Pull the token lifetime out if the module reported one, so it can sit on the
    # connection state tooltip rather than scrolling away in the log.
    $script:AuthSummary = ''
    $script:TokenExpiry = ''

    foreach ($line in $lines) {
        if ($line -match 'authentication\s+completed') { $script:AuthSummary = $line }
        if ($line -match 'valid\s+until\s+(?<expiry>.+?)\s*$') { $script:TokenExpiry = $Matches['expiry'].Trim() }
    }

    Write-UILog -Message 'Connected to DeployR.' -Level 'Success'

    $script:ExistingApps = @(Get-DeployRApplication -ErrorAction SilentlyContinue)
    Write-UILog -Message ('DeployR currently holds {0} application content item(s).' -f $script:ExistingApps.Count)

    $script:DeployRConnected = $true
}

function Get-DefaultSourcesRoot {
    <#
    .SYNOPSIS
        Picks a starting point for the sources folder.

    .DESCRIPTION
        Prefers the fixed drive with the most free space that is not the system
        drive, since application content does not belong on C. Falls back to the
        system drive when there is nothing else. This is only a prefilled
        suggestion, the field stays editable.
    #>
    [CmdletBinding()]
    param()

    $leaf = 'DeployRSources\Applications'

    try {
        $systemDrive = ($env:SystemDrive + '\')

        $candidate = [System.IO.DriveInfo]::GetDrives() |
                     Where-Object { $_.DriveType -eq [System.IO.DriveType]::Fixed -and $_.IsReady -and $_.Name -ne $systemDrive } |
                     Sort-Object -Property AvailableFreeSpace -Descending |
                     Select-Object -First 1

        if ($candidate) { return (Join-Path -Path $candidate.Name -ChildPath $leaf) }
    }
    catch {
        # Fall through to the system drive.
    }

    if ($env:SystemDrive) { return (Join-Path -Path ($env:SystemDrive + '\') -ChildPath $leaf) }

    return $leaf
}

function Get-SafePathSegment {
    <#
    .SYNOPSIS
        Makes a folder name out of an application name or version string.
    #>
    [CmdletBinding()]
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) { return 'Unnamed' }

    # The Windows set is spelled out rather than taken from
    # GetInvalidFileNameChars, so behaviour does not depend on the host platform.
    $invalid = @('<', '>', ':', '"', '/', '\', '|', '?', '*') + [char[]](0..31 | ForEach-Object { [char]$_ })

    $builder = New-Object System.Text.StringBuilder

    foreach ($char in $Value.ToCharArray()) {
        if ($invalid -contains $char) { $null = $builder.Append('-') }
        else { $null = $builder.Append($char) }
    }

    # Windows will not keep a trailing dot or space on a folder name.
    $result = $builder.ToString().Trim().TrimEnd('.', ' ')

    if ([string]::IsNullOrWhiteSpace($result)) { return 'Unnamed' }

    # Reserved device names cannot be used as folder names, even with an extension.
    $reserved = @('CON', 'PRN', 'AUX', 'NUL') +
                (1..9 | ForEach-Object { "COM$_" }) +
                (1..9 | ForEach-Object { "LPT$_" })

    $stem = ($result -split '\.')[0]
    if ($reserved -contains $stem.ToUpperInvariant()) { $result = '_' + $result }

    return $result
}

function Get-StagingTargetPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SourcesRoot,
        [Parameter(Mandatory)][string]$AppName,
        [string]$Version
    )

    # Built as strings rather than with Join-Path. Join-Path resolves the drive
    # qualifier, so a sources folder on a drive that is not currently mounted
    # returns null instead of a path, and the copy target silently goes empty.
    $separator = [System.IO.Path]::DirectorySeparatorChar
    $target = $SourcesRoot.Trim().TrimEnd('\', '/') + $separator + (Get-SafePathSegment -Value $AppName)

    if (-not [string]::IsNullOrWhiteSpace($Version)) {
        $target = $target + $separator + (Get-SafePathSegment -Value $Version)
    }

    return $target
}

function Get-FreeSpaceMB {
    <#
    .SYNOPSIS
        Free space on the volume holding a path, or null when it cannot be worked
        out, which is the case for UNC paths.
    #>
    [CmdletBinding()]
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    if ($Path.TrimStart().StartsWith('\\')) { return $null }

    try {
        $root = [System.IO.Path]::GetPathRoot($Path)
        if ([string]::IsNullOrWhiteSpace($root)) { return $null }

        $drive = New-Object System.IO.DriveInfo($root)
        if (-not $drive.IsReady) { return $null }

        return [math]::Round($drive.AvailableFreeSpace / 1MB, 2)
    }
    catch {
        return $null
    }
}

function Copy-AppContentToSources {
    <#
    .SYNOPSIS
        Copies an application's content from the MDT share into the local sources
        tree and returns the folder the content item should be built from.

    .DESCRIPTION
        Uses robocopy where available, since it retries and handles long paths and
        slow links far better than Copy-Item. Robocopy exit codes below 8 all mean
        success of some kind, 8 and above are real failures.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SourceFolder,
        [Parameter(Mandatory)][string]$TargetFolder
    )

    if (-not (Test-Path -LiteralPath $SourceFolder -PathType Container)) {
        throw "Source folder not found: $SourceFolder"
    }

    $parent = Split-Path -Path $TargetFolder -Parent
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        $null = New-Item -Path $parent -ItemType Directory -Force -ErrorAction Stop
    }

    if (Test-Path -LiteralPath $TargetFolder -PathType Container) {
        $existing = @(Get-ChildItem -LiteralPath $TargetFolder -Recurse -File -Force -ErrorAction SilentlyContinue)
        if ($existing.Count -gt 0) {
            Write-UILog -Message ("Target folder already holds {0} file(s). Existing files will be overwritten where names match, nothing is deleted." -f $existing.Count) -Level 'Warn'
        }
    }

    $source = $SourceFolder.TrimEnd('\')
    $target = $TargetFolder.TrimEnd('\')

    $robocopy = Get-Command -Name 'robocopy.exe' -ErrorAction SilentlyContinue

    if ($robocopy) {
        # /E includes empty subfolders, and no /MIR on purpose so an existing
        # sources tree never gets pruned by this script.
        $roboArgs = @($source, $target, '/E', '/R:2', '/W:2', '/NP', '/NFL', '/NDL', '/NJH', '/NJS')

        $null = & $robocopy.Source @roboArgs 2>&1
        $code = $LASTEXITCODE

        if ($code -ge 8) {
            throw ("robocopy failed with exit code {0} copying '{1}' to '{2}'." -f $code, $source, $target)
        }
    }
    else {
        Write-UILog -Message 'robocopy not found, falling back to Copy-Item.' -Level 'Warn'

        if (-not (Test-Path -LiteralPath $target)) {
            $null = New-Item -Path $target -ItemType Directory -Force -ErrorAction Stop
        }

        Copy-Item -Path (Join-Path -Path $source -ChildPath '*') -Destination $target -Recurse -Force -ErrorAction Stop
    }

    $copied = @(Get-ChildItem -LiteralPath $target -Recurse -File -Force -ErrorAction SilentlyContinue)
    if ($copied.Count -eq 0) {
        throw "Nothing was copied to '$target'. The source folder may be empty or unreadable."
    }

    return $target
}

function Set-DeployRVersionActive {
    <#
    .SYNOPSIS
        Marks a newly created content item version as Active.

    .DESCRIPTION
        A version is not Active when it is created, so without this the content
        item exists but nothing will deploy it. The status is set on the returned
        object and written back with Set-DeployRMetadata.

    .OUTPUTS
        True when the version was activated.
    #>
    [CmdletBinding()]
    param($Version)

    # Not Mandatory, so a null gets our own message rather than a parameter
    # binding error, and there is no chance of a prompt behind the window.
    if ($null -eq $Version) {
        throw 'New-DeployRContentItemVersion returned nothing, so there is no version to activate.'
    }

    $Version.status = 'Active'
    $Version | Set-DeployRMetadata -Type ContentItemVersion -ErrorAction Stop

    return $true
}

function New-DeployRApplicationFromRow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Row,
        [string]$SourcesRoot,
        [switch]$DryRun
    )

    # Deliberately not [Parameter(Mandatory)]. In a WPF script an empty value would
    # trigger a console prompt on a window nobody can see, and the UI would appear
    # to hang. Guard explicitly instead.
    if ([string]::IsNullOrWhiteSpace($SourcesRoot)) {
        $Row.Result = 'Skipped, no sources folder set'
        return $false
    }

    $appName = ([string]$Row.DeployRName).Trim()
    $command = ([string]$Row.InstallCommand).Trim()
    $folder  = ([string]$Row.SourceFolder).Trim()
    $ver     = ([string]$Row.TargetVersion).Trim()

    if ([string]::IsNullOrWhiteSpace($appName)) {
        $Row.Result = 'Skipped, no DeployR name'
        return $false
    }

    if ([string]::IsNullOrWhiteSpace($command)) {
        $Row.Result = 'Skipped, no install command line'
        return $false
    }

    # Content is always staged locally, so an application with nothing to copy
    # cannot be created. These are the MDT NoSource applications.
    if ([string]::IsNullOrWhiteSpace($folder)) {
        $Row.Result = 'Skipped, no source content to stage'
        return $false
    }

    if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
        $Row.Result = 'Skipped, source folder missing'
        return $false
    }

    $stagedFolder = Get-StagingTargetPath -SourcesRoot $SourcesRoot -AppName $appName -Version $ver
    $Row.StagedFolder = $stagedFolder

    $existing = $script:ExistingApps | Where-Object { $_.Name -eq $appName } | Select-Object -First 1

    if ($DryRun) {
        $action = if ($existing) { 'add a new version to the existing item' } else { 'create a new content item' }
        $Row.Result = ('Dry run, would copy to {0} then {1} and set the version Active' -f $stagedFolder, $action)
        return $true
    }

    # Copy first, so a failed copy leaves no half made content item behind.
    try {
        Write-UILog -Message ("Copying '{0}' to {1}" -f $appName, $stagedFolder)
        $contentFolder = Copy-AppContentToSources -SourceFolder $folder -TargetFolder $stagedFolder
    }
    catch {
        $Row.Result = 'Copy failed: ' + $_.Exception.Message
        Write-UILog -Message ("Copy failed for '{0}': {1}" -f $appName, $_.Exception.Message) -Level 'Error'
        return $false
    }

    try {
        if ($existing) {
            Write-UILog -Message ("Adding version '{0}' to existing content item '{1}'" -f $ver, $appName)
            $newVersion = New-DeployRContentItemVersion -ContentItemId $existing.id `
                                                        -SourceFolder $contentFolder `
                                                        -InstallationCommandLine $command `
                                                        -Description $ver `
                                                        -ErrorAction Stop
            $baseResult = 'Copied, version added to existing item'
        }
        else {
            Write-UILog -Message ("Creating content item '{0}'" -f $appName)
            $contentItem = New-DeployRContentItem -Type Folder `
                                                  -Name $appName `
                                                  -Description 'Imported from MDT' `
                                                  -Purpose Application `
                                                  -ErrorAction Stop

            $newVersion = New-DeployRContentItemVersion -ContentItemId $contentItem.id `
                                                        -SourceFolder $contentFolder `
                                                        -InstallationCommandLine $command `
                                                        -Description $ver `
                                                        -ErrorAction Stop

            $baseResult = 'Copied and created'
            $script:ExistingApps += $contentItem
        }
    }
    catch {
        $Row.Result = 'Failed: ' + $_.Exception.Message
        Write-UILog -Message ("Failed to create '{0}': {1}" -f $appName, $_.Exception.Message) -Level 'Error'
        return $false
    }

    # A new version is not Active, so without this the content item exists but
    # nothing will deploy it. Handled separately from creation, because if this is
    # the part that fails the content item is still there and the operator needs to
    # know it is sitting inactive rather than missing.
    try {
        $null = Set-DeployRVersionActive -Version $newVersion
        $Row.Result = $baseResult + ', version active'
        Write-UILog -Message ("Version '{0}' of '{1}' set to Active" -f $ver, $appName) -Level 'Success'
    }
    catch {
        $Row.Result = $baseResult + ', BUT version not activated: ' + $_.Exception.Message
        Write-UILog -Message ("'{0}' was created but the version could not be set to Active: {1}" -f $appName, $_.Exception.Message) -Level 'Error'
        Write-UILog -Message ("Activate '{0}' by hand in the DeployR console before using it." -f $appName) -Level 'Warn'
    }

    return $true
}

# ---------------------------------------------------------------------------
# XAML
# ---------------------------------------------------------------------------

$xamlText = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MDT to DeployR application migration"
        Height="880" Width="1400"
        WindowStartupLocation="CenterScreen"
        Background="#0B1220"
        Foreground="#E6EDF7"
        FontFamily="Segoe UI"
        FontSize="12.5"
        TextOptions.TextFormattingMode="Display"
        UseLayoutRounding="True">

    <Window.Resources>

        <!-- Palette -->
        <SolidColorBrush x:Key="AppBg"        Color="#0B1220"/>
        <SolidColorBrush x:Key="CardBg"       Color="#131C2E"/>
        <SolidColorBrush x:Key="CardBorder"   Color="#1F2A3F"/>
        <SolidColorBrush x:Key="InputBg"      Color="#0E1725"/>
        <SolidColorBrush x:Key="InputBorder"  Color="#26344A"/>
        <SolidColorBrush x:Key="TextPrimary"  Color="#E6EDF7"/>
        <SolidColorBrush x:Key="TextMuted"    Color="#8FA3BF"/>
        <SolidColorBrush x:Key="TextDim"      Color="#5F708A"/>
        <SolidColorBrush x:Key="Accent"       Color="#2F7CF6"/>
        <SolidColorBrush x:Key="AccentHover"  Color="#4C90F9"/>
        <SolidColorBrush x:Key="Danger"       Color="#E0483E"/>
        <SolidColorBrush x:Key="Ok"           Color="#3DD68C"/>
        <SolidColorBrush x:Key="Warn"         Color="#F0A93B"/>

        <!-- Card container -->
        <Style x:Key="Card" TargetType="Border">
            <Setter Property="Background" Value="{StaticResource CardBg}"/>
            <Setter Property="BorderBrush" Value="{StaticResource CardBorder}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="10"/>
            <Setter Property="Padding" Value="14,12"/>
            <Setter Property="Margin" Value="0,0,0,10"/>
            <Setter Property="SnapsToDevicePixels" Value="True"/>
        </Style>

        <Style x:Key="CardHeader" TargetType="TextBlock">
            <Setter Property="Foreground" Value="{StaticResource TextMuted}"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Margin" Value="0,0,0,10"/>
        </Style>

        <Style TargetType="Label">
            <Setter Property="Foreground" Value="{StaticResource TextMuted}"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="Padding" Value="0,0,4,0"/>
        </Style>

        <!-- Buttons -->
        <Style x:Key="BaseButton" TargetType="Button">
            <Setter Property="Background" Value="#1B2740"/>
            <Setter Property="Foreground" Value="#DCE6F5"/>
            <Setter Property="BorderBrush" Value="#2C3B58"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="14,0"/>
            <Setter Property="Height" Value="32"/>
            <Setter Property="MinWidth" Value="94"/>
            <Setter Property="Margin" Value="0,0,8,0"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="SnapsToDevicePixels" Value="True"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd"
                                CornerRadius="6"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                              Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#243352"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#151E33"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Bd" Property="Background" Value="#141B2A"/>
                                <Setter TargetName="Bd" Property="BorderBrush" Value="#1E2739"/>
                                <Setter Property="Foreground" Value="#546B87"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="Button" BasedOn="{StaticResource BaseButton}"/>

        <Style x:Key="PrimaryButton" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="Background" Value="#2F7CF6"/>
            <Setter Property="BorderBrush" Value="#3B86F7"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" CornerRadius="6"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="1">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                              Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#4C90F9"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#2568D6"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Bd" Property="Background" Value="#1C2C48"/>
                                <Setter TargetName="Bd" Property="BorderBrush" Value="#22355A"/>
                                <Setter Property="Foreground" Value="#6B82A6"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="Background" Value="#E0483E"/>
            <Setter Property="BorderBrush" Value="#E85A50"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" CornerRadius="6"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="1">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                              Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#EC5B51"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#C23B32"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Bd" Property="Background" Value="#3A2028"/>
                                <Setter TargetName="Bd" Property="BorderBrush" Value="#472730"/>
                                <Setter Property="Foreground" Value="#8B6B70"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Text input -->
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="{StaticResource InputBg}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource InputBorder}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Height" Value="30"/>
            <Setter Property="Padding" Value="9,0"/>
            <Setter Property="CaretBrush" Value="#7FB0FF"/>
            <Setter Property="SelectionBrush" Value="#2F7CF6"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border x:Name="Bd" CornerRadius="6"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}">
                            <ScrollViewer x:Name="PART_ContentHost"
                                          Margin="{TemplateBinding Padding}"
                                          VerticalAlignment="{TemplateBinding VerticalContentAlignment}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsKeyboardFocusWithin" Value="True">
                                <Setter TargetName="Bd" Property="BorderBrush" Value="#2F7CF6"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Bd" Property="Background" Value="#0C1320"/>
                                <Setter Property="Foreground" Value="#546578"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="PasswordBox">
            <Setter Property="Background" Value="{StaticResource InputBg}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource InputBorder}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Height" Value="30"/>
            <Setter Property="Padding" Value="9,0"/>
            <Setter Property="CaretBrush" Value="#7FB0FF"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="PasswordBox">
                        <Border x:Name="Bd" CornerRadius="6"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}">
                            <ScrollViewer x:Name="PART_ContentHost"
                                          Margin="{TemplateBinding Padding}"
                                          VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsKeyboardFocusWithin" Value="True">
                                <Setter TargetName="Bd" Property="BorderBrush" Value="#2F7CF6"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Bd" Property="Background" Value="#0C1320"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Check box -->
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <StackPanel Orientation="Horizontal" Background="Transparent">
                            <Border x:Name="Box" Width="16" Height="16" CornerRadius="4"
                                    Background="#0E1725" BorderBrush="#33445F" BorderThickness="1"
                                    VerticalAlignment="Center">
                                <Path x:Name="Tick" Visibility="Collapsed"
                                      Data="M 2.5 6.5 L 5.5 9.5 L 11 3.5"
                                      Stroke="#FFFFFF" StrokeThickness="1.8"
                                      StrokeStartLineCap="Round" StrokeEndLineCap="Round"
                                      StrokeLineJoin="Round"/>
                            </Border>
                            <ContentPresenter Margin="8,0,0,0" VerticalAlignment="Center"/>
                        </StackPanel>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Box" Property="Background" Value="#2F7CF6"/>
                                <Setter TargetName="Box" Property="BorderBrush" Value="#3B86F7"/>
                                <Setter TargetName="Tick" Property="Visibility" Value="Visible"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Box" Property="BorderBrush" Value="#4C90F9"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Foreground" Value="#556680"/>
                                <Setter TargetName="Box" Property="Background" Value="#0C1320"/>
                                <Setter TargetName="Box" Property="BorderBrush" Value="#232F42"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Combo box -->
        <Style TargetType="ComboBoxItem">
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="Padding" Value="10,6"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBoxItem">
                        <Border x:Name="Bd" Background="Transparent" CornerRadius="4" Padding="{TemplateBinding Padding}">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsHighlighted" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#1E2E4C"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ComboBox">
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="Height" Value="30"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton x:Name="Toggle" Focusable="False" ClickMode="Press"
                                          IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
                                <ToggleButton.Template>
                                    <ControlTemplate TargetType="ToggleButton">
                                        <Border x:Name="Bd" CornerRadius="6" Background="#0E1725"
                                                BorderBrush="#26344A" BorderThickness="1">
                                            <Path x:Name="Arrow" HorizontalAlignment="Right" VerticalAlignment="Center"
                                                  Margin="0,0,10,0" Data="M 0 0 L 4 4 L 8 0"
                                                  Stroke="#8FA3BF" StrokeThickness="1.6"
                                                  StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
                                        </Border>
                                        <ControlTemplate.Triggers>
                                            <Trigger Property="IsMouseOver" Value="True">
                                                <Setter TargetName="Bd" Property="BorderBrush" Value="#3B5578"/>
                                            </Trigger>
                                        </ControlTemplate.Triggers>
                                    </ControlTemplate>
                                </ToggleButton.Template>
                            </ToggleButton>
                            <ContentPresenter x:Name="Selected" IsHitTestVisible="False"
                                              Margin="10,0,26,0" VerticalAlignment="Center"
                                              Content="{TemplateBinding SelectionBoxItem}"
                                              ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"/>
                            <Popup x:Name="PART_Popup" AllowsTransparency="True" Placement="Bottom"
                                   IsOpen="{TemplateBinding IsDropDownOpen}" Focusable="False" PopupAnimation="Fade">
                                <Border Background="#131C2E" BorderBrush="#2A3A57" BorderThickness="1"
                                        CornerRadius="8" Padding="4" MinWidth="{TemplateBinding ActualWidth}"
                                        MaxHeight="{TemplateBinding MaxDropDownHeight}">
                                    <ScrollViewer>
                                        <ItemsPresenter/>
                                    </ScrollViewer>
                                </Border>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Scroll bars -->
        <Style TargetType="ScrollBar">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Width" Value="10"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Background="Transparent">
                            <Track x:Name="PART_Track" IsDirectionReversed="True">
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.PageUpCommand" Opacity="0" Focusable="False">
                                        <RepeatButton.Template>
                                            <ControlTemplate TargetType="RepeatButton">
                                                <Border Background="Transparent"/>
                                            </ControlTemplate>
                                        </RepeatButton.Template>
                                    </RepeatButton>
                                </Track.DecreaseRepeatButton>
                                <Track.Thumb>
                                    <Thumb>
                                        <Thumb.Template>
                                            <ControlTemplate TargetType="Thumb">
                                                <Border x:Name="Th" CornerRadius="5" Background="#2A3A57" Margin="2,0"/>
                                                <ControlTemplate.Triggers>
                                                    <Trigger Property="IsMouseOver" Value="True">
                                                        <Setter TargetName="Th" Property="Background" Value="#3C5178"/>
                                                    </Trigger>
                                                </ControlTemplate.Triggers>
                                            </ControlTemplate>
                                        </Thumb.Template>
                                    </Thumb>
                                </Track.Thumb>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.PageDownCommand" Opacity="0" Focusable="False">
                                        <RepeatButton.Template>
                                            <ControlTemplate TargetType="RepeatButton">
                                                <Border Background="Transparent"/>
                                            </ControlTemplate>
                                        </RepeatButton.Template>
                                    </RepeatButton>
                                </Track.IncreaseRepeatButton>
                            </Track>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="Orientation" Value="Horizontal">
                                <Setter Property="Height" Value="10"/>
                                <Setter TargetName="PART_Track" Property="IsDirectionReversed" Value="False"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Progress bar -->
        <Style TargetType="ProgressBar">
            <Setter Property="Height" Value="8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ProgressBar">
                        <Border CornerRadius="5" Background="#0E1725" BorderBrush="#26344A" BorderThickness="1">
                            <Grid>
                                <Border x:Name="PART_Track" Background="Transparent"/>
                                <Border x:Name="PART_Indicator" CornerRadius="4" Background="#2F7CF6"
                                        HorizontalAlignment="Left"/>
                            </Grid>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Tooltip -->
        <Style TargetType="ToolTip">
            <Setter Property="Foreground" Value="#E6EDF7"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ToolTip">
                        <Border Background="#182236" BorderBrush="#2A3A57" BorderThickness="1"
                                CornerRadius="6" Padding="10,7">
                            <ContentPresenter/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Data grid -->
        <Style TargetType="DataGridColumnHeader">
            <Setter Property="Background" Value="#182236"/>
            <Setter Property="Foreground" Value="#9FB2CC"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="11.5"/>
            <Setter Property="Height" Value="36"/>
            <Setter Property="Padding" Value="10,0"/>
            <Setter Property="BorderBrush" Value="#223047"/>
            <Setter Property="BorderThickness" Value="0,0,1,1"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="DataGridColumnHeader">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="DataGridCell">
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="10,0"/>
            <Setter Property="Foreground" Value="{Binding RelativeSource={RelativeSource AncestorType=DataGridRow}, Path=Foreground}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="DataGridCell">
                        <Border Background="Transparent" Padding="{TemplateBinding Padding}">
                            <ContentPresenter VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

    </Window.Resources>

    <Grid Margin="16,14,16,14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="150"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Grid Grid.Row="0" Margin="2,0,2,14">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Border Grid.Column="0" Width="38" Height="38" CornerRadius="9" Background="#16375F"
                    BorderBrush="#2F7CF6" BorderThickness="1" Margin="0,0,12,0">
                <TextBlock Text="DR" Foreground="#7FB0FF" FontWeight="Bold" FontSize="14"
                           HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <StackPanel Grid.Column="1" VerticalAlignment="Center">
                <TextBlock Text="MDT to DeployR" FontSize="17" FontWeight="SemiBold" Foreground="#F2F6FC"/>
                <TextBlock Text="Application migration" FontSize="11.5" Foreground="#8FA3BF" Margin="0,1,0,0"/>
            </StackPanel>
            <TextBlock Grid.Column="2" Text="Created by Johan Arwidmark" FontSize="11.5"
                       Foreground="#7C8FAB" VerticalAlignment="Bottom" Margin="0,0,2,3"/>
        </Grid>

        <!-- MDT deployment share -->
        <Border Grid.Row="1" Style="{StaticResource Card}">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <TextBlock Grid.Row="0" Grid.ColumnSpan="5" Text="MDT DEPLOYMENT SHARE" Style="{StaticResource CardHeader}"/>

                <Label Grid.Row="1" Grid.Column="0" Content="Share root"/>
                <TextBox Grid.Row="1" Grid.Column="1" x:Name="TxtShare" Margin="10,0,10,0"
                         ToolTip="Local path or UNC, for example \\MDT01\DeploymentShare$"/>
                <CheckBox Grid.Row="1" Grid.Column="2" x:Name="ChkSkipSize" Content="Skip size scan"
                          VerticalAlignment="Center" Margin="0,0,14,0"
                          ToolTip="Skip the recursive size and file count scan. Worth using over a slow link."/>
                <Button Grid.Row="1" Grid.Column="3" x:Name="BtnBrowse" Content="Browse"/>
                <Button Grid.Row="1" Grid.Column="4" x:Name="BtnLoad" Content="Load apps"
                        Style="{StaticResource PrimaryButton}" Margin="0"/>

                <CheckBox Grid.Row="2" Grid.Column="0" x:Name="ChkUseShareCreds" Content="Alternate credentials"
                          VerticalAlignment="Center" Margin="0,10,0,0"
                          ToolTip="Authenticate to the remote share with a different Windows account."/>
                <StackPanel Grid.Row="2" Grid.Column="1" Grid.ColumnSpan="3" Orientation="Horizontal" Margin="10,10,10,0">
                    <Label Content="User"/>
                    <TextBox x:Name="TxtShareUser" Width="190" Margin="8,0,14,0" IsEnabled="False"
                             ToolTip="DOMAIN\user or user@domain"/>
                    <Label Content="Password"/>
                    <PasswordBox x:Name="TxtSharePassword" Width="170" Margin="8,0,14,0" IsEnabled="False"/>
                    <TextBlock x:Name="LblShareState" VerticalAlignment="Center" Foreground="#8FA3BF" FontWeight="SemiBold"/>
                </StackPanel>
                <Button Grid.Row="2" Grid.Column="4" x:Name="BtnTestShare" Content="Test access" Margin="0,10,0,0"/>
            </Grid>
        </Border>

        <!-- DeployR -->
        <Border Grid.Row="2" Style="{StaticResource Card}">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="180"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <TextBlock Grid.Row="0" Grid.ColumnSpan="6" Text="DEPLOYR" Style="{StaticResource CardHeader}"/>

                <Label Grid.Row="1" Grid.Column="0" Content="Module"/>
                <TextBox Grid.Row="1" Grid.Column="1" Grid.ColumnSpan="2" x:Name="TxtModulePath" Margin="10,0,14,0"
                         ToolTip="Folder holding DeployR.Utility. Detected automatically on a DeployR server."/>
                <TextBlock Grid.Row="1" Grid.Column="3" x:Name="LblModuleState" Text="Not loaded" Foreground="#E0483E"
                           VerticalAlignment="Center" Margin="0,0,14,0" FontWeight="SemiBold"
                           TextTrimming="CharacterEllipsis"/>
                <Button Grid.Row="1" Grid.Column="4" x:Name="BtnBrowseModule" Content="Browse"/>
                <Button Grid.Row="1" Grid.Column="5" x:Name="BtnLoadModule" Content="Reload" Margin="0"/>

                <Label Grid.Row="2" Grid.Column="0" Content="Server URL" Margin="0,10,0,0"/>
                <TextBox Grid.Row="2" Grid.Column="1" x:Name="TxtServer" Margin="10,10,14,0"
                         ToolTip="For example https://deployr01.corp.viamonstra.com:7281. A bare host name is expanded to https and the default port."/>
                <Label Grid.Row="2" Grid.Column="2" Content="Passcode" Margin="0,10,0,0"/>
                <PasswordBox Grid.Row="2" Grid.Column="3" x:Name="TxtPasscode" Margin="10,10,14,0"/>
                <TextBlock Grid.Row="2" Grid.Column="4" x:Name="LblConnState" Text="Not connected" Foreground="#E0483E"
                           VerticalAlignment="Center" Margin="0,10,14,0" FontWeight="SemiBold"/>
                <Button Grid.Row="2" Grid.Column="5" x:Name="BtnConnect" Content="Connect"
                        Style="{StaticResource PrimaryButton}" Margin="0,10,0,0"/>

                <Label Grid.Row="3" Grid.Column="0" Content="Sources" Margin="0,10,0,0"/>
                <TextBox Grid.Row="3" Grid.Column="1" Grid.ColumnSpan="3" x:Name="TxtSourcesRoot" Margin="10,10,14,0"
                         ToolTip="Required. Local folder that content is copied into before the content item is created, for example D:\DeployRSources\Applications"/>
                <Button Grid.Row="3" Grid.Column="4" x:Name="BtnBrowseSources" Content="Browse" Margin="0,10,8,0"/>
                <TextBlock Grid.Row="3" Grid.Column="5" x:Name="LblFreeSpace" VerticalAlignment="Center"
                           Foreground="#8FA3BF" Margin="0,10,0,0"/>
            </Grid>
        </Border>

        <!-- Filter bar -->
        <Grid Grid.Row="3" Margin="2,0,2,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="260"/>
                <ColumnDefinition Width="130"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBox Grid.Column="0" x:Name="TxtFilter" Margin="0,0,10,0" ToolTip="Filter by name, publisher or command line"/>
            <ComboBox Grid.Column="1" x:Name="CmbStatus" Margin="0,0,14,0" SelectedIndex="0">
                <ComboBoxItem Content="All"/>
                <ComboBoxItem Content="Ready"/>
                <ComboBoxItem Content="Review"/>
                <ComboBoxItem Content="Blocked"/>
            </ComboBox>
            <TextBlock Grid.Column="2" x:Name="LblCounts" VerticalAlignment="Center" Foreground="#8FA3BF"/>
            <Button Grid.Column="3" x:Name="BtnSelectReady" Content="Select ready"/>
            <Button Grid.Column="4" x:Name="BtnSelectAll" Content="Select all"/>
            <Button Grid.Column="5" x:Name="BtnSelectNone" Content="Select none" Margin="0"/>
        </Grid>

        <!-- Grid -->
        <Border Grid.Row="4" Background="#131C2E" BorderBrush="#1F2A3F" BorderThickness="1"
                CornerRadius="10" Padding="1" Margin="0,0,0,10" SnapsToDevicePixels="True">
            <DataGrid x:Name="GridApps"
                      AutoGenerateColumns="False"
                      CanUserAddRows="False"
                      CanUserDeleteRows="False"
                      SelectionMode="Single"
                      HeadersVisibility="Column"
                      GridLinesVisibility="None"
                      Background="Transparent"
                      BorderThickness="0"
                      RowHeaderWidth="0"
                      RowHeight="34"
                      AlternationCount="2"
                      Foreground="#DCE6F5"
                      VerticalGridLinesBrush="Transparent"
                      HorizontalGridLinesBrush="#1B2436">
                <DataGrid.RowStyle>
                    <Style TargetType="DataGridRow">
                        <Setter Property="Background" Value="#131C2E"/>
                        <Setter Property="Foreground" Value="#DCE6F5"/>
                        <Setter Property="BorderThickness" Value="0"/>
                        <Setter Property="ToolTip" Value="{Binding DetailText}"/>
                        <Style.Triggers>
                            <Trigger Property="ItemsControl.AlternationIndex" Value="1">
                                <Setter Property="Background" Value="#0F1828"/>
                            </Trigger>
                            <DataTrigger Binding="{Binding Status}" Value="Review">
                                <Setter Property="Foreground" Value="#F0A93B"/>
                            </DataTrigger>
                            <DataTrigger Binding="{Binding Status}" Value="Blocked">
                                <Setter Property="Foreground" Value="#FF6B6B"/>
                            </DataTrigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#182742"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter Property="Background" Value="#1D3B6B"/>
                            </Trigger>
                        </Style.Triggers>
                    </Style>
                </DataGrid.RowStyle>
                <DataGrid.Columns>
                    <DataGridTemplateColumn Header="" Width="38" CanUserSort="False">
                        <DataGridTemplateColumn.CellTemplate>
                            <DataTemplate>
                                <CheckBox IsChecked="{Binding Selected, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"
                                          HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </DataTemplate>
                        </DataGridTemplateColumn.CellTemplate>
                    </DataGridTemplateColumn>
                    <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="74" IsReadOnly="True"/>
                    <DataGridTextColumn Header="MDT name" Binding="{Binding MdtName}" Width="230" IsReadOnly="True"/>
                    <DataGridTextColumn Header="DeployR name" Binding="{Binding DeployRName, Mode=TwoWay, UpdateSourceTrigger=LostFocus}" Width="200"/>
                    <DataGridTextColumn Header="Version" Binding="{Binding TargetVersion, Mode=TwoWay, UpdateSourceTrigger=LostFocus}" Width="90"/>
                    <DataGridTextColumn Header="Install command line" Binding="{Binding InstallCommand, Mode=TwoWay, UpdateSourceTrigger=LostFocus}" Width="290"/>
                    <DataGridTextColumn Header="Files" Binding="{Binding FileCount}" Width="60" IsReadOnly="True"/>
                    <DataGridTextColumn Header="MB" Binding="{Binding SizeMB}" Width="74" IsReadOnly="True"/>
                    <DataGridTextColumn Header="Notes" Binding="{Binding IssueSummary}" Width="*" IsReadOnly="True"/>
                    <DataGridTextColumn Header="Result" Binding="{Binding Result}" Width="180" IsReadOnly="True"/>
                </DataGrid.Columns>
            </DataGrid>
        </Border>


        <!-- Log -->
        <Border Grid.Row="5" Style="{StaticResource Card}" Padding="10,10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Text="LOG" Style="{StaticResource CardHeader}" Margin="0,0,0,6"/>
                <TextBox Grid.Row="1" x:Name="TxtLog" IsReadOnly="True"
                         VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"
                         TextWrapping="NoWrap" Height="Auto"
                         FontFamily="Cascadia Mono, Consolas" FontSize="11"
                         Background="#0A101C" BorderBrush="#1B2436" Foreground="#B9CBE3"
                         VerticalContentAlignment="Top" Padding="8,6"/>
            </Grid>
        </Border>

        <!-- Actions -->
        <Grid Grid.Row="6" Margin="2,2,2,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <CheckBox Grid.Column="0" x:Name="ChkDryRun" Content="Dry run, do not write to DeployR"
                      IsChecked="True" VerticalAlignment="Center" Margin="0,0,20,0"/>
            <ProgressBar Grid.Column="1" x:Name="Progress" Margin="0,0,20,0" Minimum="0" Maximum="100"
                         VerticalAlignment="Center"/>
            <Button Grid.Column="2" x:Name="BtnExport" Content="Export CSV"/>
            <Button Grid.Column="3" x:Name="BtnCreate" Content="Create in DeployR"
                    Style="{StaticResource PrimaryButton}" MinWidth="160"/>
            <Button Grid.Column="4" x:Name="BtnClose" Content="Close" MinWidth="90" Margin="0"/>
        </Grid>
    </Grid>
</Window>
'@

# ---------------------------------------------------------------------------
# Build the window
# ---------------------------------------------------------------------------

try {
    [xml]$xamlDoc = $xamlText
    $reader = New-Object System.Xml.XmlNodeReader $xamlDoc
    $script:Window = [Windows.Markup.XamlReader]::Load($reader)
}
catch {
    throw "Failed to load the XAML layout. $($_.Exception.Message)"
}

foreach ($controlName in @(
        'TxtShare', 'ChkSkipSize', 'BtnBrowse', 'BtnLoad',
        'ChkUseShareCreds', 'TxtShareUser', 'TxtSharePassword', 'LblShareState', 'BtnTestShare',
        'TxtModulePath', 'BtnBrowseModule', 'BtnLoadModule', 'LblModuleState',
        'TxtSourcesRoot', 'BtnBrowseSources', 'LblFreeSpace',
        'TxtServer', 'TxtPasscode', 'LblConnState', 'BtnConnect',
        'TxtFilter', 'CmbStatus', 'LblCounts', 'BtnSelectReady', 'BtnSelectAll', 'BtnSelectNone',
        'GridApps', 'TxtLog',
        'ChkDryRun', 'Progress', 'BtnExport', 'BtnCreate', 'BtnClose')) {

    $script:Controls[$controlName] = $script:Window.FindName($controlName)
}

$script:Controls.GridApps.ItemsSource = $script:Rows

if ($DeployRModulePath)    { $script:Controls.TxtModulePath.Text = $DeployRModulePath }
if ($SourcesRoot) { $script:Controls.TxtSourcesRoot.Text = $SourcesRoot }
else              { $script:Controls.TxtSourcesRoot.Text = Get-DefaultSourcesRoot }

# Prepopulate the server URL. Explicit parameter wins, otherwise build it from the
# local machine, which is the right answer when running on the DeployR server.
if ($DeployRUrl) {
    $script:Controls.TxtServer.Text = Format-DeployRUrl -Value $DeployRUrl -DefaultPort $DeployRPort
}
else {
    $script:Controls.TxtServer.Text = Get-DefaultDeployRUrl -Port $DeployRPort
}
if ($DeploymentShare)      { $script:Controls.TxtShare.Text  = $DeploymentShare }

if ($ShareCredential) {
    $script:Controls.ChkUseShareCreds.IsChecked = $true
    $script:Controls.TxtShareUser.Text          = $ShareCredential.UserName
    $script:Controls.TxtShareUser.IsEnabled     = $true
    $script:Controls.TxtSharePassword.IsEnabled = $true
    # PasswordBox has no way to take a SecureString back, so the plaintext goes in
    # once here and stays inside the control from that point on.
    $script:Controls.TxtSharePassword.Password  = $ShareCredential.GetNetworkCredential().Password
}

if ($Passcode)             { $script:Controls.TxtPasscode.Password = $Passcode }
if ($SkipSizeCalculation)  { $script:Controls.ChkSkipSize.IsChecked = $true }

# ---------------------------------------------------------------------------
# View filtering and counters
# ---------------------------------------------------------------------------

function Update-RowFilter {
    [CmdletBinding()]
    param()

    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($script:Rows)
    if (-not $view) { return }

    $text = ''
    if ($script:Controls.TxtFilter.Text) { $text = $script:Controls.TxtFilter.Text.Trim() }

    $statusFilter = 'All'
    if ($script:Controls.CmbStatus.SelectedItem) {
        $statusFilter = [string]$script:Controls.CmbStatus.SelectedItem.Content
    }

    $view.Filter = [Predicate[object]] {
        param($item)

        $matchText = $true
        if ($text) {
            $matchText = ($item.MdtName -like "*$text*") -or
                         ($item.DeployRName -like "*$text*") -or
                         ($item.InstallCommand -like "*$text*") -or
                         ($item.Publisher -like "*$text*")
        }

        $matchStatus = $true
        if ($statusFilter -ne 'All') { $matchStatus = ($item.Status -eq $statusFilter) }

        return ($matchText -and $matchStatus)
    }

    $view.Refresh()
}

function Update-Counts {
    [CmdletBinding()]
    param()

    $total    = $script:Rows.Count
    $ready    = @($script:Rows | Where-Object { $_.Status -eq 'Ready' }).Count
    $review   = @($script:Rows | Where-Object { $_.Status -eq 'Review' }).Count
    $blocked  = @($script:Rows | Where-Object { $_.Status -eq 'Blocked' }).Count
    $selected = @($script:Rows | Where-Object { $_.Selected }).Count

    $script:Controls.LblCounts.Text = '{0} apps   |   Ready {1}   Review {2}   Blocked {3}   |   Selected {4}' -f `
        $total, $ready, $review, $blocked, $selected
}

# ---------------------------------------------------------------------------
# Event handlers
# ---------------------------------------------------------------------------

function Select-FolderPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Description,
        [string]$StartPath
    )

    Add-Type -AssemblyName System.Windows.Forms

    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $false

    if ($StartPath -and (Test-Path -LiteralPath $StartPath)) {
        $dialog.SelectedPath = $StartPath
    }

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }

    return $null
}

$script:Controls.BtnBrowse.Add_Click({
    $picked = Select-FolderPath -Description 'Select the MDT deployment share root' -StartPath $script:Controls.TxtShare.Text
    if ($picked) { $script:Controls.TxtShare.Text = $picked }
})

$script:Controls.BtnBrowseModule.Add_Click({
    $start = $script:Controls.TxtModulePath.Text
    if (-not $start) { $start = Join-Path $env:ProgramFiles '2Pint Software' }
    $picked = Select-FolderPath -Description 'Select the folder holding DeployR.Utility' -StartPath $start
    if ($picked) { $script:Controls.TxtModulePath.Text = $picked }
})

function Update-ModuleStateDisplay {
    <#
    .SYNOPSIS
        Reflects the loaded DeployR.Utility version in the UI, or the reason it
        could not be loaded.
    #>
    [CmdletBinding()]
    param(
        $Module,
        [string]$ErrorMessage
    )

    $baseTitle = 'MDT to DeployR application migration'

    if ($Module) {
        $script:Controls.LblModuleState.Text       = ('v{0}' -f $Module.Version)
        $script:Controls.LblModuleState.Foreground = $script:BrushOk
        $script:Controls.LblModuleState.ToolTip    = ('DeployR.Utility {0}{1}{2}' -f $Module.Version, [Environment]::NewLine, $Module.ModuleBase)
        $script:Controls.TxtModulePath.Text        = $Module.ModuleBase
        $script:Window.Title = ('{0}   |   DeployR.Utility {1}' -f $baseTitle, $Module.Version)
    }
    else {
        $script:Controls.LblModuleState.Text       = 'Not loaded'
        $script:Controls.LblModuleState.Foreground = $script:BrushBad
        $script:Controls.LblModuleState.ToolTip    = if ($ErrorMessage) { $ErrorMessage } else { 'DeployR.Utility is not loaded.' }
        $script:Window.Title = $baseTitle
    }
}

function Initialize-DeployRModule {
    <#
    .SYNOPSIS
        Loads DeployR.Utility at startup and shows the version in the UI.

    .DESCRIPTION
        The expectation is that this script runs on the DeployR server, where the
        module is always present, so there is no reason to make the user press a
        button before they can do anything. A failure here is not fatal: analysis
        and CSV export still work, you just cannot create anything.
    #>
    [CmdletBinding()]
    param([switch]$Force)

    # Import and display are kept apart on purpose. A failure to paint the label
    # must never be reported as a failure to load the module.
    $module       = $null
    $errorMessage = $null

    try {
        $module = Import-DeployRModule -Path $script:Controls.TxtModulePath.Text -Force:$Force
    }
    catch {
        $errorMessage = $_.Exception.Message
    }

    try {
        Update-ModuleStateDisplay -Module $module -ErrorMessage $errorMessage
    }
    catch {
        Write-UILog -Message ('Could not update the module display. {0}' -f $_.Exception.Message) -Level 'Warn'
    }

    if (-not $module) {
        Write-UILog -Message $errorMessage -Level 'Warn'
        Write-UILog -Message 'Analysis and CSV export still work. Set the module folder and press Reload to enable creation.' -Level 'Warn'
    }

    return $module
}

$script:Controls.BtnLoadModule.Add_Click({

    $script:Controls.BtnLoadModule.IsEnabled = $false

    try {
        $module = Initialize-DeployRModule -Force

        if (-not $module) {
            [System.Windows.MessageBox]::Show(
                $script:Controls.LblModuleState.ToolTip, 'DeployR module',
                [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
        }
    }
    finally {
        $script:Controls.BtnLoadModule.IsEnabled = $true
    }
})

function Update-FreeSpaceDisplay {
    [CmdletBinding()]
    param()

    $root = $script:Controls.TxtSourcesRoot.Text

    if ([string]::IsNullOrWhiteSpace($root)) {
        $script:Controls.LblFreeSpace.Text = ''
        return
    }

    $freeMB = Get-FreeSpaceMB -Path $root

    if ($null -eq $freeMB) {
        $script:Controls.LblFreeSpace.Text = ''
        return
    }

    $script:Controls.LblFreeSpace.Text = ('{0:N1} GB free' -f ($freeMB / 1024))
}

$script:Controls.BtnBrowseSources.Add_Click({
    $picked = Select-FolderPath -Description 'Select the local sources folder' -StartPath $script:Controls.TxtSourcesRoot.Text
    if ($picked) {
        $script:Controls.TxtSourcesRoot.Text = $picked
        Update-FreeSpaceDisplay
    }
})

$script:Controls.TxtSourcesRoot.Add_LostFocus({ Update-FreeSpaceDisplay })

$script:Controls.ChkUseShareCreds.Add_Click({
    $enabled = [bool]$script:Controls.ChkUseShareCreds.IsChecked
    $script:Controls.TxtShareUser.IsEnabled     = $enabled
    $script:Controls.TxtSharePassword.IsEnabled = $enabled
    if (-not $enabled) { $script:Controls.LblShareState.Text = '' }
})

function Connect-ShareForPath {
    <#
    .SYNOPSIS
        Establishes the share session if needed and reports the outcome in the UI.
        Returns true when the path is usable.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $credential = Get-ShareCredentialFromUI

    if ($credential) {
        $result = Connect-NetworkShare -Path $Path -Credential $credential

        if (-not $result.Connected -and $result.Code -ne 0) {

            # One set of credentials per server is a Windows rule, not our bug, so
            # offer the only real way out rather than just failing.
            if ($result.Code -eq 1219) {
                $answer = [System.Windows.MessageBox]::Show(
                    ($result.Message + [Environment]::NewLine + [Environment]::NewLine +
                     'Drop the existing session to that server and connect with these credentials?'),
                    'Existing connection', [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Question)

                if ($answer -eq [System.Windows.MessageBoxResult]::Yes) {
                    $result = Connect-NetworkShare -Path $Path -Credential $credential -Force
                }
            }
        }

        if (-not $result.Connected -and $result.Code -ne 0) {
            $script:Controls.LblShareState.Text = 'Connect failed'
            $script:Controls.LblShareState.Foreground = $script:BrushBad
            Write-UILog -Message ("Share connect failed. {0}" -f $result.Message) -Level 'Error'
            [System.Windows.MessageBox]::Show($result.Message, 'Deployment share',
                [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
            return $false
        }

        if ($result.Connected) {
            $script:Controls.LblShareState.Text = 'Connected'
            $script:Controls.LblShareState.Foreground = $script:BrushOk
        }
    }
    else {
        $script:Controls.LblShareState.Text = ''
    }

    # Whether or not we authenticated, confirm the path is actually readable.
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-UILog -Message ("Cannot reach '{0}'. Check the path, and whether this account has access." -f $Path) -Level 'Error'
        return $false
    }

    return $true
}

$script:Controls.BtnTestShare.Add_Click({

    $share = $script:Controls.TxtShare.Text
    if ([string]::IsNullOrWhiteSpace($share)) {
        Write-UILog -Message 'Enter the deployment share root first.' -Level 'Warn'
        return
    }

    $script:Controls.BtnTestShare.IsEnabled = $false
    $script:Window.Cursor = [System.Windows.Input.Cursors]::Wait

    try {
        if (-not (Connect-ShareForPath -Path $share)) { return }

        $controlFile = Join-Path -Path $share -ChildPath 'Control\Applications.xml'

        if (Test-Path -LiteralPath $controlFile -PathType Leaf) {
            Write-UILog -Message ("Access confirmed. Found {0}" -f $controlFile) -Level 'Success'
        }
        else {
            Write-UILog -Message ("Path is readable but Control\Applications.xml was not found under '{0}'. Is this the share root?" -f $share) -Level 'Warn'
        }
    }
    catch {
        Write-UILog -Message $_.Exception.Message -Level 'Error'
    }
    finally {
        $script:Window.Cursor = $null
        $script:Controls.BtnTestShare.IsEnabled = $true
    }
})

$script:Controls.BtnLoad.Add_Click({

    $share = $script:Controls.TxtShare.Text
    if ([string]::IsNullOrWhiteSpace($share)) {
        [System.Windows.MessageBox]::Show('Enter the MDT deployment share root first.', 'MDT to DeployR',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }

    $script:Controls.BtnLoad.IsEnabled = $false
    $script:Window.Cursor = [System.Windows.Input.Cursors]::Wait

    try {
        if (-not (Connect-ShareForPath -Path $share)) { return }

        $script:Rows.Clear()
        Update-Counts

        $skip = [bool]$script:Controls.ChkSkipSize.IsChecked
        $items = Get-MdtApplicationInventory -ShareRoot $share -SkipSize:$skip

        foreach ($item in $items) { $script:Rows.Add($item) }

        Update-RowFilter
        Update-Counts

        Write-UILog -Message ('Loaded {0} application(s).' -f $script:Rows.Count) -Level 'Success'
    }
    catch {
        Write-UILog -Message $_.Exception.Message -Level 'Error'
        [System.Windows.MessageBox]::Show($_.Exception.Message, 'MDT to DeployR',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
    finally {
        $script:Window.Cursor = $null
        $script:Controls.BtnLoad.IsEnabled = $true
    }
})

$script:Controls.BtnConnect.Add_Click({

    $script:Controls.BtnConnect.IsEnabled = $false
    $script:Window.Cursor = [System.Windows.Input.Cursors]::Wait

    try {
        Connect-DeployRServer -ModulePath $script:Controls.TxtModulePath.Text `
                              -Url $script:Controls.TxtServer.Text `
                              -Code $script:Controls.TxtPasscode.Password

        $script:Controls.LblConnState.Text = 'Connected'
        $script:Controls.LblConnState.Foreground = $script:BrushOk

        # Keep the token lifetime visible rather than buried in the log.
        if ($script:TokenExpiry) {
            $script:Controls.LblConnState.Text = ('Connected, token to {0}' -f $script:TokenExpiry)
        }

        $tip = @($script:AuthSummary, $(if ($script:TokenExpiry) { 'Token valid until ' + $script:TokenExpiry } else { '' })) |
               Where-Object { $_ }
        if ($tip) { $script:Controls.LblConnState.ToolTip = ($tip -join [Environment]::NewLine) }

        # Connect imports the module if it was not already there, so keep the
        # version display in step.
        Update-ModuleStateDisplay -Module (Get-Module -Name 'DeployR.Utility')
    }
    catch {
        $script:DeployRConnected = $false
        $script:Controls.LblConnState.Text = 'Not connected'
        $script:Controls.LblConnState.Foreground = $script:BrushBad
        Write-UILog -Message ('Connect failed: {0}' -f $_.Exception.Message) -Level 'Error'
    }
    finally {
        $script:Window.Cursor = $null
        $script:Controls.BtnConnect.IsEnabled = $true
    }
})

$script:Controls.TxtFilter.Add_TextChanged({ Update-RowFilter })
$script:Controls.CmbStatus.Add_SelectionChanged({ Update-RowFilter })

$script:Controls.BtnSelectReady.Add_Click({
    foreach ($row in $script:Rows) { $row.Selected = ($row.Status -eq 'Ready') }
    $script:Controls.GridApps.Items.Refresh()
    Update-Counts
})

$script:Controls.BtnSelectAll.Add_Click({
    foreach ($row in $script:Rows) {
        if ($row.Status -ne 'Blocked') { $row.Selected = $true }
    }
    $script:Controls.GridApps.Items.Refresh()
    Update-Counts
})

$script:Controls.BtnSelectNone.Add_Click({
    foreach ($row in $script:Rows) { $row.Selected = $false }
    $script:Controls.GridApps.Items.Refresh()
    Update-Counts
})


$script:Controls.BtnExport.Add_Click({

    if ($script:Rows.Count -eq 0) {
        Write-UILog -Message 'Nothing to export. Load a deployment share first.' -Level 'Warn'
        return
    }

    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.Filter = 'CSV file (*.csv)|*.csv'
    $dialog.FileName = [System.IO.Path]::GetFileName($ReportPath)
    $dialog.InitialDirectory = [System.IO.Path]::GetDirectoryName($ReportPath)

    if ($dialog.ShowDialog() -ne $true) { return }

    try {
        $script:Rows |
            Select-Object Status, MdtName, DeployRName, TargetVersion, InstallCommand,
                          SourceFolder, SourceExists, StagedFolder, FileCount, SizeMB, Publisher,
                          MdtVersion, Language, Enabled, Hidden, IsBundle, Dependencies,
                          Platforms, UninstallKey, Guid, Result,
                          @{ Name = 'Issues'; Expression = { $_.IssuesText -replace "`r`n", ' | ' } },
                          @{ Name = 'Notes';  Expression = { $_.NotesText  -replace "`r`n", ' | ' } } |
            Export-Csv -LiteralPath $dialog.FileName -NoTypeInformation -Encoding UTF8

        Write-UILog -Message ('Report written to {0}' -f $dialog.FileName) -Level 'Success'
    }
    catch {
        Write-UILog -Message ('Export failed: {0}' -f $_.Exception.Message) -Level 'Error'
    }
})

$script:Controls.BtnCreate.Add_Click({

    $selected = @($script:Rows | Where-Object { $_.Selected })

    if ($selected.Count -eq 0) {
        Write-UILog -Message 'No applications selected.' -Level 'Warn'
        return
    }

    $dryRun = [bool]$script:Controls.ChkDryRun.IsChecked
    $root   = ([string]$script:Controls.TxtSourcesRoot.Text).Trim()

    if ([string]::IsNullOrWhiteSpace($root)) {
        [System.Windows.MessageBox]::Show(
            'Set the sources folder first. Content is always copied there before the content item is created.',
            'Sources folder', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        $script:Controls.TxtSourcesRoot.Focus() | Out-Null
        return
    }

    if ($root.StartsWith('\\')) {
        $answer = [System.Windows.MessageBox]::Show(
            ('The sources folder is a UNC path. The point of copying content is to end up with a local source tree on the DeployR server. Use {0} anyway?' -f $root),
            'Sources folder is remote', [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)

        if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
    }

    if (-not $dryRun -and -not $script:DeployRConnected) {
        [System.Windows.MessageBox]::Show('Connect to DeployR first, or tick the dry run box.', 'MDT to DeployR',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }

    # Catch a sources folder on a drive that is not there before copying anything.
    if (-not $dryRun -and -not $root.StartsWith('\\')) {
        $driveRoot = [System.IO.Path]::GetPathRoot($root)
        if ($driveRoot -and -not (Test-Path -LiteralPath $driveRoot)) {
            [System.Windows.MessageBox]::Show(
                ("The sources folder points at {0}, which is not available on this machine." -f $driveRoot),
                'Sources folder', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
            return
        }
    }

    # The copy moves real bytes, so check there is room before starting rather than
    # failing partway through a few hundred applications.
    if (-not $dryRun) {

        $requiredMB = [math]::Round((@($selected | Measure-Object -Property SizeMB -Sum).Sum), 2)
        $freeMB     = Get-FreeSpaceMB -Path $root

        if ($requiredMB -gt 0 -and $null -ne $freeMB) {

            Write-UILog -Message ('Copy needs about {0:N0} MB, {1:N0} MB free on the sources volume.' -f $requiredMB, $freeMB)

            if ($freeMB -lt $requiredMB) {
                $answer = [System.Windows.MessageBox]::Show(
                    ('The copy needs roughly {0:N0} MB but only {1:N0} MB is free on that volume. Continue anyway?' -f $requiredMB, $freeMB),
                    'Not enough space', [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)

                if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
            }
        }
        elseif ($requiredMB -eq 0) {
            Write-UILog -Message 'Content sizes are unknown because the size scan was skipped, so the free space check was not run.' -Level 'Warn'
        }
    }

    if (-not $dryRun) {
        $answer = [System.Windows.MessageBox]::Show(
            ('Create or update {0} application content item(s) in DeployR?' -f $selected.Count),
            'Confirm', [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
        if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
    }

    $script:Controls.BtnCreate.IsEnabled = $false
    $script:Controls.Progress.Value = 0
    $script:Controls.Progress.Maximum = $selected.Count

    $ok = 0
    $failed = 0
    $counter = 0

    Write-UILog -Message ('Starting {0} for {1} application(s).' -f $(if ($dryRun) { 'dry run' } else { 'creation' }), $selected.Count)

    foreach ($row in $selected) {

        $counter++
        $row.Result = 'Working...'
        $script:Controls.GridApps.Items.Refresh()

        if (New-DeployRApplicationFromRow -Row $row -SourcesRoot $root -DryRun:$dryRun) { $ok++ } else { $failed++ }

        $script:Controls.Progress.Value = $counter
        $script:Controls.GridApps.Items.Refresh()
        Invoke-UIRefresh
    }

    $script:Controls.BtnCreate.IsEnabled = $true

    Write-UILog -Message ('Finished. Succeeded {0}, skipped or failed {1}.' -f $ok, $failed) -Level 'Success'

    if (-not $dryRun -and $script:DeployRConnected) {
        try { $script:ExistingApps = @(Get-DeployRApplication -ErrorAction SilentlyContinue) } catch { }
    }
})

$script:Controls.BtnClose.Add_Click({ $script:Window.Close() })

$script:Window.Add_Closed({
    # Only removes sessions this script created. Anything that was already there
    # when we started is left alone.
    if ($script:ConnectedShares.Count -gt 0) { Disconnect-NetworkShares }
})

$script:Rows.Add_CollectionChanged({ Update-Counts })

# ---------------------------------------------------------------------------
# Go
# ---------------------------------------------------------------------------

$script:Window.Add_SourceInitialized({
    # The window handle only exists from this point, and the frame has not been
    # painted yet, so there is no flash of a light title bar.
    Set-WindowChrome -Window $script:Window
})

$script:Window.Add_ContentRendered({

    # Running on the DeployR server is the expected case, so load the module up
    # front rather than making the user ask for it.
    $module = Initialize-DeployRModule

    Update-FreeSpaceDisplay

    if ($module) {
        Write-UILog -Message 'Ready. Point at an MDT deployment share and choose Load apps.'
    }
    else {
        Write-UILog -Message 'Ready for analysis. Creating apps needs DeployR.Utility, which did not load.' -Level 'Warn'
    }

    if ($script:Controls.TxtShare.Text) {
        $script:Controls.BtnLoad.RaiseEvent(
            (New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
    }
})

$null = $script:Window.ShowDialog()
