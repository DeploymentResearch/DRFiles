<#
.SYNOPSIS
    Demo script for reading Delivery Optimization settings from multiple virtual machines.
.DESCRIPTION
    Connects to each virtual machine over PowerShell remoting and reads the Delivery
    Optimization policy values from the registry.
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
$Cred = Get-Credential

# Multiple VMS
$VMS = Get-VM -Name DA-Intune* | Sort-Object Name

# Get the DO Settings
foreach ($VM in $VMs){

    $VMName = $VM.VMName
    # Check if VMS is running
    $VMStatus = (Get-VM -Name $VMName).State
    
    If ($VMStatus -eq "Running"){

        Write-Host "Working on $VMName" -ForegroundColor Green
        Invoke-Command -VMName $VMName { (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization").DOGroupId } -Credential $Cred 
        Invoke-Command -VMName $VMName { (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization").DODownloadMode } -Credential $Cred 
        Invoke-Command -VMName $VMName { (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization").DoCacheHost } -Credential $Cred 
        Write-Host ""
    } 
}
