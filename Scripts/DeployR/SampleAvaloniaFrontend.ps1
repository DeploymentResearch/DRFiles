<#
.SYNOPSIS
    Prompts for a computer name during OSD using Avalonia, hosted directly in PowerShell.

.DESCRIPTION
    Avalonia replacement for the WPF version. Avoids the Microsoft.WindowsDesktop.App
    framework reference entirely, so it runs in any .NET host, and has no STA requirement.

    Runs in both a WinPE boot image and a Linux boot image. The windowing backend and
    the rendering options are selected at runtime based on the platform.

    Avalonia assemblies are loaded from -AvaloniaPath at runtime. XAML is parsed at
    runtime via AvaloniaRuntimeXamlLoader, so nothing here is precompiled.

    The accepted name is written to -OutFile and to stdout.

.PARAMETER AvaloniaPath
    Folder containing the Avalonia managed DLLs and their native dependencies.

.PARAMETER OutFile
    File to receive the accepted computer name.

.EXITCODES
    0   Name accepted, written to OutFile
    1   User cancelled or closed the window
    2   Avalonia failed to initialise, or the UI failed to build
#>

[CmdletBinding()]
param(
    [string]$AvaloniaPath,
    [string]$OutFile,
    [string]$LogPath
)

# ---------------------------------------------------------------- config
$MinLength      = 1
$MaxLength      = 15
$ForceUpperCase = $true
$LogFileName    = "OSDComputerName.log"
$LogComponent   = "OSDComputerName"

$ValidNamePattern = "^[A-Za-z0-9]$|^[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]$"

# ---------------------------------------------------------------- platform
# $IsWindows and $IsLinux are automatic variables in PowerShell 6 and later. They are
# not present in Windows PowerShell 5.1, so derive them if they are missing.
if ($null -eq $IsWindows) {
    $IsWindows = $true
    $IsLinux   = $false
}

# $env:TEMP exists only on Windows. On Linux it is null, and Join-Path then fails with
# "Cannot bind argument to parameter 'Path' because it is null". GetTempPath() honours
# TMPDIR when set and falls back to /tmp, so it is safe on both platforms.
$TempDir = [System.IO.Path]::GetTempPath()

if ([string]::IsNullOrWhiteSpace($OutFile)) {
    $OutFile = Join-Path $TempDir "computername.txt"
}

# ---------------------------------------------------------------- logging
if ([string]::IsNullOrWhiteSpace($LogPath) -or -not (Test-Path $LogPath)) {
    $LogPath = $TempDir
}
$LogFile = Join-Path $LogPath $LogFileName

function Write-Log {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)] $Message,
        [Parameter(Mandatory=$false)] $ErrorMessage,
        [Parameter(Mandatory=$false)] $Component = "Script",
        [Parameter(Mandatory=$false)] [int]$Type = 1
    )
    $Time = Get-Date -Format "HH:mm:ss.ffffff"
    $Date = Get-Date -Format "MM-dd-yyyy"
    if ($null -ne $ErrorMessage) { $Type = 3 }
    $LogMessage = "<![LOG[$Message $ErrorMessage" + "]LOG]!><time=`"$Time`" date=`"$Date`" component=`"$Component`" context=`"`" type=`"$Type`" thread=`"`" file=`"`">"
    $LogMessage.Replace("`0","") | Out-File -Append -Encoding UTF8 -FilePath $LogFile
}

Write-Log "Starting Avalonia computer name prompt. Logging to $LogFile" -Component $LogComponent
Write-Log "Host: $((Get-Process -Id $PID).Path)" -Component $LogComponent
Write-Log "Runtime: $([System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription)" -Component $LogComponent
Write-Log "OS: $([System.Runtime.InteropServices.RuntimeInformation]::OSDescription)" -Component $LogComponent
Write-Log "TempDir: $TempDir  OutFile: $OutFile" -Component $LogComponent

