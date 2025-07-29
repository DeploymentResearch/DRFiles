<#
    Name: Gather.ps1
    Actual version: 1.0.7
    Author: Johan Schrewelius, Onevinn AB
    Date: 2018-10-17 v. 1.0.0
    Command: powershell.exe -executionpolicy bypass -file Gather.ps1 [-debug]
    Usage: Run in SCCM Task Sequence as lightweight replacement for MDT Gather Step
    Remark: Creates and sets a limited number of MDT Task Sequence variables, the most commonly used - subjectiveley
    Updated by Sassan Fanai, Onevinn: Added switch parameter and logic to handle Lenovo models.
    2018-12-24 v. 1.0.1: Added more variables and debug switch, aligned variable names with MDT.
    2019-01-09 v. 1.0.2: Protected OSDComputerName from being overwritten if already set.
    2019-01-27 v. 1.0.3: Added method for checking bitlocker status and encryption method.
    2020-04-13 v. 1.0.4: Additional variables when executed in Full OS: OsLocale, WindowsInstallationType, WindowsProductName, TimeZone. 
                         Added desktop chassis type "35".
    2023-04-09 v. 1.0.5: Added variable 'SystemSKUNumber' (According to advice from Mike Terrill)
    2023-11-21 - GARY BLOK - Added UBR for the OS on C:\
    2023-15-12 v. 1.0.7: Various bug fixes to prevent error during TS
    2024-02-28 - GARY BLOK - Adding MachineMatchID - a unique idea used to match devices to driver packs #MMS2024
#>

param (
[switch]$UseOldLenovoName,
[switch]$Debug
)

$TSvars = @{}

$DesktopChassisTypes = @("3","4","5","6","7","13","15","16","35")
$LatopChassisTypes = @("8","9","10","11","12","14","18","21","30","31")
$ServerChassisTypes = @("23")

$VirtualHosts = @{ "Virtual Machine"="Hyper-V"; "VMware Virtual Platform"="VMware"; "VMware7,1"="VMware"; "VirtualBox"="VirtualBox"; "Xen"="Xen" }

$EncryptionMethods = @{ 0 = "UNSPECIFIED";
                        1 = 'AES_128_WITH_DIFFUSER';
                        2 = "AES_256_WITH_DIFFUSER";
                        3 = 'AES_128';
                        4 = "AES_256";
                        5 = 'HARDWARE_ENCRYPTION';
                        6 = "XTS_AES_128";
                        7 = "XTS_AES_256" }

function Get-ComputerSystemProductInfo {

    $cmp = gwmi -Class 'Win32_ComputerSystemProduct'

    If ($cmp.Vendor -eq "LENOVO" -and $UseOldLenovoName -ne $true) {
        $tempModel = $cmp.Version
    }
    else {
        $tempModel = $cmp.Name
    }

    $TSvars.Add("Model", $tempModel)
    $TSvars.Add("UUID", $cmp.UUID)
    $TSvars.Add("Vendor", $cmp.Vendor)

    if($VirtualHosts.ContainsKey($tempModel)) {
        $TSvars.Add("IsVM", "True")
        $TSvars.Add("VMPlatform", $VirtualHosts[$tempModel])
    }
    else {
        $TSvars.Add("IsVM", "False")
        $TSvars.Add("VMPlatform", "")
    }
}

function Get-ComputerSystemInfo {

    $cmp = gwmi -Class 'Win32_ComputerSystem'
    $TSvars.Add("Memory", ($cmp.TotalPhysicalMemory / 1024 / 1024).ToString())
    if($cmp.SystemSKUNumber){
        $TSvars.Add("SystemSKUNumber", $cmp.SystemSKUNumber)
    }
}

function Get-Product {

    $bb = gwmi -Class 'Win32_BaseBoard'
    $TSvars.Add("Product", $bb.Product)
}

function Get-BiosInfo {

    $bios = gwmi -Class 'Win32_BIOS'
    $TSvars.Add("SerialNumber", $bios.SerialNumber)
    $TSvars.Add("BIOSVersion", $bios.SMBIOSBIOSVersion)
    $TSvars.Add("BIOSReleaseDate", $bios.ReleaseDate)
}

