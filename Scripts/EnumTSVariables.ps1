$VarFile = Join-Path $ENV:SystemDrive '\Windows\Temp\TSVariables.txt'
$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$Vars = $TSEnv.GetVariables()
$Output = foreach ($Var in $Vars)
{
    '{0} = {1}' -f $Var, $TSEnv.Value($Var)
}
$Output | Out-File -FilePath $VarFile