# GetApartmentState is only meaningful on Windows. Guard it so a platform exception
# cannot take the script down before the UI is even attempted.
try {
    Write-Log "Apartment: $([System.Threading.Thread]::CurrentThread.GetApartmentState())" -Component $LogComponent
}
catch {
    Write-Log "Apartment state not available on this platform" -Component $LogComponent
}

# ---------------------------------------------------------------- assemblies

# $PSScriptRoot is empty unless the script was invoked with -File or dot-sourced from
# disk. Fall back through the likely locations rather than depending on it.
Write-Log "PSScriptRoot: '$PSScriptRoot'  CurrentDir: '$($PWD.Path)'" -Component $LogComponent

Import-Module DeployR.Utility
$DeployRoot = ${TSEnv:DEPLOYRROOT}
Write-Log "DeployRoot is: $DeployRoot" -Component $LogComponent

# Join-Path, not "$DeployRoot\Client". A backslash is a literal filename character on
# Linux, not a directory separator.
if ([string]::IsNullOrWhiteSpace($AvaloniaPath)) {
    $AvaloniaPath = Join-Path $DeployRoot "Client"
}
Write-Log "Using Avalonia path: $AvaloniaPath" -Component $LogComponent

if (-not (Test-Path $AvaloniaPath)) {
    Write-Log "Avalonia path does not exist" -ErrorMessage $AvaloniaPath -Component $LogComponent
    exit 2
}

# Load only what we need. This folder may be a host application's directory containing
# assemblies that conflict with the ones we want, so a blanket load is not safe.
# The managed assemblies keep the .dll extension on Linux; only the native SkiaSharp
# and HarfBuzzSharp payloads differ (libSkiaSharp.so / libHarfBuzzSharp.so).
$Wanted = @(
    "Avalonia.Base.dll"
    "Avalonia.dll"
    "Avalonia.Controls.dll"
    "Avalonia.Desktop.dll"
    "Avalonia.Dialogs.dll"
    "Avalonia.Fonts.Inter.dll"
    "Avalonia.Markup.dll"
    "Avalonia.Markup.Xaml.dll"
    "Avalonia.Markup.Xaml.Loader.dll"
    "Avalonia.Metal.dll"
    "Avalonia.MicroCom.dll"
    "Avalonia.OpenGL.dll"
    "Avalonia.Remote.Protocol.dll"
    "Avalonia.Skia.dll"
    "Avalonia.Themes.Fluent.dll"
    "Avalonia.Themes.Simple.dll"
    "HarfBuzzSharp.dll"
    "SkiaSharp.dll"
)

if ($IsWindows) {
    $Wanted += "Avalonia.Win32.dll"
}
else {
    # Without these two, UsePlatformDetect has no windowing backend to find and
    # SetupWithoutStarting throws.
    $Wanted += "Avalonia.X11.dll"
    $Wanted += "Avalonia.FreeDesktop.dll"
}

$Loaded  = 0
$Missing = @()
foreach ($dll in $Wanted) {
    $Full = Join-Path $AvaloniaPath $dll
    if (-not (Test-Path $Full)) { $Missing += $dll; continue }
    try {
        [System.Reflection.Assembly]::LoadFrom($Full) | Out-Null
        $Loaded++
    }
    catch {
        Write-Log "Could not load $dll" -ErrorMessage $_.Exception.Message -Component $LogComponent -Type 2
    }
}
Write-Log "Loaded $Loaded of $($Wanted.Count) candidate assemblies from $AvaloniaPath" -Component $LogComponent
if ($Missing.Count -gt 0) {
    Write-Log "Not present: $($Missing -join ', ')" -Component $LogComponent -Type 2
}

# Report the Avalonia version actually in play, and confirm the runtime XAML loader is
# present. A published Avalonia app compiles its XAML and does not ship the loader.
$BaseDll = Join-Path $AvaloniaPath "Avalonia.Base.dll"
if (Test-Path $BaseDll) {
    $BaseVer = [Reflection.AssemblyName]::GetAssemblyName($BaseDll).Version
    Write-Log "Avalonia.Base version: $BaseVer" -Component $LogComponent
}

