<#
.SYNOPSIS
    Dumps all task sequence variables to a text file.
.DESCRIPTION
    Enumerates every variable in the task sequence environment and writes name and value pairs
    to a file under Windows\Temp.
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
      1.0.0 - 2022-01-02 - Initial release
#>

$VarFile = Join-Path $ENV:SystemDrive '\Windows\Temp\TSVariables.txt'
$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$Vars = $TSEnv.GetVariables()
$Output = foreach ($Var in $Vars)
{
    '{0} = {1}' -f $Var, $TSEnv.Value($Var)
}
$Output | Out-File -FilePath $VarFile
