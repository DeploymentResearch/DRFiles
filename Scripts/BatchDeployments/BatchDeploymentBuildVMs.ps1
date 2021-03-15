#$VMList = CreateMultipleVMs -VMNamePrefix "TEST2" -HyperVHostID "C1" -NumberOfVMs 3 -VMType "GEN2-PXE"

#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName='None')]
param (
    [Parameter(Mandatory = $true)]
    [string]$VMNamePrefix,
    [Parameter(Mandatory = $true)]
    [string]$HyperVHostID,
    [Parameter(Mandatory = $true)]
    [int]$NumberOfVMs,
    [Parameter(Mandatory = $true)]
    [string]$VMType
)


$VMLocation = "C:\VMs"
$VMNetwork = "Chicago1"
$ExportFile = "C:\Setup\Computers.csv" 
$VMMemory = 4096MB
$VMDiskSize = 512GB

# Check for the Hyper-V Switch
$VMSwitchNameCheck = Get-VMSwitch | Where-Object -Property Name -EQ "Chicago1"
if ($VMSwitchNameCheck.Name -eq "Chicago1"){
    Write-Host "Hyper-V Virtual Machine switch exist, OK, continuing..." -ForegroundColor Green
    Write-Host ""
}
Else{
    Write-Host "Hyper-V switch does not exist. creating it..."
    # Create External Hyper-V Switch
    Write-host "$Env:Computername Creating External virtual switch..."
    New-VMSwitch -Name Chicago1 -NetAdapterName "Ethernet" -AllowManagementOs $true
    Start-Sleep -Seconds 20
    Write-host "$Env:Computername virtual switch created" -ForegroundColor Green
    Write-Host ""
}


# Create the VMs
$i = 1
[System.Collections.ArrayList]$VMList = @()
do {
 
    Write-Host "Creating VM $i of $NumberOfVMs"
 
    # Create the virtual machines
    $VMName = "$VMNamePrefix-" + ($i | %{"{0:D3}" -f $_})
    $MacAddress = "00:15:5D:" + $HyperVHostID + ":" + ($i | %{"{0:D2}" -f $_}) + ":" + ($i | %{"{0:D2}" -f $_})
    "$VMNamePrefix-" + ($i | %{"{0:D3}" -f $_}) + ",," + $MacAddress # | Out-File -FilePath $ExportFile -Append

    Write-host "Creating $VMName VM"
    
    If ($VMType -eq "GEN2-PXE"){
        # Create Gen 2 VM with Secureboot Disabled and Network Boot
        New-VM -Name $VMName -Generation 2 -BootDevice NetworkAdapter -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD -Version 5.0
    }

    If ($VMType -eq "GEN1-PXE"){   
        # Create Gen 1 VM with Network Boot
        New-VM -Name $VMName -Generation 1 -BootDevice LegacyNetworkAdapter -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD
    }

    If ($VMType -eq "GEN2-CD"){
        # Create Gen 2 VM with Secureboot Disabled and boot from CD
        New-VM -Name $VMName -Generation 2 -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD
    }
    
    New-VHD -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize
    Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx"
    $CD = Set-VMDvdDrive -VMName $VMName -Path $VMISO
    Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false
  
    Set-VMProcessor -VMName $VMName -Count 2
    Set-VMNetworkAdapter -VMName $VMName -StaticMacAddress $MacAddress
    $Disk = Get-VMHardDiskDrive -VMName $VMName
    $Network = Get-VMNetworkAdapter -VMName $VMName

    If ($VMType -eq "GEN2-PXE"){
        # Create Gen 2 VM with Secureboot Disabled and Network Boot
        Set-VMFirmware -VMName $VMName -EnableSecureBoot Off -BootOrder $Disk,$Network
    }

    If ($VMType -eq "GEN2-CD"){
        # When booting from ISO without prompt, set boot order to disk first
        Set-VMFirmware -VMName $VMName -FirstBootDevice $Disk
    }

    # Set Checkpoint Type to Standard
    Set-VM -Name $VMName -CheckpointType Standard

    # For Windows 10 Hyper-V hosts, disable automatic checkpoints
    $OSCaption = (Get-WmiObject win32_operatingsystem).caption
    If ($OSCaption -eq "Microsoft Windows 10 Enterprise"){
        Set-VM -Name $VMName -AutomaticCheckpointsEnabled $false
    }

    $obj = [PSCustomObject]@{

    # Add values to arraylist
    "Name" = "$VMNamePrefix-" + ($i | %{"{0:D3}" -f $_})
    "SMBIOS GUID" = $Null 
    "Mac Address" = $MacAddress
    "VMName" = $VMName

    }

    # Add all the values
    $VMList.Add($obj)|Out-Null

    $i++
}
while ($i -le $NumberOfVMs)

# Export the result to CSV file to ConfigMgr compatible import file (using just the first three fields)
$VMList | Select "Name", "SMBIOS GUID","Mac Address" | ConvertTo-Csv -NoTypeInformation | Set-Content -Path $ExportFile