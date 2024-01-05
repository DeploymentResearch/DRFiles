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
