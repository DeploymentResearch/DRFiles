$ComputerName = "TEST01"
$MyCustomVariable = "WELL"

$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment

$TSEnv.Value("OSDComputerName") = $ComputerName
$TSEnv.Value("MyCustomVariable") = $MyCustomVariable

