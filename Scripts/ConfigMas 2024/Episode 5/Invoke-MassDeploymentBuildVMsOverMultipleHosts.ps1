# Prereqs: 
# Hyper-V Console and PowerShell cmdlets
# ConfigMgr Console

# Create Bootimage ISO
& 'E:\Setup\Scripts\New-BootimageISO.ps1'

# Configure Bootimage ISO for no prompt
& 'E:\Setup\Scripts\New-NoPromptISO.ps1'

# ConfigMgr Settings
$SiteCode = "PS1"
$CollectionName = "MassDeployment - Windows 11 Enterprise x64 23H2"

# Import ConfigMgr Module
Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)

# Hyper-V Settings
$VMNamePrefix = "LAB-R"
$SiteServer = "CM01"
$VMMemory = 4096MB
$VMDiskSize = 240GB
$vCPUCount = 2
$VMNetwork = "Chicago1"
$VMISO = "C:\ISO\Bootimage_NoPrompt.iso"
$NumberOfVMsPerHost = 10
$VMLocation = "C:\VMs"

# Generate list of Hyper-V Hosts (servers)
$LowNumber = 38
$HigNumber = 40
$Srvs = $($LowNumber..$HigNumber | ForEach-Object {"{0:D3}" -f $_})
$Servers = foreach($Srv in $Srvs){"ROGUE-$SRV"}

# Set credentials and allow remote administration via PowerShell to all hosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force

# WinRM Test: Get Memory Configuration
foreach($Server in $Servers){
    Invoke-Command -command { $Memory = Get-WmiObject Win32_ComputerSystem;$MemoryInGB = [math]::round($Memory.TotalPhysicalMemory/1GB, 0);Write-Host "$Env:Computername has $MemoryInGB GB RAM" } -computerName $Server
}

# Copy Boot image ISO File to each Hyper-V Host
Set-Location C: # Make sure to switch to a provider supporting file copy
foreach ($Server in $Servers){
    New-Item "\\$Server\C`$\ISO" -ItemType Directory -Force
    Copy-Item "E:\Setup\Bootimage_NoPrompt.iso" "\\$Server\C`$\ISO\Bootimage_NoPrompt.iso" -Force
}

# Create Hyper-V Virtual Switch on each Hyper-V Host
foreach ($Server in $Servers){
    
    $ScriptBlock = {
        Write-Host "Checking for Hyper-V Virtual Switch"
        $VMSwitchNameCheck = Get-VMSwitch | Where-Object -Property Name -EQ $using:VMNetwork
        if ($VMSwitchNameCheck.Name -eq $using:VMNetwork) {
            Write-Host "Hyper-V switch already exist, all ok..." -ForegroundColor Green
        }
        Else {
            Write-Host "Hyper-V switch does not exist, creating it"
            Write-host "Creating virtual switch..."
            New-VMSwitch -Name $using:VMNetwork -AllowManagementOS $true -NetAdapterName "Ethernet"
            Start-Sleep -Seconds 10
        }
    }
    Invoke-Command -ComputerName $Server -ScriptBlock $ScriptBlock 
}

# Create list of VMs to build on each Hyper-V Host
[System.Collections.ArrayList]$VMList = @()
foreach ($Server in $Servers){

    Write-Host "Working on Hyper-V Host: $Server" -ForegroundColor Green

    # Get last octet of local IP address (used for HyperVHostId portion of mac address range)
    # Note: Current Mac Address range supports a maximum of 256 VMs per host       
    $IPAddress = Invoke-Command -ComputerName $Server -Command { (Get-NetIPConfiguration).IPv4Address.IPAddress }
    $LastOctetInIPAddress = ([IPAddress]$IPAddress).GetAddressBytes()[3]
    $HyperVHostId = $Server.Substring(7,2) + ":" + $LastOctetInIPAddress

    # Create the VM List
    $i = 1
    do {
            
        $VMName = $VMNamePrefix + $Server.Substring(6,3) + "-" + ($i | %{"{0:D3}" -f $_})
        $MacAddress = "00:15:5D:" + $HyperVHostId + ":" + ($i | %{"{0:X2}" -f $_}) 
        Write-Host " - Adding VM $i of $NumberOfVMsPerHost to list, VM Name is: $VMName, Mac Address is: $MacAddress"
    
        $obj = [PSCustomObject]@{

            # Add values to arraylist
            "HyperVHost" = $Server
            "VMName" = $VMName
            "ComputerName" = $VMName # For now, using VM name as computer name
            "SMBIOS GUID" = $Null 
            "MacAddress" = $MacAddress

        }

        # Add all the values
        $VMList.Add($obj)|Out-Null

        $i++
    }
    while ($i -le $NumberOfVMsPerHost)
}
$VMListCount = $VMList.Count
Write-Host "VM list created with $VMListCount VMs"

