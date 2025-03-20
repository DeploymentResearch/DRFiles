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