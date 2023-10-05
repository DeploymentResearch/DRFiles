#Requires -RunAsAdministrator
[CmdletBinding()]
param (

)

$LogFile = "C:\Windows\Temp\PSDAutopilotCleanup.log"

# Delete any existing logfile if it exists
If (Test-Path $Logfile){Remove-Item $Logfile -Force -ErrorAction SilentlyContinue -Confirm:$false}

Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
   )

   $TimeGenerated = $(Get-Date -UFormat "%D %T")
   $Line = "$TimeGenerated $Message"
   Add-Content -Value $Line -Path $LogFile -Encoding Ascii

}

# Remove any unattend.xml files
Write-Log -Message "Starting to remove existing unattend.xml files"
If (Test-Path "C:\Windows\Panther\unattend.xml" ){Remove-Item "C:\Windows\Panther\unattend.xml" -Force } 
If (Test-Path "C:\Windows\System32\Sysprep\unattend.xml" ){Remove-Item "C:\Windows\System32\Sysprep\unattend.xml" -Force } 

