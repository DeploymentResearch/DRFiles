<#
.SYNOPSIS
    Minimal WinPE test for Modern Driver Management.
.DESCRIPTION
    Sets the working directory to the Invoke-CMApplyDriverPackage package folder and runs the
    script, so driver package matching can be tested from a WinPE command prompt.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark / deploymentresearch.com
    Credits: Modern Driver Management by Nickolaj Andersen and Maurice Daly, MSEndpointMgr
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2024-03-19 - Initial release
#>

# Set the location (working directory) to where your Invoke-CMApplyDriverPackage.ps1 script is, then run this script
# For example: Set-Location "C:\_SMSTaskSequence\Packages\PS1000AF"

$SMSProvider = "cm01.corp.viamonstra.com"	
$Cred = Get-Credential 
$Password = $Cred.GetNetworkCredential().Password
$UserName = "$($Cred.GetNetworkCredential().Domain)\$($Cred.GetNetworkCredential().UserName)"

# Check Dell Optiplex 7050
.\Invoke-CMApplyDriverPackage.ps1 -DebugMode -Endpoint $SMSProvider -UserName $UserName -Password $Password -TargetOSVersion 21H2 -TargetOSName 'Windows 10' -Manufacturer Dell -ComputerModel "Optiplex 7050" -SystemSKU "07A1" -Verbose
