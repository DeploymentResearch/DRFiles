<#
.SYNOPSIS
    Sets OSDComputerName from the BIOS serial number during a task sequence.
.DESCRIPTION
    Reads the serial number, truncates it to twelve characters, prefixes it, and writes the
    result to OSDComputerName so it stays within the fifteen character limit.
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
      1.0.0 - 2025-03-19 - Initial release
#>

$ComputerNamePrefix = "VOA"
$SerialNumber = (Get-CimInstance -ClassName Win32_BIOS | Select-Object SerialNumber).SerialNumber
# Validate length
If ($SerialNumber.Length -gt 12){
    # Use the first 12 characters
    $SerialNumber = $SerialNumber.Substring(0,12)
}

$OSDComputerName = "VOA" + $SerialNumber
$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$TSEnv.Value("OSDComputerName") = $OSDComputerName
