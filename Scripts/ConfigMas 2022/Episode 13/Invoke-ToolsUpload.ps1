<#
.SYNOPSIS
    Demo script for copying a tools folder into Hyper-V virtual machines.
.DESCRIPTION
    Enables the Guest Service Interface and copies files into each virtual machine over the
    VMBus, without needing network connectivity to the guest.
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
      1.0.0 - 2022-12-14 - Initial release
#>

# Demo script for working with VMs in Hyper-V
#
# Author: Johan Arwidmark
# Twitter: @jarwidmark
# LinkedIn: https://www.linkedin.com/in/jarwidmark

# Set credentials (Use local admin account)
$Cred =Get-Credential
$TargetFolder = "C:\Setup\Sysinternals"

# Multiple VMS
$VMS = Get-VM -Name DA-Intune-* | Sort-Object Name

# Copy the tools
foreach ($VM in $VMs){

    $VMName = $VM.VMName
    # Check if VMS is running
    $VMStatus = (Get-VM -Name $VMName).State
    
    If ($VMStatus -eq "Running"){

        # Enable Guest Services (required for Copy-VMFile, and not enabled by default)
        Enable-VMIntegrationService -Name 'Guest Service Interface' –VMName $VMName 

        Invoke-Command -VMName $VMName { New-Item -Path $using:TargetFolder -ItemType Directory -Force } -Credential $Cred 
        #Invoke-Command -VMName $VMName { Remove-Item -Path "C:\Setup\SysinternalsSuite" -Force } -Credential $Cred 
   
        # Copy PsExec from Sysinternals
        Copy-VMFile -Name $VMName -SourcePath "D:\Setup\SysinternalsSuite\PsExec.exe" –DestinationPath $TargetFolder -FileSource Host -Force
    } 
}