function Get-OsInfo {

    $Os = gwmi -Class 'Win32_OperatingSystem'
    $TSvars.Add("OSCurrentVersion", $Os.Version)
    $TSvars.Add("OSCurrentBuild", $Os.BuildNumber)
}

function Get-SystemEnclosureInfo {

    $chassi = gwmi -Class 'Win32_SystemEnclosure' 
    $TSvars.Add("AssetTag", $chassi.SMBIOSAssetTag)

    $chassi.ChassisTypes | foreach {

        if($TSvars.ContainsKey("IsDesktop")) {
            $TSvars["IsDesktop"] = [string]$DesktopChassisTypes.Contains($_.ToString())
        }
        else {
            $TSvars.Add("IsDesktop", [string]$DesktopChassisTypes.Contains($_.ToString()))
        }

        if($TSvars.ContainsKey("IsLaptop")) {
            $TSvars["IsLaptop"] = [string]$LatopChassisTypes.Contains($_.ToString())
        }
        else {
            $TSvars.Add("IsLaptop", [string]$LatopChassisTypes.Contains($_.ToString()))
        }

        if($TSvars.ContainsKey("IsServer")) {
            $TSvars["IsServer"] = [string]$ServerChassisTypes.Contains($_.ToString())
        }
        else {
            $TSvars.Add("IsServer", [string]$ServerChassisTypes.Contains($_.ToString()))
        }
    }
}

function Get-NicConfigurationInfo {

    (gwmi -Class 'Win32_NetworkAdapterConfiguration' -Filter "IPEnabled = 1") | foreach {
        
        $_.IPAddress |% {
            if($_ -ne $null) {
                if($_.IndexOf('.') -gt 0 -and !$_.StartsWith("169.254") -and $_ -ne "0.0.0.0") {

                    if($TSvars.ContainsKey("IPAddress")) {
                         $TSvars["IPAddress"] = $TSvars["IPAddress"] + ',' + $_
                    }
                    else {
                        $TSvars.Add("IPAddress", $_)
                    }
                }
            }
        }

        $_.DefaultIPGateway |% {

            if($_ -ne $null -and $_.IndexOf('.') -gt 0) {

                if($TSvars.ContainsKey("DefaultGateway")) {
                    $TSvars["DefaultGateway"] = $TSvars["DefaultGateway"] + ',' + $_
                }
                else {
                    $TSvars.Add("DefaultGateway", $_)
                }
            }
        }
    }
}

function Get-MacInfo {

    $nic = (gwmi -Class 'Win32_NetworkAdapter' -Filter "NetConnectionStatus = 2")
    $TSvars.Add("MacAddress", $nic.MACAddress -join ',')
}

function Get-BatteryStatus {

    try {
        $AcConnected = (gwmi -Namespace 'root\wmi' -Query "SELECT * FROM BatteryStatus Where Voltage > 0" -EA SilentlyContinue).PowerOnline
    }
    catch { }

    if ($AcConnected -eq $null) {
        $AcConnected = "True"
    }

    $TSvars.Add("IsOnBattery", ((![bool]$AcConnected)).ToString())
}

function Get-Architecture {
    
    $arch = "X86"

    if($env:PROCESSOR_ARCHITECTURE.Equals("AMD64")) {
        $arch = "X64"
    }

    $TSvars.Add("Architecture", $arch)
}

function Get-Processor {

    $proc = gwmi -Class 'Win32_Processor' | Select-Object -First '1'
    $TSvars.Add("ProcessorSpeed", $proc.MaxClockSpeed.ToString())
}

