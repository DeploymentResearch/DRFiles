$cs  = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

[PSCustomObject]@{
    Manufacturer      = $cs.Manufacturer
    Model             = $cs.Model
    HypervisorPresent = $cs.HypervisorPresent
    NestedVirtExposed = $cpu.VMMonitorModeExtensions
    SLAT              = $cpu.SecondLevelAddressTranslationExtensions
}