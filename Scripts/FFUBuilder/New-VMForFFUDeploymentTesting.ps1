<#
.SYNOPSIS
    Script to create a VM for FFU Deployment testing

.DESCRIPTION
    Requirements: Populated C:\FFUDevelopment folder built by the FFU project - https://github.com/rbalsleyMSFT/FFU

    Credits (and thanks): Tim Welch - https://github.com/rbalsleyMSFT/FFU/discussions/185

.NOTES
    Author: Johan Arwidmark / deploymentresearch.com
    Twitter (X): @jarwidmark
    LinkedIn: https://www.linkedin.com/in/jarwidmark
    License: MIT
    Source:  https://github.com/DeploymentResearch/DRFiles

.DISCLAIMER
    This script is provided "as is" without warranty of any kind, express or implied.
    Use at your own risk — the author and DeploymentResearch assume no responsibility for any
    issues, damages, or data loss resulting from its use or modification.

    This script is shared in the spirit of community learning and improvement.
    You are welcome to adapt and redistribute it under the terms of the MIT License.

.VERSION
    1.0.0
    Released: 2025-10-26
    Change history:
      1.0.0 - 2026-10-26 - Initial release
#>

# Check for admin permissions
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script requires administrative privileges. Please run PowerShell as Administrator and try again."
    Break
}

# Test VM Configuration Parameters
# Note: Windows 11 really likes a few extra vCPUs, hence the value of 4
$VMName = "TEST01"
$VMPath = "C:\VMs"
$VHDPath = "C:\VMs\$VMName\$VMName.vhdx"
$VHDSize = 240GB
$VHDLogicalSectorSizeBytes = 512
$MemoryStartupBytes = 8GB
$ProcessorCount = 4
$SwitchName = "External"

# FFU Configuration Parameters
# Note: Purposely using folders outside of C:\FFUDevelopment to allow for new Builds and Test Deployments simultaneously 
# Copy the .FFU file you want to test a deployment for to the $FFUDir folder and the Deploy ISO to the $FFUDeployISO folder
$FFUDir = "C:\FFUTesting"
$FFUDeployISO = "C:\ISO\WinPE_FFU_Deploy_x64.iso"
$FFUdiskSize = 50GB

# Create VM Directory if it doesn't exist
New-Item -Path "$VMPath\$VMName" -ItemType Directory -Force

# Create new Virtual Machine
New-VM -Name $VMName `
    -Path $VMPath `
    -MemoryStartupBytes $MemoryStartupBytes `
    -Generation 2 `
    -SwitchName $SwitchName

# Create and attach new Virtual Hard Disk
New-VHD -Path $VHDPath -SizeBytes $VHDSize -Dynamic
Add-VMHardDiskDrive -VMName $VMName -Path $VHDPath

# Configure VM Settings
Set-VMProcessor -VMName $VMName -Count $ProcessorCount
Set-VMFirmware -VMName $VMName -EnableSecureBoot On

# Enable virtual TPM
$owner = Get-HgsGuardian UntrustedGuardian -ErrorAction SilentlyContinue
If ($owner){
    # All good
}
Else {
    # Create new UntrustedGuardian HgsGuardian
    $owner = New-HgsGuardian -Name "UntrustedGuardian" -GenerateCertificates
}
$kp = New-HgsKeyProtector -Owner $owner -AllowUntrustedRoot
Set-VMKeyProtector -VMName $VMName -KeyProtector $kp.RawData
Enable-VMTPM -VMName $VMName

# Add DVD Drive with the FFU Deployment ISO
Add-VMDvdDrive -VMName $VMName -Path $FFUDeployISO

# Add a fixed drive with the correct settings for the FFU
$FFUDiskPath = "$VMPath\$VMName\deploy.vhdx"
New-VHD -Path $FFUDiskPath -SizeBytes $FFUdiskSize -Dynamic -LogicalSectorSizeBytes $VHDLogicalSectorSizeBytes
Mount-VHD -Path $FFUDiskPath
$FFUdisk = Get-Disk | Where-Object {($_.Model -match "Virtual Disk*") -and ($_.PartitionStyle -Eq 'RAW') -and ($_.Size -eq $FFUdiskSize)}
If (-not $FFUdisk) {
    Write-Warning "No suitable disk found for FFU deployment. Ensure the disk is not in use and try again."
    Break
}
Initialize-Disk -Number $FFUdisk.Number
$FFUDrive = New-Partition -DiskNumber $FFUdisk.Number -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Deploy" -Confirm:$false

# Copy the most recent FFU file to the disk
$FFUFile = Get-ChildItem -Path $FFUDir -Filter *.ffu | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Copy-Item -Path $FFUFile -Destination "$($FFUDrive.DriveLetter):\" -Verbose

Dismount-VHD -Path $FFUDiskPath
Add-VMHardDiskDrive -VMName $VMName -Path $FFUDiskPath

# Set Windows ISO DVD Drive as First Boot Device
$DVDDrive = Get-VMDvdDrive -VMName $VMName | Select-Object -First 1
Set-VMFirmware -VMName $VMName -FirstBootDevice $DVDDrive

# Configure Memory Settings
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false

# Disable Automatic Checkpoints on Windows 11 Hyper-V Hosts
$OSName = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
if ($OSName -match 'Windows 11') {
    Set-VM -VMName  $VMName -AutomaticCheckpointsEnabled $false
}

# Enable Guest Services
Enable-VMIntegrationService -VMName $VMName -Name "Guest Service Interface"

# Create Checkpoint
Checkpoint-VM -Name $VMName -SnapshotName "Clean with Deploy FFU ISO"

# Start the VM
Start-VM -VMName $VMName

Write-Host "Virtual Machine $VMName has been created and started with automated installation configuration."

# Connect to the VM
VMConnect localhost $VMName

