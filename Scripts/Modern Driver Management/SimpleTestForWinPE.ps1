# Set the location (working directory) to where your Invoke-CMApplyDriverPackage.ps1 script is, then run this script
# For example: Set-Location "C:\_SMSTaskSequence\Packages\PS1000AF"

$SMSProvider = "cm01.corp.viamonstra.com"	
$Cred = Get-Credential 
$Password = $Cred.GetNetworkCredential().Password
$UserName = "$($Cred.GetNetworkCredential().Domain)\$($Cred.GetNetworkCredential().UserName)"

# Check Dell Optiplex 7050
.\Invoke-CMApplyDriverPackage.ps1 -DebugMode -Endpoint $SMSProvider -UserName $UserName -Password $Password -TargetOSVersion 21H2 -TargetOSName 'Windows 10' -Manufacturer Dell -ComputerModel "Optiplex 7050" -SystemSKU "07A1" -Verbose
