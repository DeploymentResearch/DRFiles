# Demo script for working with Windows Autopilot in VMs in Hyper-V
#
# Author: Johan Arwidmark
# Twitter: @jarwidmark
# LinkedIn: https://www.linkedin.com/in/jarwidmark

# Set credentials 
$Cred = Get-Credential

# VMs to work with
$VMs = @(
    "APTEST205"
    "APTEST206"
    "APTEST207"
    "APTEST208"
    "APTEST209"
)

# Demo Settings and Scripts
$DemoFolder = "E:\Demo\Windows Autopilot"
$APInfoScript = "$DemoFolder\Get-WindowsAutoPilotInfo.ps1"
$APCSVFolder = "$DemoFolder\APCSVFiles"
$APCSVFileAllMachines = "$APCSVFolder\AutoPilot_AllMachines.csv"
$InventoryFile = "$DemoFolder\DemoInventory.csv"

# Make sure the files and folders are there
If (!(Test-Path $DemoFolder)){ Write-Warning "$DemoFolder folder not found, aborting...";Break}
If (!(Test-Path $APCSVFolder)){ Write-Warning "$APCSVFolder folder not found, aborting...";Break}
If (!(Test-Path $APInfoScript)){ Write-Warning "$APScript script not found, aborting...";Break}

# Get some basic VM info from Hyper-V and save as CSV file
[System.Collections.ArrayList]$VMInfo = @()
foreach($VMName in $VMs){ 
    $SerialNumber = (Get-CimInstance -Namespace root\virtualization\v2 -class Msvm_VirtualSystemSettingData -Filter "elementname = '$VMName'").BIOSSerialNumber
    $IPAddresses = (Get-VMNetworkAdapter -VMName $VMName).IPAddresses
    $IPv4Address = $IPAddresses |  Where-Object {$_ -notmatch ':'}
    $DiskSizeInGB = [math]::Round((Get-VM -VMname $VMName | Select-Object VMId | Get-VHD).Size/1GB)
    $VMSwitch = (Get-VMNetworkAdapter -VMName $VMName).SwitchName
    
    $obj = [PSCustomObject]@{
        VMName = $VMName
        IPAddress = $IPv4Address
        SerialNumber = $SerialNumber
        DiskSize = $DiskSizeInGB
        VMSwitch = $VMSwitch
    }

    $VMInfo.Add($obj)|Out-Null
}
$VMInfo | Export-csv -Path $InventoryFile -NoTypeInformation


# Copy the Autopilot script to the VMs using Copy-VMFile
foreach($VMName in $VMs){ 
    # Enable Guest Services (required for Copy-VMFile, and not enabled by default)
    Enable-VMIntegrationService -Name 'Guest Service Interface' -VMName $VMName 
    # Copy the script (overwrite if exist)
    Copy-VMFile -Name $VMName -SourcePath $APInfoScript -DestinationPath C:\Windows\Temp -FileSource Host -Force
}

# Gather Autopilot Hash
foreach($VMName in $VMs){ 
    $Session = New-PSSession -VMName $VMName -Credential $Cred
    Invoke-Command -Session $Session -ScriptBlock { 
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force 
        $APFile = "C:\Windows\Temp\AutoPilot_$env:Computername.csv"
        C:\Windows\Temp\Get-WindowsAutoPilotInfo.ps1 -OutputFile $APFile 
    }
}

# Copy Autopilot Hash to Demo folder on Hyper-V host
foreach($VMName in $VMs){ 
    $session = New-PSSession -VMName $VMName -Credential $cred
    $APFile = "C:\Windows\Temp\AutoPilot_$($session.Computername).csv"
    Copy-Item -FromSession $session -Path "C:\Windows\Temp\*.csv" -Destination $APCSVFolder
}

# Combine the CSV files for easy upload
$CSVFiles = Get-ChildItem -Path $APCSVFolder -Filter "*.CSV" 
$CSVFiles | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $APCSVFileAllMachines -NoTypeInformation -Encoding ASCII   

