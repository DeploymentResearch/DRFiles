$SiteServer = "CM01"
$ImportFolder = "E:\BatchDeployment"
$CollectionName = "BatchDeployment"

$HostList = @(
    "CHI-W10PEER-007"
    "CHI-W10PEER-008"
    "CHI-W10PEER-014"
    "CHI-W10PEER-015"
    "CHI-W10PEER-016"
    "CHI-W10PEER-017"
    "CHI-W10PEER-018"
    "CHI-W10PEER-019"
    "CHI-W10PEER-020"
    #"ROGUE-001"
    #"ROGUE-002"
    #"ROGUE-003"
    #"ROGUE-004"
    #"ROGUE-005"
    #"ROGUE-006"
    #"ROGUE-007"
    #"ROGUE-008"
    #"ROGUE-009"
    #"ROGUE-010"
)

# Below are details for the build
$BuildInfo = @()
$BuildInfo += [pscustomobject]@{ Server = "CHI-W10PEER-007"; VMNamePrefix = "C007";HyperVHostID = "C0";NumberOfVMs = 4;VMType = "GEN2-PXE" }
$BuildInfo += [pscustomobject]@{ Server = "CHI-W10PEER-008"; VMNamePrefix = "C008";HyperVHostID = "C1";NumberOfVMs = 4;VMType = "GEN2-PXE" }
$BuildInfo += [pscustomobject]@{ Server = "CHI-W10PEER-014"; VMNamePrefix = "C014";HyperVHostID = "C2";NumberOfVMs = 4;VMType = "GEN2-PXE" }
$BuildInfo += [pscustomobject]@{ Server = "CHI-W10PEER-015"; VMNamePrefix = "C015";HyperVHostID = "C3";NumberOfVMs = 4;VMType = "GEN2-PXE" }
$BuildInfo += [pscustomobject]@{ Server = "CHI-W10PEER-016"; VMNamePrefix = "C016";HyperVHostID = "C4";NumberOfVMs = 4;VMType = "GEN2-PXE" }
$BuildInfo += [pscustomobject]@{ Server = "CHI-W10PEER-017"; VMNamePrefix = "C017";HyperVHostID = "C5";NumberOfVMs = 4;VMType = "GEN2-PXE" }
$BuildInfo += [pscustomobject]@{ Server = "CHI-W10PEER-018"; VMNamePrefix = "C018";HyperVHostID = "C6";NumberOfVMs = 4;VMType = "GEN2-PXE" }
$BuildInfo += [pscustomobject]@{ Server = "CHI-W10PEER-019"; VMNamePrefix = "C019";HyperVHostID = "C7";NumberOfVMs = 4;VMType = "GEN2-PXE" }
$BuildInfo += [pscustomobject]@{ Server = "CHI-W10PEER-020"; VMNamePrefix = "C020";HyperVHostID = "C8";NumberOfVMs = 4;VMType = "GEN2-PXE" }
#$BuildInfo += [pscustomobject]@{ Server = "ROGUE-001"; VMNamePrefix = "R001";HyperVHostID = "D0";NumberOfVMs = 4;VMType = "GEN2-PXE" }
#$BuildInfo += [pscustomobject]@{ Server = "ROGUE-002"; VMNamePrefix = "R002";HyperVHostID = "D1";NumberOfVMs = 4;VMType = "GEN2-PXE" }
#$BuildInfo += [pscustomobject]@{ Server = "ROGUE-003"; VMNamePrefix = "R003";HyperVHostID = "D2";NumberOfVMs = 4;VMType = "GEN2-PXE" }
#$BuildInfo += [pscustomobject]@{ Server = "ROGUE-004"; VMNamePrefix = "R004";HyperVHostID = "D3";NumberOfVMs = 4;VMType = "GEN2-PXE" }
#$BuildInfo += [pscustomobject]@{ Server = "ROGUE-005"; VMNamePrefix = "R005";HyperVHostID = "D4";NumberOfVMs = 4;VMType = "GEN2-PXE" }
#$BuildInfo += [pscustomobject]@{ Server = "ROGUE-006"; VMNamePrefix = "R006";HyperVHostID = "D5";NumberOfVMs = 4;VMType = "GEN2-PXE" }
#$BuildInfo += [pscustomobject]@{ Server = "ROGUE-007"; VMNamePrefix = "R007";HyperVHostID = "D6";NumberOfVMs = 4;VMType = "GEN2-PXE" }
#$BuildInfo += [pscustomobject]@{ Server = "ROGUE-008"; VMNamePrefix = "R008";HyperVHostID = "D7";NumberOfVMs = 4;VMType = "GEN2-PXE" }
#$BuildInfo += [pscustomobject]@{ Server = "ROGUE-009"; VMNamePrefix = "R009";HyperVHostID = "D8";NumberOfVMs = 4;VMType = "GEN2-PXE" }
#$BuildInfo += [pscustomobject]@{ Server = "ROGUE-010"; VMNamePrefix = "R010";HyperVHostID = "D9";NumberOfVMs = 3;VMType = "GEN2-PXE" }

