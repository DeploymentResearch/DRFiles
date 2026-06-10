# Script to create a VM for Autopilot testing
# Requirements: VHDX file of sysprepped Windows 10/11 setup (can be default from Microsoft)
#
# TIP: To convert an existing WIM image to VHDX file, use Convert-WindowsImage.ps1 from https://github.com/nerdile/convert-windowsimage
# For example syntax, see https://github.com/DeploymentResearch/DRFiles/blob/master/Scripts/AutoPilot/Convert-WindowsImage-Syntax.ps1
#
# Author: Johan Arwidmark
# Twitter: @jarwidmark
# LinkedIn: https://www.linkedin.com/in/jarwidmark

# ============================================================
#  EDIT THESE VALUES FOR YOUR ENVIRONMENT
# ============================================================

# Name of the VM. This will also be set as the Windows computer name.
# WARNING: If a VM with this name already exists, it will be deleted (you will be prompted first).
$VMName = "APTEST212"

# Folder where the VM and its virtual hard disk will be created
$VMLocation = "E:\VMs"

# Name of the Hyper-V virtual switch to connect the VM to
$VMNetwork = "NoInternet"

# Memory and CPU for the VM
$VMMemory = 4096MB
$VMProcessorCount = 2

# Path to your sysprepped reference VHDX file
$RefVHD = "C:\VHD\W11-X64-25H2-Enterprise-2025-09.vhdx"

# Paths to the supporting files copied into the VM
$Unattend = "F:\GitHub\DRFiles\Scripts\AutoPilot\Unattend.xml"
$APScript = "C:\Setup\Scripts\Get-WindowsAutoPilotInfo.ps1"
$RemoveUnattendScript = "C:\Setup\Scripts\Remove-APUnattend.ps1"

# ============================================================
#  No changes needed below this line
# ============================================================

# --- Verify that specified files and the virtual switch exist ---
# Checking everything up front means we fail fast, before the slow VHDX copy.
If (!(Test-Path $APScript)) { Write-Error "Autopilot script not found at $APScript, aborting..."; exit 1 }
If (!(Test-Path $Unattend)) { Write-Error "Unattend.xml file not found at $Unattend, aborting..."; exit 1 }
If (!(Test-Path $RefVHD)) { Write-Error "Parent VHDX file not found at $RefVHD, aborting..."; exit 1 }
If (!(Test-Path $RemoveUnattendScript)) { Write-Error "Remove-APUnattend script not found at $RemoveUnattendScript, aborting..."; exit 1 }
If (!(Get-VMSwitch -Name $VMNetwork -ErrorAction Ignore)) {
    Write-Error "Hyper-V virtual switch '$VMNetwork' not found, aborting..."
    Write-Host "Available switches:" -ForegroundColor Yellow
    Get-VMSwitch | Select-Object Name, SwitchType | Format-Table -AutoSize
    exit 1
}

# --- Verify there is enough free disk space for the VHDX copy ---
$RefVHDSizeGB = [math]::Round((Get-Item $RefVHD).Length / 1GB, 1)
$TargetDrive = (Get-Item (Split-Path $VMLocation -Qualifier)).PSDrive
$FreeSpaceGB = [math]::Round($TargetDrive.Free / 1GB, 1)
If ($FreeSpaceGB -lt ($RefVHDSizeGB + 5)) {
    Write-Error "Not enough free space on $($TargetDrive.Name): drive. Need ~$($RefVHDSizeGB + 5) GB, found $FreeSpaceGB GB. Aborting..."
    exit 1
}

# --- Cleanup existing VM (if it exists) ---
$VM = Get-VM $VMName -ErrorAction Ignore
If ($VM) {
    Write-Warning "A VM named '$VMName' already exists. It will be STOPPED and DELETED, including its files."
    Read-Host "Press Enter to continue, or Ctrl+C to abort"

    # Ask the VM where its files actually live, BEFORE removing it.
    # (The VM may have been created with a different location than $VMLocation.)
    $OldVHDPaths = $VM.HardDrives.Path
    $OldVMFolder = $VM.Path

    Stop-VM -VMName $VMName -Force -ErrorAction SilentlyContinue
    $VM | Remove-VM -Force

    # Remove-VM only deletes the VM configuration, not the disks, so clean those up too
    foreach ($OldVHD in $OldVHDPaths) {
        If (Test-Path $OldVHD) { Remove-Item -Path $OldVHD -Force }
    }
    If (Test-Path "$OldVMFolder\$VMName") { Remove-Item -Recurse "$OldVMFolder\$VMName" -Force }
}
If (Test-Path "$VMLocation\$VMName") { Remove-Item -Recurse "$VMLocation\$VMName" -Force }

