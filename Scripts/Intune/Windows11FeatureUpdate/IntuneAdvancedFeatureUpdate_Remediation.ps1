# The script creates the SetupConfig.ini, PostOOBE.cmd, and PostOOBE.ps1 scripts used by Feature Updates via Intune
# Creds to Adam Gross for Export-IniFile function...

$FeatureUpdatePath = "C:\ProgramData\FeatureUpdate" # Main customization folder, drivers, scripts and logs goes here
$UpdatePath = "C:\Users\Default\AppData\Local\Microsoft\Windows\WSUS" # Path that Feature Updates via Intune uses (if created)
$SetupConfigPath = "$UpdatePath\SetupConfig.ini"
$PostOOBECMDScript = "PostOOBE.cmd"
$PostOOBEPSScript = "PostOOBE.ps1"
$LocalLoggingModule = "IntuneLogging.psm1"
$Logfile = "$FeatureUpdatePath\Logs\IntuneAdvancedFeatureUpdate_Remediation.log"

# Create log folder
New-Item -Path "$FeatureUpdatePath\Logs" -ItemType Directory -Force

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

Function Export-IniFile {
    [CmdletBinding()]
    Param (
        [parameter()]
        [System.Collections.Specialized.OrderedDictionary]$Content,

        [parameter()]
        [string]$NewFile
    )

    Try {
        #This array will be the final ini output
        $NewIniContent = New-Object System.Collections.Generic.List[System.String]

        $KeyCount = 0
        #Convert the dictionary into ini file format
        ForEach ($sectionHash in $Content.Keys) {
            $KeyCount++
            #Create section headers
            $NewIniContent.Add("[$($sectionHash)]")

            #Create all section content. Items with a Name and Value in the dictionary will be formatted as Name=Value.
            #Any items with no value will be formatted as Name only.
            ForEach ($key in $Content[$sectionHash].keys) {
                If ($Key -like "Comment*") {
                    #Comment
                    $NewIniContent.Add($Content[$sectionHash][$key])
                }
                ElseIf ($NewIniDictionary[$sectionHash][$key]) {
                    #Name=Value format
                    $NewIniContent.Add(($key, $Content[$sectionHash][$key]) -join "=")
                }
                Else {
                    #Name only format
                    $NewIniContent.Add($key)
                }
            }
            #Add a blank line after each section if there is more than one, but don't add one after the last section
            If ($KeyCount -lt $Content.Keys.Count) {
                $NewIniContent.Add("")
            }
        }
        #Write $Content to the SetupConfig.ini file
        New-Item -Path $NewFile -ItemType File -Force | Out-Null
        $NewIniContent -join "`r`n" | Out-File -FilePath $NewFile -Force -NoNewline | Out-Null
        $ExportedFile = Get-Item -Path $NewFile -ErrorAction SilentlyContinue
        Return $ExportedFile
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

# Create remaining folders
Write-Log "Creating Scripts Folder: $FeatureUpdatePath\scripts"
New-Item -Path "$FeatureUpdatePath\Scripts" -ItemType Directory -Force

Write-Log "Creating Drivers Folder: $FeatureUpdatePath\Driverrs"
New-Item -Path "$FeatureUpdatePath\Drivers" -ItemType Directory -Force

# Generate a SetupConfig.ini file
[System.Collections.Specialized.OrderedDictionary]$AddSettings = [ordered]@{
    "SetupConfig" = [ordered]@{
        "Quiet"                 =   ""
        "Auto"                  =   "Upgrade"
        "EULA"                  =   "Accept"
        "BitLocker"             =   "AlwaysSuspend"; #{AlwaysSuspend | TryKeepActive | ForceKeepActive}
        "Compat"                =   "IgnoreWarning"; #{IgnoreWarning | ScanOnly}
        "Priority"              =   "Normal" #{High | Normal | Low}
        "DynamicUpdate"         =   "Enable" #{Enable | Disable | NoDrivers | NoLCU | NoDriversNoLCU}
        "ShowOOBE"              =   "None" #{Full | None}
        "Telemetry"             =   "Enable" #{Enable | Disable}
        "DiagnosticPrompt"      =   "Enable" #{Enable | Disable}
        "PKey"                  =   "NPPR9-FWDCX-D2C8J-H872K-2YT43" #<product key>
        "InstallDrivers"        =   "$FeatureUpdatePath\Drivers"
        "PostOOBE"              =   "$FeatureUpdatePath\Scripts\PostOOBE.cmd"
        "CopyLogs"              =   "$FeatureUpdatePath\Logs"
        #"ReflectDrivers"       =   ""
        #"SkipFinalize"         =   "" #2004 and up
        #"Finalize"             =   "" #2004 and up
        #"NoReboot"             =   ""
        #"MigrateDrivers"       =   "All" #{All | None}
        #"PostRollBack"         =   "Path to script"
        #"PostRollBackContext"  =   ""Path to script"
        ";Version"              =   "1.2" # custom entry, not used by Windows 11
    }
}

# Create SetupConfig.ini file
Write-Log "Creating SetupConfig.ini in: $SetupConfigPath"
$NewIniDictionary = $AddSettings
$ExportedFile = Export-IniFile -Content $NewIniDictionary -NewFile $SetupConfigPath
$PostOOBECMDContent = $null
# Create PostOOBE.cmd script
Write-Log "Creating PostOOBE.cmd in $FeatureUpdatePath\Scripts"
$PostOOBECMDContent = @(
"@echo off
set version=1.0
set Component=PostOOBE
set logfile=$FeatureUpdatePath\Logs\PostOOBE-CMD.log
set psfile=$FeatureUpdatePath\Scripts\PostOOBE.ps1
    
echo %date% %time% START %Component% %version% > %logfile%
    
if exist %psfile% (
    echo %date% %time% %psfile% found, launching... >> %logfile%
    powershell.exe -ExecutionPolicy Bypass -File %psfile% -WindowStyle Hidden
    echo %date% %time% powershell return code: %errorlevel% >> %logfile%
    
) else (
	echo %date% %time% ERROR %psfile% not found! >> %logfile%
)
    
echo %date% %time% END >> %logfile%"
) 

$PostOOBECMDContent | Out-File "$FeatureUpdatePath\Scripts\$PostOOBECMDScript" -Encoding ASCII -Force

# Create local logging module using a function export from AST
$code = @'
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
'@

$ast=[System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$null, [ref]$null)
$result=$ast.FindAll({$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]},1) 
$Export = $result | Where-Object { $_.Name -eq "Write-Log" }

# Export function to a local script
Set-Content -path "$FeatureUpdatePath\Scripts\IntuneLogging.psm1" -Value $Export.ToString()

# Update the local script with an Export-ModuleMember command
"Export-ModuleMember -Function Write-Log" | Out-File -Append -Encoding UTF8 -FilePath "$FeatureUpdatePath\Scripts\IntuneLogging.psm1"


# Create PostOOBE.ps1 script
Write-Log "Creating PostOOBE.ps1 in $PostOOBEPath"
$PostOOBEContent = @(
"# PostOOBE Script for cleanup after upgrade

# Import local logging module
Import-Module $FeatureUpdatePath\Scripts\$LocalLoggingModule

# Set logfile
`$Logfile = `"$FeatureUpdatePath\Logs\PostOOBE-PS.log`"

Write-Log `"About to remove drivers folder: $FeatureUpdatePath\Drivers`"
If (Test-Path $FeatureUpdatePath\Drivers) {Remove-Item $FeatureUpdatePath\Drivers -Recurse -Force }"
)

Write-Log "Creating PostOOBE.ps1 in $PostOOBEPath"
$PostOOBEContent | Out-File "$FeatureUpdatePath\Scripts\$PostOOBEPSScript" -Encoding ASCII -Force

