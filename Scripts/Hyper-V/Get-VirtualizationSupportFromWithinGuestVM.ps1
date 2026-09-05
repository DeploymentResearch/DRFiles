<#
.SYNOPSIS
    Reports nested virtualization support from inside a guest virtual machine.
.DESCRIPTION
    Returns the manufacturer, model, hypervisor presence, and whether the virtual machine
    monitor extensions are exposed, which is what nested Hyper-V needs.
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
      1.0.0 - 2026-08-31 - Initial release
#>

$cs  = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

[PSCustomObject]@{
    Manufacturer      = $cs.Manufacturer
    Model             = $cs.Model
    HypervisorPresent = $cs.HypervisorPresent
    NestedVirtExposed = $cpu.VMMonitorModeExtensions
    SLAT              = $cpu.SecondLevelAddressTranslationExtensions
}
