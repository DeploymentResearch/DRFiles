# -------------------------------------------------------------------------------------------
# File: Remove-AutologonSettings.ps1
# Credits: Johan Arwidmark (@jarwidmark)
#
# Description:
# A sample script that removes any Autologon Info
#
# Provided as-is with no support. See https://deploymentresearch.com for related information.
# -------------------------------------------------------------------------------------------

$Logfile = "C:\Windows\Temp\Remove-AutologonSettings.log"

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

Write-Log "Starting the Remove-AutologonSettings.ps1 script"

$RegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Write-Log "Clearing values in $RegistryPath"
Set-ItemProperty $RegistryPath 'AutoAdminLogon' -Value "0" -Type String 
Set-ItemProperty $RegistryPath 'AutoLogonCount' -Value "0" -Type String 
Set-ItemProperty $RegistryPath 'DefaultUsername' -Value "" -type String 
Set-ItemProperty $RegistryPath 'DefaultDomainName' -Value "VIAMONSTRA" -type String
Set-ItemProperty $RegistryPath 'DefaultPassword' -Value "" -type String
Set-ItemProperty $RegistryPath 'ForceAutoLogon' -Value "0" -type String
Set-ItemProperty $RegistryPath 'DisableCAD' -Value "0" -type Dword

Write-Log "Script completed"