function Get-Bitlocker {

    $IsBDE = $false
    $BitlockerEncryptionType = "N/A"
    $BitlockerEncryptionMethod = "N/A"

    $EncVols = Get-WmiObject -Namespace 'ROOT\cimv2\Security\MicrosoftVolumeEncryption' -Query "Select * from Win32_EncryptableVolume" -EA SilentlyContinue

    if ($EncVols) {

        foreach ($EncVol in $EncVols) {

            if($EncVol.ProtectionStatus -ne 0) {

                $EncMethod = [int]$EncVol.GetEncryptionMethod().EncryptionMethod

                if ($EncryptionMethods.ContainsKey($EncMethod)) {
                    $BitlockerEncryptionMethod = $EncryptionMethods[$EncMethod]
                }

                $Status = $EncVol.GetConversionStatus(0)

                if ($Status.ReturnValue -eq 0) {
                    if ($Status.EncryptionFlags -eq 0x00000001) {
                        $BitlockerEncryptionType = "Used Space Only Encrypted"
                    }
                    else {
                        $BitlockerEncryptionType = "Full Disk Encryption"
                    }
                }
                else {
                    $BitlockerEncryptionType = "Unknown"
                }

                $IsBDE = $true
            }
        }
    }

    $TSvars.Add("IsBDE", $IsBDE.ToString())
    $TSvars.Add("BitlockerEncryptionMethod", $BitlockerEncryptionMethod)
    $TSvars.Add("BitlockerEncryptionType", $BitlockerEncryptionType)
}

function Get-UBR {
    if ($env:SystemDrive -eq "X:"){
        $Info = DISM.exe /image:c:\ /Get-CurrentEdition
        $UBR = ($Info | Where-Object {$_ -match "Image Version"}) -replace "Image Version: "
    }
    else {
        $Info = DISM.exe /online /Get-CurrentEdition
        $UBR = ($Info | Where-Object {$_ -match "Image Version"}) -replace "Image Version: "
    }
    # Reset $LastExitCode to 0 if DISM errors
    $global:LastExitCode = 0
    if ($UBR) {
        #return $UBR
        $TSvars.Add("CDriveUBR", $UBR)
    }
}

function Get-MachineMatchID {
    $Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
    $MachineMatchID = "Unknown" #HP, Intel, others
    
    if ($Manufacturer -match "Dell" -or $Manufacturer -match "Microsoft"){
        $MachineMatchID = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemSKUNumber
    }
    elseif ($Manufacturer -match "Lenovo"){
        $MachineMatchID = ((Get-CimInstance -Class "Win32_Bios" -Namespace "root/cimv2").SMBIOSBIOSVersion).SubString(0, 4)
    }
    
    if ($MachineMatchID -eq "Unknown"){
        $MachineMatchID = (Get-CimInstance -ClassName Win32_BaseBoard).Product
    }
    
    $TSvars.Add("MachineMatchID", $MachineMatchID)
}

Get-ComputerSystemProductInfo
Get-ComputerSystemInfo
Get-Product
Get-BiosInfo
Get-OsInfo
Get-SystemEnclosureInfo
Get-NicConfigurationInfo
Get-MacInfo
Get-BatteryStatus
Get-Architecture
Get-Processor
Get-Bitlocker
Get-UBR
Get-MachineMatchID

if($Debug) {
    $TSvars.Keys | Sort-Object |% {
        Write-Host "$($_) = $($TSvars[$_])"
    }
}
else {
    $tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
    $temp = $tsenv.Value("OSDComputerName")
    $IsNotInPe = $tsenv.Value("_SMSTSInWinPE").ToLower().Equals("false")

    if ($IsNotInPe) {
        
        try {
            $CompInfoInFullOs = Get-ComputerInfo | Select OsLocale, WindowsInstallationType, WindowsProductName, TimeZone
            $TSvars.Add("OsLocale", $CompInfoInFullOs.OsLocale)
            $TSvars.Add("WindowsInstallationType", $CompInfoInFullOs.WindowsInstallationType)
            $TSvars.Add("WindowsProductName", $CompInfoInFullOs.WindowsProductName)
            $TSvars.Add("TimeZone", $CompInfoInFullOs.TimeZone)
        }
        catch { }
    }
    
    if(!$temp) {
        $TSvars.Add("OSDComputerName", $tsenv.Value("_SMSTSMachineName"))
    }

    $TSvars.Keys |% {
        $tsenv.Value($_) = $TSvars[$_].tostring()
    }
}
