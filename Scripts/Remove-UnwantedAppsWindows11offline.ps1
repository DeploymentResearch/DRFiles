<#
.SYNOPSIS
    Remove unwanted apps from Windows 11

.DESCRIPTION
    Remove unwanted apps from Windows 11 during the WinPE phase. Script intended for ConfigMgr OSD

.LINK
    https://deploymentresearch.com

.NOTES
    FileName: Remove-UnwantedAppsWindows11offline.ps1
    Solution: ConfigMgr OSD 
    Author: Johan Arwidmark
    Contact: @jarwidmark on X (Twitter) or https://www.linkedin.com/in/jarwidmark
    Created: 4/20/2024

    Version history:
    1.0.0 - (4/20/2024) - Script created
    1.0.1 - (4/21/2024) - Changed add/remove method to use dism.exe 

.EXAMPLE
#>


$Apps = @(
    "Clipchamp.Clipchamp_2.2.8.0_neutral_~_yxz26nhyzhsrt",
    "Microsoft.549981C3F5F10_3.2204.14815.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.BingNews_4.2.27001.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.BingWeather_4.53.33420.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.GamingApp_2021.427.138.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.GetHelp_10.2201.421.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.MicrosoftOfficeHub_18.2204.1141.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.MicrosoftSolitaireCollection_4.12.3171.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.People_2020.901.1724.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.PowerAutomateDesktop_10.0.3735.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.Todos_2.54.42772.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.WindowsAlarms_2022.2202.24.0_neutral_~_8wekyb3d8bbwe",
    "microsoft.windowscommunicationsapps_16005.14326.20544.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.WindowsFeedbackHub_2022.106.2230.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.WindowsMaps_2022.2202.6.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.Xbox.TCUI_1.23.28004.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.XboxGameOverlay_1.47.2385.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.XboxGamingOverlay_2.622.3232.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.XboxIdentityProvider_12.50.6001.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.XboxSpeechToTextOverlay_1.17.29001.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.YourPhone_1.22022.147.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.ZuneMusic_11.2202.46.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.ZuneVideo_2019.22020.10021.0_neutral_~_8wekyb3d8bbwe",
    "MicrosoftCorporationII.QuickAssist_2022.414.1758.0_neutral_~_8wekyb3d8bbwe"
)

# Figure out where to log
try {
    $TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
    $LogPath = $TSEnv.Value("_SMSTSLogPath")
    $LogFile = "$LogPath\Remove-UnwantedAppsWindows11offline.log"
    Write-Output "LogFile is: $LogFile"
}
catch {
    Write-Warning "No Task Sequence environment found, aborting script..."
    Break
}

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

If ( $env:SYSTEMDRIVE -eq "X:" ) {
    Write-Log "Running offline in WinPE"
    Write-Log "Using DISM.EXE instead of Remove-AppxProvisionedPackage for better WinPE support"

    $OSDTargetSystemDrive = $TSEnv.Value("OSDTargetSystemDrive")
    $TargetImage = "$OSDTargetSystemDrive\"
    
    write-Log "Remove Provisioned Windows Apps in the offline image located in $TargetImage"

    # Request temporary files for RedirectStandardOutput and RedirectStandardError
    $RedirectStandardOutput = [System.IO.Path]::GetTempFileName()
    $RedirectStandardError = [System.IO.Path]::GetTempFileName()

    foreach ($App in $Apps){
        # Start dism.exe
        $Utility = "dism.exe"
        $Arguments = "/image:$TargetImage /Remove-ProvisionedAppxPackage /PackageName:$App" 
        Write-Log -Message "About to run $Utility $Arguments"
        $Result = Start-Process $Utility $Arguments -NoNewWindow -Wait -PassThru -RedirectStandardOutput $RedirectStandardOutput -RedirectStandardError $RedirectStandardError

        # Log the Standard Output, skip any the empty lines
        If ((Get-Item $RedirectStandardOutput).length -gt 0){
            Write-Log -Message "----------- Begin Standard Output -----------"
            $CleanedRedirectStandardOutput = Get-Content $RedirectStandardOutput | Where-Object {$_.trim() -ne "" } 
            foreach ($row in $CleanedRedirectStandardOutput){
                 Write-Log -Message $row
            }
            Write-Log -Message "----------- End Standard Output -----------"
        }

        # Log the  Standard Error, skip any empty lines
        If ((Get-Item $RedirectStandardError).length -gt 0){
            Write-Log -Message "----------- Begin Standard Error -----------"
            $CleanedRedirectStandardError = Get-Content $RedirectStandardError | Where-Object {$_.trim() -ne "" } 
            foreach ($row in $CleanedRedirectStandardError){
                 Write-Log -Message $row
            }
            Write-Log -Message "----------- End Standard Error -----------"
        }
    
        # Command error handling
        if ($Result.ExitCode -eq 0) {
	        Write-Log -Message  "Command has been successfully processed"
        } elseif ($Result.ExitCode -gt 0) {
	        return Write-Log "Exit code is $($Result.ExitCode)"
        } else {
	        return Write-Log "An unknown error occurred."
        }
    }
}