if (-not (Test-Path (Join-Path $AvaloniaPath "Avalonia.Markup.Xaml.Loader.dll"))) {
    Write-Log "Avalonia.Markup.Xaml.Loader.dll is not present in $AvaloniaPath" -ErrorMessage "Runtime XAML parsing requires this package, version-matched to Avalonia.Base" -Component $LogComponent
    exit 2
}

if (-not ([System.Management.Automation.PSTypeName]'Avalonia.AppBuilder').Type) {
    Write-Log "Avalonia.AppBuilder not found after loading assemblies" -ErrorMessage "Check that Avalonia.Base.dll and Avalonia.Controls.dll are present" -Component $LogComponent
    exit 2
}

# ---------------------------------------------------------------- X11 display
# The X server is running in the Linux boot image, but the process DeployR spawns does
# not necessarily inherit DISPLAY. Without it, X11 platform initialisation fails.
if (-not $IsWindows) {
    if ([string]::IsNullOrWhiteSpace($env:DISPLAY)) {
        $env:DISPLAY = ":0"
        Write-Log "DISPLAY was not set, defaulting to :0" -Component $LogComponent -Type 2
    }
    else {
        Write-Log "DISPLAY is: $($env:DISPLAY)" -Component $LogComponent
    }
}

# ---------------------------------------------------------------- app bootstrap
try {
    $Builder = [Avalonia.AppBuilder]::Configure[Avalonia.Application]()

    # UsePlatformDetect and WithInterFont are C# extension methods. PowerShell cannot
    # call extension methods with instance syntax, so they are invoked statically.
    $Builder = [Avalonia.AppBuilderDesktopExtensions]::UsePlatformDetect($Builder)

    # Force software rendering. Neither boot image has a usable GPU.
    try {
        if ($IsWindows) {
            $Opts  = [Avalonia.Win32PlatformOptions]::new()
            $Modes = [System.Collections.Generic.List[Avalonia.Win32RenderingMode]]::new()
            $Modes.Add([Avalonia.Win32RenderingMode]::Software)
            $Opts.RenderingMode = $Modes
            $Builder = $Builder.With[Avalonia.Win32PlatformOptions]($Opts)
            Write-Log "Win32 software rendering mode set" -Component $LogComponent
        }
        else {
            $Opts  = [Avalonia.X11PlatformOptions]::new()
            $Modes = [System.Collections.Generic.List[Avalonia.X11RenderingMode]]::new()
            $Modes.Add([Avalonia.X11RenderingMode]::Software)
            $Opts.RenderingMode = $Modes
            $Builder = $Builder.With[Avalonia.X11PlatformOptions]($Opts)
            Write-Log "X11 software rendering mode set" -Component $LogComponent
        }
    }
    catch {
        Write-Log "Could not set software rendering, continuing with defaults" -ErrorMessage $_.Exception.Message -Component $LogComponent -Type 2
    }

    # Embedded font, so the UI does not depend on the boot image having any installed
    # fonts. This matters more on Linux, where there may be no fontconfig cache at all.
    try {
        $Builder = [Avalonia.InterFontApplicationBuilderExtension]::WithInterFont($Builder)
        Write-Log "Inter font embedded" -Component $LogComponent
    }
    catch {
        Write-Log "WithInterFont unavailable, falling back to system fonts" -Component $LogComponent -Type 2
    }

    $Builder.SetupWithoutStarting() | Out-Null

    [Avalonia.Application]::Current.Styles.Add([Avalonia.Themes.Fluent.FluentTheme]::new())
    Write-Log "Avalonia initialised" -Component $LogComponent
}
catch {
    Write-Log "Failed to initialise Avalonia" -ErrorMessage $_.Exception.ToString() -Component $LogComponent
    exit 2
}

