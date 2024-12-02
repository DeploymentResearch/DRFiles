# Script to check for SetupConfig.ini file (with the correct version) 

$SetupConfigPath = "C:\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini"
$CompliantVersion = "1.2"
$LogPath = "C:\ProgramData\FeatureUpdate\Logs"
$Logfile = "$LogPath\IntuneAdvancedFeatureUpdate_Discovery.log"

# Create log path
New-Item -Path $LogPath -ItemType Directory -Force

# Delete any existing log file if it exists
If (Test-Path $Logfile){Remove-Item $Logfile -Force -ErrorAction SilentlyContinue -Confirm:$false}

function Write-Log {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        $Message,
        [Parameter(Mandatory=$false)]
        $ErrorMessage,
        [Parameter(Mandatory=$false)]
        $Component = "Script",
        [Parameter(Mandatory=$false)]
        [int]$Type
    )
    <#
    Type: 1 = Normal, 2 = Warning (yellow), 3 = Error (red)
    #>
   $Time = Get-Date -Format "HH:mm:ss.ffffff"
   $Date = Get-Date -Format "MM-dd-yyyy"
   if ($ErrorMessage -ne $null) {$Type = 3}
   if ($Component -eq $null) {$Component = " "}
   if ($Type -eq $null) {$Type = 1}
   $LogMessage = "<![LOG[$Message $ErrorMessage" + "]LOG]!><time=`"$Time`" date=`"$Date`" component=`"$Component`" context=`"`" type=`"$Type`" thread=`"`" file=`"`">"
   $LogMessage.Replace("`0","") | Out-File -Append -Encoding UTF8 -FilePath $LogFile
}

Write-Log "Checking for $SetupConfigPath with a version of $CompliantVersion"
$Result = Test-Path $SetupConfigPath
if ($Result -eq "True"){
    # File found, continuing to check for version
    Write-Log "$SetupConfigPath found, continuing to check for version"
    $Searchtext = ";Version="
    $Version = ((Get-Content $SetupConfigPath | Select-String -Pattern $Searchtext -SimpleMatch) -split $Searchtext)[1].Trim() 
    If ($Version -eq $CompliantVersion){
        
        Write-Log "Matching version $Version found, all good"
        Write-Output "Matching SetupConfig.ini version $Version found, all good"
        exit 0
    }
    else {
    Write-Log "Matching SetupConfig.ini version not found"
    Write-Log "Expecting version $CompliantVersion, found version $Version, non-compliant"
    Write-Output "Matching SetupConfig.ini version not found, non-compliant"
    exit 1
    }
}
else {
    Write-Log "SetupConfig.ini is not available, non-compliant"
    Write-Output "SetupConfig.ini is not available, non-compliant"
    exit 1
}  