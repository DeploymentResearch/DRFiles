<#
.SYNOPSIS
    Sets OSDComputerName from the asset tag during a task sequence.
.DESCRIPTION
    Reads the AssetTag variable, prefixes it, and truncates the result to the fifteen character
    NetBIOS limit before writing OSDComputerName.
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
      1.0.0 - 2024-10-01 - Initial release
#>

# Set ComputerName based on AssetTag
$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$prefix = "ABC"
$AssetTag = $tsenv.Value("AssetTag")

If ($AssetTag){
    $tsenv.Value("OSDComputerName") = ($prefix + $AssetTag).Substring(0,15)
}