# ---------------------------------------------------------------- ui
# Note the Avalonia namespace URI, and CanResize in place of WPF's ResizeMode.
# FontFamily is left to the theme rather than hard-coded to Consolas, which does not
# exist in a Linux boot image.
$Xaml = @"
<Window xmlns="https://github.com/avaloniaui"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Computer Name"
        Width="440"
        SizeToContent="Height"
        WindowStartupLocation="CenterScreen"
        CanResize="False"
        Topmost="True"
        Background="#FFF5F5F5"
        FontSize="13">
    <StackPanel Margin="22">

        <TextBlock Text="Please enter the computer name"
                   FontSize="17"
                   FontWeight="SemiBold"
                   Foreground="#FF1F1F1F"
                   Margin="0,0,0,4"/>

        <TextBlock x:Name="HintText"
                   Foreground="#FF6E6E6E"
                   TextWrapping="Wrap"
                   Margin="0,0,0,14"/>

        <TextBox x:Name="NameBox"
                 Padding="8,6"
                 FontSize="16"
                 BorderBrush="#FFB0B0B0"
                 BorderThickness="1"/>

        <TextBlock x:Name="StatusText"
                   Margin="2,7,0,0"
                   FontSize="12"
                   TextWrapping="Wrap"
                   MinHeight="17"/>

        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,18,0,0">
            <Button x:Name="OkButton"
                    Content="OK"
                    Width="96" Height="31"
                    Margin="0,0,8,0"
                    IsDefault="True"
                    IsEnabled="False"/>
            <Button x:Name="CancelButton"
                    Content="Cancel"
                    Width="96" Height="31"
                    IsCancel="True"/>
        </StackPanel>

    </StackPanel>
</Window>
"@

try {
    $Window = [Avalonia.Markup.Xaml.AvaloniaRuntimeXamlLoader]::Parse($Xaml)
}
catch {
    Write-Log "Failed to parse XAML" -ErrorMessage $_.Exception.ToString() -Component $LogComponent
    exit 2
}

# Avalonia has no FindName. Resolve through the name scope instead.
function Get-Control {
    param($Root, [string]$Name)
    $Scope = [Avalonia.Controls.NameScope]::GetNameScope($Root)
    if ($null -eq $Scope) { throw "No name scope on the root element" }
    $Ctl = $Scope.Find($Name)
    if ($null -eq $Ctl) { throw "Control not found: $Name" }
    return $Ctl
}

try {
    $NameBox      = Get-Control $Window "NameBox"
    $HintText     = Get-Control $Window "HintText"
    $StatusText   = Get-Control $Window "StatusText"
    $OkButton     = Get-Control $Window "OkButton"
    $CancelButton = Get-Control $Window "CancelButton"
}
catch {
    Write-Log "Failed to resolve named controls" -ErrorMessage $_.Exception.Message -Component $LogComponent
    exit 2
}

# Avalonia will not convert a colour string to IBrush on property assignment the way
# WPF's type converter did. Build the brushes once, up front.
$BrushGrey  = [Avalonia.Media.Brush]::Parse("#FF6E6E6E")
$BrushRed   = [Avalonia.Media.Brush]::Parse("#FFC02626")
$BrushGreen = [Avalonia.Media.Brush]::Parse("#FF1E7B34")

$NameBox.MaxLength = $MaxLength
$HintText.Text = "$MinLength to $MaxLength characters. Letters, numbers and hyphens. Cannot start or end with a hyphen, and cannot be all numbers."

# ---------------------------------------------------------------- validation
$script:Accepted = $false

