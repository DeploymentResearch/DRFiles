<#
.SYNOPSIS
    Collects Autopilot hardware hashes from a set of test virtual machines.
.DESCRIPTION
    Connects to each virtual machine over PowerShell remoting, gathers the Autopilot hardware
    hash, copies the CSV files back to the host, and combines them into a single file.
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
      1.0.0 - 2022-05-03 - Initial release
#>

# Set credentials 
$Username = '.\Administrator'
$Password = 'P@ssw0rd'
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$pass

$VMs = @(
    "MMS2022-AP004"
    "MMS2022-AP005"
)

# Get the CSV Files (using sessions since CopyVM-File only supports copying from host to VM)
foreach($VM in $VMs){ 
    $session = New-PSSession -VMName $VM -Credential $cred
    Copy-Item -FromSession $session -Path "C:\Users\Administrator\Desktop\*.csv" -Destination "C:\Temp"

}

# Combine the CSV files for easy upload
$CSVFiles = Get-ChildItem -Path "C:\Temp" -Filter "*MMS*.CSV" 
$CSVFiles | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv C:\Temp\AutoPilot_AllMachines.csv -NoTypeInformation -Encoding ASCII

# Prepare for autopilot
foreach($VM in $VMs){ 
    $session = New-PSSession -VMName $VM -Credential $cred
    Invoke-Command -Session $session -ScriptBlock { 
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force 
        Remove-item -Path C:\Users\Administrator\Desktop\*autopilot*.csv -Force
        C:\Windows\Remove-APUnattend.ps1 
        #C:\Windows\system32\Sysprep\sysprep.exe /quiet /oobe /generalize /shutdown
    }
}