# Import list of VMs to ConfigMgr
Set-Location "$SiteCode`:"
foreach ($VM in $VMList){
    Import-CMComputerInformation -ComputerName $VM.ComputerName -MacAddress $VM.MacAddress -CollectionName $CollectionName
}

# Wait until ConfigMgr created devices from the import
Start-Sleep -Seconds 300

# Update the target collection
Invoke-CMCollectionUpdate -Name $CollectionName
Start-Sleep -Seconds 60

# Check for machines in the target collection
Set-Location "$SiteCode`:"
Write-Host "Checking for machines in the following collection: $CollectionName "
$Members = Get-CMCollectionMember -CollectionName $CollectionName | Select Name
$MemberCount = $Members.Count
Write-Host "Number of machines found in the collection are: $MemberCount"
If ($Members.Count -eq $VMList.count){
    Write-Host "All good, all machines from the import list are showing ConfigMgr" -ForegroundColor Green
}
Else{
    Write-Warning "The VM list has $($VMList.count) machines, the collection has only  $($Members.Count) "
}

# Create VMs on each Hyper-V Host
$i = 1
foreach ($VM in $VMList){

    $ScriptBlock = {

        # Create the virtual machines
        $VMName = $using:VM.VMName
        $MacAddress = $using:VM.MacAddress
        $HyperVHost = $using:VM.HyperVHost
        Write-Host "Creating VM $using:i of $using:VMListCount, Hyper-V Host is: $HyperVHost, VM Name is: $VMName"
    
        # Create Gen 2 VM with Secureboot Disabled and boot from CD
        New-VM -Name $VMName -Generation 2 -BootDevice CD -MemoryStartupBytes $using:VMMemory -SwitchName $using:VMNetwork -Path $using:VMLocation -NoVHD
    
        New-VHD -Path "$using:VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $using:VMDiskSize
        Add-VMHardDiskDrive -VMName $VMName -Path "$using:VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx"
        $CD = Set-VMDvdDrive -VMName $VMName -Path $using:VMISO
        Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false
  
        Set-VMProcessor -VMName $VMName -Count $using:vCPUCount
        Set-VMNetworkAdapter -VMName $VMName -StaticMacAddress $MacAddress
        $Disk = Get-VMHardDiskDrive -VMName $VMName
        $Network = Get-VMNetworkAdapter -VMName $VMName

        # When booting from ISO with prompt disabled, set boot order to disk first
        Set-VMFirmware -VMName $VMName -FirstBootDevice $Disk

        # Set Checkpoint Type to Standard
        Set-VM -Name $VMName -CheckpointType Standard
    }
    Invoke-Command -ComputerName $VM.HyperVHost -ScriptBlock $ScriptBlock 
    $i++
}

# Start the VMs, slight delay between each start
foreach ($VM in $VMList){

    $HyperVHost =  $VM.HyperVHost
    $VMName = $VM.VMName
    Write-Host "Starting VM: $VMName, on Hyper-V Host: $HyperVHost..."
    
    $ScriptBlock = {
        Start-VM -VMName $using:VMName 
        Start-Sleep -Seconds 10
    }
    Invoke-Command -ScriptBlock $ScriptBlock -computerName $HyperVHost
}

