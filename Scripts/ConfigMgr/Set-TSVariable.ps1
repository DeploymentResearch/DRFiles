<#
.SYNOPSIS
    Reference snippet for setting task sequence variables from PowerShell.
.DESCRIPTION
    Shows how to create the task sequence environment COM object and assign both built-in and
    custom variables.
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
      1.0.0 - 2023-08-04 - Initial release
#>

$ComputerName = "TEST01"
$MyCustomVariable = "WELL"

$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment

$TSEnv.Value("OSDComputerName") = $ComputerName
$TSEnv.Value("MyCustomVariable") = $MyCustomVariable

