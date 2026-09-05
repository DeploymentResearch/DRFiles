<#
.SYNOPSIS
    Install script for an Intune Win32 app that copies a tools folder.
.DESCRIPTION
    Copies the packaged files to the target folder on the device and writes a log file, as the
    install command for a file copy style Win32 application.
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
      1.0.0 - 2022-12-02 - Initial release
#>

$LogFile = "C:\Windows\Temp\ViaMonstraTools_Install.log"
$TargetFolder = "C:\Tools"
$SourceFolder = $PSScriptRoot

# Delete any existing logfile if it exists
If (Test-Path $LogFile){Remove-Item $LogFile -Force -ErrorAction SilentlyContinue -Confirm:$false}

Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
    )

    $TimeGenerated = $(Get-Date -UFormat "%D %T")
    $Line = "$TimeGenerated : $Message"
    Add-Content -Value $Line -Path $LogFile -Encoding Ascii
}

Write-Log "Starting the ViaMonstra Lab Tools installer"

# Make sure target folder exists
If (!(Test-Path $TargetFolder)){ 
    Write-Log "Target folder $TargetFolder does not exist, creating it"
    New-Item -Path $TargetFolder -ItemType Directory -Force
}

# Copy the tools
Write-Log "About to copy contents from $SourceFolder to $TargetFolder"
try {
    Copy-Item -Path "$SourceFolder\*" -Destination $TargetFolder -Recurse -Force -ErrorAction Stop
    Write-Log "Contents of $SourceFolder successfully copied to $TargetFolder"
} 
catch {
    Write-Log "Failed to copy $SourceFolder to $TargetFolder. Error is: $($_.Exception.Message))"
}
  

