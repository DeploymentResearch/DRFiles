# Script to add the local computer to the specified group
# This script supports multiple domains
# Example: AddDeviceToGroup.ps1 -GroupName "NameOfGroup"

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$GroupName
)

$LogFileName = "$($myInvocation.MyCommand)" -replace ".ps1",".log"
try {
	$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction SilentlyContinue
	$LogFilePath = Join-Path -Path $TSEnv.Value("_SMSTSLogPath") -ChildPath $LogFileName
} 
catch { 
	$LogDir = 'C:\Windows\Temp'
	$LogFilePath = Join-Path -Path $LogDir -ChildPath $LogFileName
}

# Delete log file if it exist
If (Test-Path $LogFilePath){ Remove-Item $LogFilePath -Force }

# Simple log function (replace with CMTrace formatted logging if needed)
Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
   )

   $TimeGenerated = $(Get-Date -UFormat "%D %T")
   $Line = "$TimeGenerated : $Message"
   Add-Content -Value $Line -Path $LogFilePath -Encoding Ascii

}

Write-Log "Starting the $($myInvocation.MyCommand) script"
Write-Log "About to add computer: $($env:ComputerName) to group: $GroupName"

try {

    $SysInfo = New-Object -ComObject "ADSystemInfo"
    $ComputerDN = $SysInfo.GetType().InvokeMember("ComputerName", "GetProperty", $Null, $SysInfo, $Null)
    $ComputerDNLDAP = "LDAP://" + $ComputerDN
    Write-Log "Computer LDAP path to add is: $ComputerDNLDAP"

    # Search for the group in AD
    $GroupName = $GroupName.Trim('"') 
    $GroupDn = ([ADSISEARCHER]"sAMAccountName=$($GroupName)").FindOne().Path

    if ($GroupDn){
        $Group = [ADSI]"$GroupDn"
        Write-Log "Group LDAP path is: $($Group.Path)"
    }
    Else{
        Write-Log "Group not found, aborting..."
        Break
    }

    Write-Log "Checking if computer is already a member of the group"
    if ($Group.IsMember($ComputerDNLDAP)) {
        Write-Log "Computer: $($env:ComputerName) is a member of the $GroupName group already. Do nothing"
    }
    Else{
        Write-Log "Computer: $($env:ComputerName) is currently Not a member of the $GroupName group, adding the Computer"
        $Group.Add($ComputerDNLDAP)
    }
}
catch {
    $_.Exception.Message ; Exit 1
}