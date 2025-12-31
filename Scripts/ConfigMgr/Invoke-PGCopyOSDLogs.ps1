<#
.SYNOPSIS
  Invoke-PGCopyOSDLogs.ps1

.DESCRIPTION
  A Pretty Good Copy OSD Logs Script for ConfigMgr (SCCM). The script will archive multiple OSD-related
  log files into a zip archive and upload it to the specified shared folder.

  Script uses the following task sequence variables:
  SLShare: UNC Path to shared folder
  LogCopyUsername: User name to connect to shared folder
  LogCopyPassword: Password for the LogCopyUsername

.NOTES
  Version:        1.0
  Author:         @jarwidmark
  Creation Date:  05/01/2025
  Purpose/Change: Initial script development
  Credits:        Johan Schrewelius, Onevinn AB for Authenticate and ZipFiles functions

  Version history:
  1.0.0 - 05/01/2025 - Initial script development

#>


function Authenticate {
    param(
        [string]$UNCPath = $(Throw "An UNCPath must be specified"),
        [string]$User,
        [string]$PW
    )

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "net.exe"
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = "USE $($UNCPath) /USER:$($User) $($PW)"
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
}

function ZipFiles {
    param(
        [string]$ZipFileName,
        [string]$SourceDir
    )

   Add-Type -Assembly System.IO.Compression.FileSystem
   $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
   [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceDir, $ZipFileName, $compressionLevel, $false)
}

try {
    $dt = get-date -Format "MM-dd-yyyy-HH-mm-ss"
    $tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
    $LogPath = $tsenv.Value("SLShare")
    $ComputerName = $tsenv.Value("OSDComputerName")
    $source =  $tsenv.Value("_SMSTSLogPath")
    $LogCopyUsername = $tsenv.Value("LogCopyUsername")
    $LogCopyPassword = $tsenv.Value("LogCopyPassword")

    New-Item "$source\tmp" -ItemType Directory -Force

    # Validate ComputerName
    If ($ComputerName) {
        # All good
    }
    Else{
        # Set Computer name to local host name
        $ComputerName = $Env:COMPUTERNAME
    }
    
    # Copy main ConfigMgr logs (always smsts.log, but can be others).
    Copy-Item "$source\*" "$source\tmp" -Force -Exclude "tmp"

    # List other OSD-Related logs to copy, including the target folder 
    $FilesToCopy = @()
    $FilesToCopy += [pscustomobject]@{ SourceFile = "$Env:SystemRoot\Panther\Setupact.log"; TargetFolder = "$source\tmp\Panther"}
    $FilesToCopy += [pscustomobject]@{ SourceFile = "$Env:SystemRoot\Panther\Setuperr.log"; TargetFolder = "$source\tmp\Panther"}
    $FilesToCopy += [pscustomobject]@{ SourceFile = "$Env:SystemRoot\Panther\UnattendGC\Setupact.log"; TargetFolder = "$source\tmp\Panther\UnattendGC"}
    $FilesToCopy += [pscustomobject]@{ SourceFile = "$Env:SystemRoot\Panther\UnattendGC\Setuperr.log"; TargetFolder = "$source\tmp\Panther\UnattendGC"}
    $FilesToCopy += [pscustomobject]@{ SourceFile = "$Env:SystemRoot\Debug\NetSetup.LOG"; TargetFolder = "$source\tmp"}
    $FilesToCopy += [pscustomobject]@{ SourceFile = "$Env:SystemRoot\Logs\DISM\dism.log"; TargetFolder = "$source\tmp"}
    $FilesToCopy += [pscustomobject]@{ SourceFile = "$Env:SystemRoot\System32\wpeinit.log"; TargetFolder = "$source\tmp"}
    $FilesToCopy += [pscustomobject]@{ SourceFile = "$Env:SystemRoot\Inf\setupapi.dev.log"; TargetFolder = "$source\tmp"}

    # Loop through each file in list, and copy to the correct folder
    foreach ($File in $FilesToCopy) {
        
        # Check for log file
        If (Test-path $File.SourceFile) {

            # Create target folder if not exists
            If (-not(Test-path $File.TargetFolder)) {
                New-Item -Path $File.TargetFolder -ItemType Directory
            }
            
            # Copy the log file
            Copy-Item -Path $File.SourceFile -Destination $File.TargetFolder
        }
    }

    # Set source folder for Zip Archive
    $ZipArchiveSource = "$source\tmp"

    try { # Catch Error if already authenticated
        Authenticate -UNCPath $LogPath -User $LogCopyUsername -PW $LogCopyPassword
    }
    catch {}

    $ZipArchive =  Join-Path -Path "$LogPath" -ChildPath "$($ComputerName )-$($dt).zip"
    ZipFiles -ZipFileName $ZipArchive -SourceDir $ZipArchiveSource

    Remove-Item -Path "$ZipArchiveSource" -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Output "$_.Exception.Message"
    exit 1
}