$VMLocation = "E:\VMs"
$VMNetwork = "Liverpool"
$NumberOfVMs = '1'
$VMType = "GEN2-CD" # Three options: GEN2-PXE, GEN2-CD, or GEN1-PXE
$SiteID = 'C3'
$VMNamePrefix = "2PS-Intune-"
#$VMNameSuffix = " (Chicago1, WAN 155 mbit)" # Optional
$SiteServer = "CM01"
$VMISO = "C:\ISO\MDT_Boot_Images_MDT01\MDT Production x64 No Prompt.iso"
$VMMemory = 4096MB
$VMDiskSize = 240GB

Function GetOutboundTraffic{
    $networkinfo = Measure-VM -Name 2Pint-DP01 | `
    Select-Object -property @{Expression = {"{0:N2}" -f(($_.NetworkMeteredTrafficReport | `
    Where-Object direction -Eq 'outbound' | `
    Measure-Object -property TotalTraffic -sum).Sum / 1024) };Label="Outbound Network Traffic (GB)"}
    return $networkinfo.'Outbound Network Traffic (GB)'
}

Function CheckFreeMemory{
    # Check free memory for 25 clients - Minimum is 110 GB 
    $NeededMemory = 110 #GigaBytes
    $AvailableMem = (Get-Counter '\Memory\Available MBytes').countersamples
    $AvailableMem1 = $AvailableMem.cookedvalue
    $AvailableMemInGB = [Math]::Round($AvailableMem1/1024,2)

    # Write-Host "Checking free memory - Minimum is $NeededMemory GB"

    if($AvailableMemInGB -lt $NeededMemory){
        Write-Warning "Oupps, you need at least $NeededMemory GB of memory"
        Write-Warning "Available free memory is $AvailableMemInGB GB"
        Write-Warning "Aborting script..."
        Break
    }
}
Function CheckFreeDiskSpace{
    # Check free space on E: - Minimum is 1024 GB 
    $NeededFreeSpace = 800 #GigaBytes
    $Disk = Get-wmiObject Win32_LogicalDisk -Filter "DeviceID='E:'" 
    $FreeSpace = [MATH]::ROUND($disk.FreeSpace /1GB)
    Write-Host "Checking free space on E: - Minimum is $NeededFreeSpace GB"

    if($FreeSpace -lt $NeededFreeSpace){
        Write-Warning "Oupps, you need at least $NeededFreeSpace GB of free disk space"
        Write-Warning "Available free space on E: is $FreeSpace GB"
        Write-Warning "Aborting script..."
        Break
    }
}


# Set credentials and allow remote administration via PowerShell to all hosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
$Cred = Get-Credential

# Delete any existing Exportfile
#If (Test-Path $ExportFile){Remove-Item $ExportFile -Force }

# Check for Hyper-V Virtual Switch
Write-Host "Checking for Hyper-V Virtual Switch"
$VMSwitchNameCheck = Get-VMSwitch | Where-Object -Property Name -EQ $VMNetwork
if ($VMSwitchNameCheck.Name -eq $VMNetwork){
    Write-Host "Hyper-V switch already exist, all ok..."
}
Else{
    Write-Host "Hyper-V switch does not exist, creating it"
    Write-host "Creating virtual switch..."
    New-VMSwitch -Name $VMNetwork -AllowManagementOS $true -NetAdapterName "Ethernet"
    Start-Sleep -Seconds 20
}
    
# Create the VMs
$i = 1
[System.Collections.ArrayList]$VMList = @()
do {

    Write-Host "Creating VM $i of $NumberOfVMs"
 
    # Create the virtual machines
    $VMName = "$VMNamePrefix" + ($i | ForEach-Object {"{0:D3}" -f $_}) + "$VMNameSuffix"
    $MacAddress = "00:15:5D:" + $SiteID + ":" + ($i | ForEach-Object {"{0:D2}" -f $_}) + ":" + ($i | ForEach-Object {"{0:D2}" -f $_})
    "$VMNamePrefix-" + ($i | ForEach-Object {"{0:D3}" -f $_}) + ",," + $MacAddress 

    Write-host "Creating $VMName VM"
    
    If ($VMType -eq "GEN2-PXE"){
        # Create Gen 2 VM 
        New-VM -Name $VMName -Generation 2 -BootDevice NetworkAdapter -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD
    }

    If ($VMType -eq "GEN1-PXE"){   
        # Create Gen 1 VM 
        New-VM -Name $VMName -Generation 1 -BootDevice LegacyNetworkAdapter -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD
    }

    If ($VMType -eq "GEN2-CD"){
        # Create Gen 2 VM 
        New-VM -Name $VMName -Generation 2 -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD
    }
    
    New-VHD -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize
    Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx"
    Set-VMDvdDrive -VMName $VMName -Path $VMISO
    Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false
  
    # Dynamic memory
    # Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes 4096MB -StartupBytes 4096MB -MaximumBytes 16384MB

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

    $obj = [PSCustomObject]@{
        # Add values to arraylist
        "VMName" = $VMName
        "MacAddress" = $MacAddress
    }

    # Add all the values
    $VMList.Add($obj)|Out-Null

 
$i++
}
while ($i -le $NumberOfVMs)

# Just generate the $VMList array, without creating any VMs
$i = 1
[System.Collections.ArrayList]$VMList = @()
do {
 
    # Create the virtual machines
    $VMName = "$VMNamePrefix" + ($i | ForEach-Object {"{0:D3}" -f $_}) + "$VMNameSuffix"
    $MacAddress = "00:15:5D:" + $SiteID + ":" + ($i | ForEach-Object {"{0:D2}" -f $_}) + ":" + ($i | ForEach-Object {"{0:D2}" -f $_})
    "$VMNamePrefix" + ($i | ForEach-Object {"{0:D3}" -f $_}) + ",," + $MacAddress 

    $obj = [PSCustomObject]@{
        # Add values to arraylist
        "VMName" = $VMName
        "MacAddress" = $MacAddress
    }

    # Add all the values
    $VMList.Add($obj)|Out-Null
 
$i++
}
while ($i -le $NumberOfVMs)


# TBA
BREAK


$Credentials = Get-Credential
Import-Module D:\Demo\_LabEnvironment\MDTDB\MDTDB.psm1 -Verbose
New-PSDrive -Name MDTProduction -Root '\\MDT01\MDTProduction$' -PSProvider FileSystem -Credential $Credentials
Connect-MDTDatabase -sqlServer MDT01 -instance SQLEXPRESS -database MDT 

foreach ($VM in $VMList){
    
    $TaskSequenceID='W11X64-001' # Windows 11 22H2 TS
    $VMName = $VM.VMName
    New-MDTComputer -macAddress $VM.MacAddress -settings @{OSDComputerName=$VMName;TaskSequenceID=$TaskSequenceID}
}


# Set credentials (Use local admin account)
$Cred =Get-Credential
$TargetFolder = "C:\Setup\Sysinternals"

# Autologon
$AutoLogon = "C:\Windows\System32\Autologon.exe"
$UserName = "admjoar"
$Domain = "VIAMONSTRA"
$Password = "P@ssw0rd"
Start-Process $AutoLogon -ArgumentList "/accepteula",$UserName,$Domain,$Password



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





# Export the result to CSV file to ConfigMgr compatible import file (using just the first three fields)
$VMList | Select-Object "Name", "SMBIOS GUID","Mac Address" | ConvertTo-Csv -NoTypeInformation | Set-Content -Path $ExportFile

# Connect to the ConfigMgr Server to copy the list of generated VMs
Net use "\\$SiteServer\E`$" /u:$UserName $Password
Copy-Item $ExportFile "\\CM01\E`$\Demo\BranchCache" -Verbose

# Have CM01 import the the list of generated VMs into ConfigMgr (takes about 2 minutes including collection membership update)
Write-Host "Importing the VMs into ConfigMgr and update collections. Will take a little while..."
Invoke-Command -command { E:\Demo\BranchCache\ImportComputersToConfigMgr.ps1 } -ComputerName $SiteServer -Credential $Cred

# Start the VMs for deployment, waiting 10 seconds in between each.
# Also start separate script that logs network traffic every 10 seconds
Clear-Host
CheckFreeDiskSpace
CheckFreeMemory
Stop-Process $NetworkLogProcess -Force
#$NetworkLogProcess = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File E:\Demo\_LabEnvironment\Get-NetworkInfo.ps1" -PassThru -WindowStyle Hidden
$NetworkLogProcess = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File E:\Demo\_LabEnvironment\Get-NetworkInfo-DP02.ps1" -PassThru -WindowStyle Hidden
$Time = Get-Date
$StartTimeUTC = $Time.ToUniversalTime().ToString("MM/dd/yy HH:mm:ss")
foreach ($VM in $VMList){
    # Optional break
    If ($VM.Name -eq "TMP-W10PEER-007"){Break}
    Start-VM -VMName $VM.VMName
    Start-Sleep -Seconds 20
    
}
Write-Host "First VM started $StartTimeUTC"
$Time = Get-Date
$TimeMinus10Seconds = $Time.AddSeconds(-10)
$TimeMinus10SecondsUTC = $TimeMinus10Seconds.ToUniversalTime().ToString("MM/dd/yy HH:mm:ss")
Write-Host "Last VM started $TimeMinus10SecondsUTC"


#
# Cleanup 
#

# Have CM01 clear the PXE Deployments on the collection
Invoke-Command -command { E:\Demo\BranchCache\ClearPXEDeployment.ps1 } -ComputerName $SiteServer -Credential $Cred

# Apply Checkpoint (Restore Checkpoint)
foreach ($VM in $VMList){
    Restore-VMSnapshot -VMName ($VM.Name + "$VMNameSuffix") -Name "Clean" -Confirm:$false 
    # Restore-VMCheckpoint
}

# Stop the network logging process
Stop-Process $NetworkLogProcess -Force

# Deletes ALL devices in the PCvsBC collection
Invoke-Command -command { E:\Demo\BranchCache\DeleteComputersInConfigMgr.ps1 } -ComputerName $SiteServer -Credential $Cred

foreach ($VM in $VMList){
    Stop-VM -VMName $VM.VMName -TurnOff -Force
}

# Remove ALL VMs in $VMList from Hyper-V
foreach ($VM in $VMList){
    Remove-VM -Name $VM.VMName -Force
}

# Deletes ALL VMs in $VMList from the disk
foreach ($VM in $VMList){
    If (Test-path -Path "$VMLocation\$($VM.VMName)"){Remove-item "$VMLocation\$($VM.VMName)" -Recurse -Force}
}

# Create a Checkpoint
foreach ($VM in $VMList){
    Checkpoint-VM -Name ($VM.Name + "$VMNameSuffix") -SnapshotName "Clean"
}



# Change boot order for testing (set network boot first)
foreach ($VM in $VMList){
    $VMNetworkAdapter = Get-VMNetworkAdapter -VMName ($VM.Name + "$VMNameSuffix") 
    Set-VMFirmware -VMName ($VM.Name + "$VMNameSuffix") -FirstBootDevice $VMNetworkAdapter
}

Set-VMFirmware "Test VM" -FirstBootDevice $vmNetworkAdapter

# Misc stuff for Benchmarking

# Limit output from clients having pre-cached content
$VMtoLimit = Get-VM -Name "2Pint-CHI-W10PEER-001 (Chicago1, WAN 155 mbit)"
$VMtoLimit | Get-VMNetworkAdapter | Set-VMNetworkAdapter -MaximumBandwidth 1024mb 

# Create a Checkpoint
foreach ($VM in $VMList){
    Checkpoint-VM -Name ($VM.Name + "$VMNameSuffix") -SnapshotName "Clean"
}

# Get Network Info
$VM = "DA-Intune-018 (Mike)" 
# Enable VM Resource Metering
Get-VM $VM | Enable-VMResourceMetering
Get-VM $VM | Measure-VM | Select-Object *
(Measure-VM -VMName $VM).NetworkMeteredTrafficReport

