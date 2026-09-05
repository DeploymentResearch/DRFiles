<#
.SYNOPSIS
    Copies files into a Hyper-V virtual machine over the VMBus.
.DESCRIPTION
    Enables the Guest Service Interface, which is not on by default, and then copies the listed
    files into the guest without needing network connectivity.
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
      1.0.0 - 2024-01-05 - Initial release
#>

# Script to files to a VM via the Hyper-V VMBus 

$VMName = "ROGUE-033"

# Enable Guest Services (required for Copy-VMFile, and not enabled by default)
Enable-VMIntegrationService -Name 'Guest Service Interface' –VMName $VMName 
    
# Copy The files 
$FilesToCopy = @()
$FilesToCopy += [pscustomobject]@{ Source = "E:\Demo\_LabEnvironment\Scripts\EnableInternetAccessOnVMs.ps1"; Destination = "C:\Setup\Scripts\EnableInternetAccessOnVMs.ps1"}
$FilesToCopy += [pscustomobject]@{ Source = "E:\Demo\_LabEnvironment\Scripts\New-LabVMsForHyperV.ps1"; Destination = "C:\Setup\Scripts\New-LabVMsForHyperV.ps1.ps1"}
$FilesToCopy += [pscustomobject]@{ Source = "D:\ISO\HydrationCMWS2019.iso"; Destination = "C:\ISO\HydrationCMWS2019.iso"}

foreach ($File in $FilesToCopy){
    Copy-VMFile -Name $VMName -SourcePath $File.Source  –DestinationPath $File.Destination -FileSource Host –CreateFullPath -Force
}