$BuildInfo.Count

$HostList.Count

# Allow remote administration via PowerShell to all hosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force

# Get Free Diskspace
foreach($row in $BuildInfo){
    Invoke-Command -command { $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"; "$Env:Computername C: has {0:#.0} GB free of {1:#.0} GB Total" -f ($disk.FreeSpace/1GB),($disk.Size/1GB) } -ComputerName $row.Server
}

# Create the VMs folder
foreach($row in $BuildInfo){
    write-host $row.Server;New-Item "\\$($row.Server)\C`$\VMs" -ItemType Directory 
}

# Copy the VM build script to each Hyper-V Host
Set-Location C:
foreach($Server in $HostList){ write-host $Server;Net use \\$Server /u:$UserName $Password }
foreach($Server in $HostList){ write-host $Server;New-Item "\\$Server\C`$\Setup" -ItemType Directory }
foreach($Server in $HostList){ write-host $Server;Copy "E:\Demo\BranchCache\BatchDeploymentBuildVMs.ps1" "\\$Server\C`$\Setup"}

foreach($row in $BuildInfo){
    $VMNamePrefix = $row.VMNamePrefix
    $HyperVHostID = $row.HyperVHostID
    $NumberOfVMs = $row.NumberOfVMs
    $VMType = $row.VMType
    $Server = $row.Server

    # Using the $Using: feature in PowerShell to pick up local variables 
    # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_variables?view=powershell-7
    Invoke-Command -Command { C:\Setup\BatcheDeploymentBuildVMs.ps1 -VMNamePrefix $Using:VMNamePrefix -HyperVHostID $Using:HyperVHostID -NumberOfVMs $Using:NumberOfVMs -VMType $Using:VMType } -computerName $Server -AsJob
}

# Check status of jobs
Get-Job

# Copy the CSV file over created VMs
foreach($Server in $HostList){
    write-host $Server;Copy-Item "\\$Server\C`$\Setup\computers.csv" E:\BatchDeployment\$($Server)_computers.csv 
}

# Import the the list of generated VMs into ConfigMgr (takes about 2 minutes including collection membership update)
E:\Demo\BranchCache\ImportComputersToConfigMgr.ps1 -ImportFolder $ImportFolder -CollectionName $CollectionName 

# Update the ALL Systems collection. NOTE: DO NOT DO THIS IN PRODUCTION!!!
Invoke-CMCollectionUpdate -Name "All Systems" 
Start-Sleep -Seconds 20

# Update the target collection. 
Invoke-CMCollectionUpdate -Name $CollectionName
Start-Sleep -Seconds 60

# List current Collection members
"Machines in $CollectionName collection"
$Members = Get-CMCollectionMember -CollectionName $CollectionName | Select Name
$Members 
""
"Number of machines in $CollectionName collection: " + $Members.Count


# ----------------------- Build Time ----------------------

$Time = Get-Date
$StartTimeUTC = $Time.ToUniversalTime().ToString("MM/dd/yy HH:mm:ss")

foreach($Server in $HostList){
    $VMList = Get-VM -ComputerName $Server 
    foreach ($VM in $VMList){

        Write-Host "Starting $($VM.Name)"
        Start-VM -VMName $VM.VMName -ComputerName $Server
        Start-Sleep -Seconds 5
    }

    # Optional break
    If ($VM.Name -eq "C007-004"){Break}

}

Write-Host "First VM started $StartTimeUTC"
$Time = Get-Date
$TimeMinus10Seconds = $Time.AddSeconds(-10)
$TimeMinus10SecondsUTC = $TimeMinus10Seconds.ToUniversalTime().ToString("MM/dd/yy HH:mm:ss")
Write-Host "Last VM started $TimeMinus10SecondsUTC"




# --------------------- Cleanup ------------------------------

# Stop and delete all VMs
Invoke-Command -command { Get-VM | Stop-VM -TurnOff -Force } -computerName $HostList -Credential $Cred
Invoke-Command -command { Get-VM | Remove-VM -Force } -computerName $HostList -Credential $Cred

# Check if C:\Vms is not empty, and if it is, delete all VMs in it
Invoke-Command -command { if(!((Get-ChildItem C:\VMs | Measure-Object).Count -eq 0)){ Remove-Item C:\VMs\* -Recurse -Force } } -computerName $HostList -Credential $Cred

# Have CM01 clear the PXE Deployments on the collection.
Set-Location "PS1:"
Get-CMCollectionMember -CollectionName $CollectionName | Clear-CMPxeDeployment -Verbose
Set-Location "C:"

# Clear Caches everywhere

    # Clear ConfigMgr Cache on all clients
    Invoke-Command -ScriptBlock {$UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr;$Cache = $UIResourceMgr.GetCacheInfo();$CacheElements = $Cache.GetCacheElements();foreach($Element in $CacheElements){$Cache.DeleteCacheElementEx($Element.CacheElementID, $true)}} -computerName $HostList 

    # Clear BranchCache cache on all clients
    Invoke-Command -command { Clear-BCCache -Force } -computerName $HostList


# Apply Checkpoint (Restore Checkpoint)
foreach($Server in $HostList){
    $VMList = Get-VM -ComputerName $Server 
    foreach ($VM in $VMList){
        Restore-VMSnapshot -VMName $VM.Name -ComputerName $Server -Name "Clean" -Confirm:$false 
    }
}

# ---------------- Misc ----------------------

# Create a Checkpoint
foreach($Server in $HostList){
    $VMList = Get-VM -ComputerName $Server 
    foreach ($VM in $VMList){
        Checkpoint-VM -VMName $VM.Name -ComputerName $Server -SnapshotName "Clean"
    }
}


# ---------------------------- OLD Stuff ------------------------

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
    $AvailableMem1 = $Mem.cookedvalue
    $AvailableMemInGB = [Math]::Round($AvailableMem1/1024,2)

    Write-Host "Checking free memory - Minimum is $NeededMemory GB"

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
$Username = 'VIAMONSTRA\Administrator'
$Password = 'P@ssw0rd'
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$pass

# Delete any existing Exportfile
If (Test-Path $ExportFile){Remove-Item $ExportFile -Force }

# Check for Hyper-V Virtual Switch
Write-Host "Checking for Hyper-V Virtual Switch"
$VMSwitchNameCheck = Get-VMSwitch | Where-Object -Property Name -EQ $VMNetwork
if ($VMSwitchNameCheck.Name -eq $VMNetwork)
    {
    Write-Host "Hyper-V switch already exist, all ok..."
    }
Else
    {
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
    $VMName = "$VMNamePrefix-" + ($i | %{"{0:D3}" -f $_}) + "$VMNameSuffix"
    $MacAddress = "00:15:5D:" + $HyperVHostID + ":" + ($i | %{"{0:D2}" -f $_}) + ":" + ($i | %{"{0:D2}" -f $_})
    "$VMNamePrefix-" + ($i | %{"{0:D3}" -f $_}) + ",," + $MacAddress | Out-File -FilePath $ExportFile -Append

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

# Just generate the $VMList array, without creating any VMs
$i = 1
[System.Collections.ArrayList]$VMList = @()
do {
 
    # Create the virtual machines
    $VMName = "$VMNamePrefix-" + ($i | %{"{0:D3}" -f $_}) + "$VMNameSuffix"
    $MacAddress = "00:15:5D:" + $SiteID + ":" + ($i | %{"{0:D2}" -f $_}) + ":" + ($i | %{"{0:D2}" -f $_})
    "$VMNamePrefix-" + ($i | %{"{0:D3}" -f $_}) + ",," + $MacAddress | Out-File -FilePath $ExportFile -Append

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

# Connect to the ConfigMgr Server to copy the list of generated VMs
Net use "\\$SiteServer\E`$" /u:$UserName $Password
Copy-Item $ExportFile "\\CM01\E`$\Demo\BranchCache" -Verbose

# Have CM01 import the the list of generated VMs into ConfigMgr (takes about 2 minutes including collection membership update)
Write-Host "Importing the VMs into ConfigMgr and update collections. Will take a little while..."
Invoke-Command -command { E:\Demo\BranchCache\ImportComputersToConfigMgr.ps1 } -ComputerName $SiteServer -Credential $Cred

# Start the VMs for deployment, waiting 10 seconds in between each.
# Also start separate script that logs network traffic every 10 seconds
cls
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


# Enable VM Resource Metering
Get-VM 2Pint-DC01 | Enable-VMResourceMetering
Get-VM 2Pint-CM01 | Enable-VMResourceMetering
Get-VM 2Pint-DP01 | Enable-VMResourceMetering
Get-VM 2Pint-DP01 | Measure-VM | select *

# Get the network traffic use the properties of the NetworkMeteredTrafficReport (in MB)
(Measure-VM -VMName 2Pint-DC01).NetworkMeteredTrafficReport
(Measure-VM -VMName 2Pint-CM01).NetworkMeteredTrafficReport
(Measure-VM -VMName 2Pint-DP01).NetworkMeteredTrafficReport

# Reset the counters
Get-VM 2Pint-DC01 | Reset-VMResourceMetering
Get-VM 2Pint-CM01 | Reset-VMResourceMetering
Get-VM 2Pint-DP01 | Reset-VMResourceMetering

# Use VM Network Adapter ACLs to measure Network from or to a specific network. 
# With ACLs, you can not just allow or deny network traffic, and you can also meter network traffic for a particular subnet or IP address.
# Add-VMNetworkAdapterAcl -VMName 2Pint-DP01 -Action Meter -RemoteIPAddress 10.10.0.0/16 -Direction Outbound