$Validate = {
    # Avalonia has no CharacterCasing. Upper-case in the handler and restore the caret.
    if ($ForceUpperCase -and $NameBox.Text) {
        $Raw = $NameBox.Text
        $Upper = $Raw.ToUpperInvariant()
        if ($Raw -cne $Upper) {
            $Caret = $NameBox.CaretIndex
            $NameBox.Text = $Upper
            $NameBox.CaretIndex = $Caret
            return   # the re-entrant TextChanged will finish validation
        }
    }

    $Name = ""
    if ($NameBox.Text) { $Name = $NameBox.Text.Trim() }
    $Len = $Name.Length

    if ($Len -lt $MinLength) {
        $StatusText.Foreground = $BrushGrey
        $StatusText.Text       = "0 / $MaxLength characters"
        $OkButton.IsEnabled    = $false
        return
    }

    if ($Name -notmatch $ValidNamePattern) {
        $StatusText.Foreground = $BrushRed
        $StatusText.Text       = "Invalid character, or the name starts or ends with a hyphen."
        $OkButton.IsEnabled    = $false
        return
    }

    if ($Name -match "^[0-9]+$") {
        $StatusText.Foreground = $BrushRed
        $StatusText.Text       = "The name cannot consist only of numbers."
        $OkButton.IsEnabled    = $false
        return
    }

    $StatusText.Foreground = $BrushGreen
    $StatusText.Text       = "$Len / $MaxLength characters. Name is valid."
    $OkButton.IsEnabled    = $true
}

$NameBox.Add_TextChanged($Validate)

# Avalonia windows have no DialogResult. Track the outcome and close.
# Hide() unmaps the X11 window and lets the dispatcher process the expose events for
# whatever is underneath it. Win32 destroys synchronously and does not need this, but
# it is harmless there. Without it, JWM has no compositor to repaint the region and a
# ghost of the dialog stays on screen after the window is gone.
$OkButton.Add_Click({
    $script:Accepted = $true
    $Window.Hide()
    $Window.Close()
})

$CancelButton.Add_Click({
    $script:Accepted = $false
    $Window.Hide()
    $Window.Close()
})

$Window.Add_Opened({
    $NameBox.Focus() | Out-Null
    & $Validate
})

# ---------------------------------------------------------------- run
# SetupWithoutStarting does not spin a message loop. Drive one manually and stop it
# when the window closes.
$Cts = [System.Threading.CancellationTokenSource]::new()

# Post the cancel rather than calling it inline. Background priority runs after the
# queued input, layout, render and platform teardown jobs, so the X11 backend gets to
# flush the window destroy to the server before the loop stops. Cancelling inline
# stops the loop first and the request is never sent.
$Window.Add_Closed({
    [Avalonia.Threading.Dispatcher]::UIThread.Post(
        [System.Action]{ $Cts.Cancel() },
        [Avalonia.Threading.DispatcherPriority]::Background
    )
})

Write-Log "Displaying the computer name dialog" -Component $LogComponent

try {
    $Window.Show()
    [Avalonia.Threading.Dispatcher]::UIThread.MainLoop($Cts.Token)
}
catch [System.OperationCanceledException] {
    # Expected: MainLoop exits by cancellation when the window closes.
}
catch {
    Write-Log "Dispatcher loop failed" -ErrorMessage $_.Exception.ToString() -Component $LogComponent
    exit 2
}

# Flush any teardown jobs the loop did not reach before cancellation.
try { [Avalonia.Threading.Dispatcher]::UIThread.RunJobs() } catch { }

if (-not $script:Accepted) {
    Write-Log "User cancelled the computer name prompt." -Component $LogComponent -Type 2
    exit 1
}

$ComputerName = $NameBox.Text.Trim()

# Write Computer Name to text file
try {
    Set-Content -Path $OutFile -Value $ComputerName -Encoding UTF8 -NoNewline
    Write-Output $ComputerName

    Write-Log "Computer name '$ComputerName' written to $OutFile" -Component $LogComponent
}
catch {
    Write-Log "Failed to write the computer name to $OutFile" -ErrorMessage $_.Exception.Message -Component $LogComponent
    exit 2
}

# Set Computer Name as variable
try {
    if (Get-Module -Name "DeployR.Utility") {
        ${TSEnv:ComputerName} = $ComputerName
    }
    else {
        $env:ComputerName = $ComputerName
    }
    Write-Log "OSDComputerName set to: $ComputerName" -Component $LogComponent -Type 1
}
catch {
    Write-Log "Failed to set the OSDComputerName task sequence variable" -ErrorMessage $_.Exception.Message -Component $LogComponent
}

exit 0