# --- Create a new VHDX file named after the VM ---
$TargetVHDName = "$VMName.vhdx"
$TargetVHDPath = "$VMLocation\$VMName\Virtual Hard Disks"
New-Item -Path $TargetVHDPath -ItemType Directory | Out-Null

Write-Host "Copying VHDX ($RefVHDSizeGB GB), this may take a while..." -ForegroundColor Cyan
Copy-Item -Path $RefVHD -Destination "$TargetVHDPath\$TargetVHDName"

# --- Mount the new VHDX and inject the Autopilot files ---
# The try/finally block makes sure the VHDX is always dismounted,
# even if something goes wrong halfway through.
try {
    Mount-DiskImage -ImagePath "$TargetVHDPath\$TargetVHDName" | Out-Null
    $VHDXDisk = Get-DiskImage -ImagePath "$TargetVHDPath\$TargetVHDName" | Get-Disk
    $VHDXDrive = Get-Partition -DiskNumber $VHDXDisk.Number |
        Where-Object { $_.Type -eq 'Basic' } |
        Sort-Object Size -Descending |
        Select-Object -First 1

    If ([string]::IsNullOrEmpty([string]$VHDXDrive.DriveLetter)) {
        throw "No drive letter assigned to the VHDX Windows partition, aborting..."
    }
    $VHDXVolume = [string]$VHDXDrive.DriveLetter + ":"

    # Copy unattend.xml and the Autopilot scripts into the Windows image
    Copy-Item -Path $Unattend -Destination "$VHDXVolume\Windows\System32\Sysprep\Unattend.xml"
    Copy-Item -Path $APScript -Destination "$VHDXVolume\Windows"
    Copy-Item -Path $RemoveUnattendScript -Destination "$VHDXVolume\Windows"

    # Remove Convert-WindowsImageInfo.txt file (leftover from image creation, if present)
    If (Test-Path "$VHDXVolume\Convert-WindowsImageInfo.txt") {
        Remove-Item -Path "$VHDXVolume\Convert-WindowsImageInfo.txt" -Force
    }

    # Update ComputerName in unattend.xml so Windows gets the same name as the VM
    # Note: $xml.Save() requires a full (absolute) path - do not change this to a relative path.
    $UnattendFileToModify = "$VHDXVolume\Windows\System32\Sysprep\Unattend.xml"
    [xml]$xml = Get-Content $UnattendFileToModify
    $component = $xml.unattend.settings.component | Where-Object { $_.ComputerName }
    If (!$component) {
        throw "No ComputerName element found in Unattend.xml - check your unattend template."
    }
    $component.ComputerName = $VMName
    $xml.Save($UnattendFileToModify)
}
finally {
    Dismount-DiskImage -ImagePath "$TargetVHDPath\$TargetVHDName" -ErrorAction SilentlyContinue | Out-Null
}

# --- Create the VM ---
Write-Host "Creating VM '$VMName'..." -ForegroundColor Cyan
New-VM -Name $VMName -Generation 2 -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -VHDPath "$TargetVHDPath\$TargetVHDName" | Out-Null
Set-VMProcessor -VMName $VMName -Count $VMProcessorCount

# --- Enable a virtual TPM ---
# Windows 11 requires TPM 2.0, and having it enabled before first boot means the
# Autopilot hardware hash matches the real state of the device.
# Note: A vTPM is enough for user-driven Autopilot testing, but Hyper-V VMs
# cannot pass TPM attestation, so self-deploying mode will not work in a VM.
Write-Host "Enabling virtual TPM..." -ForegroundColor Cyan
$Owner = Get-HgsGuardian UntrustedGuardian -ErrorAction Ignore
If (!$Owner) { $Owner = New-HgsGuardian -Name UntrustedGuardian -GenerateCertificates }
$KeyProtector = New-HgsKeyProtector -Owner $Owner -AllowUntrustedRoot
Set-VMKeyProtector -VMName $VMName -KeyProtector $KeyProtector.RawData
Enable-VMTPM -VMName $VMName

# --- Disable checkpoints to keep the lab tidy ---
# (Change to 'Standard' if you prefer to snapshot the VM before first boot
#  so you can re-run Autopilot scenarios without recopying the VHDX.)
Set-VM -VMName $VMName -CheckpointType Disabled

# --- Start the virtual machine ---
Start-VM -VMName $VMName
Write-Host ""
Write-Host "Done. VM '$VMName' has been created and is starting on host '$env:COMPUTERNAME'..." -ForegroundColor Green
Write-Host "Connect to it with: vmconnect.exe $([System.Net.Dns]::GetHostEntry('').HostName) `"$VMName`"" -ForegroundColor Green
