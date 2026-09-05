<#
.SYNOPSIS
    Applies a legacy driver package from a WIM file during a task sequence.
.DESCRIPTION
    Mounts the driver WIM, injects the drivers into the offline operating system with DISM, and
    logs to the task sequence log path.
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
      1.0.0 - 2023-06-21 - Initial release
#>

# Create Task Sequence Environment Object 
$TSEnv = New-Object -ComObject "Microsoft.SMS.TSEnvironment"

# Set Log file
$LogFile = "$($TSEnv.Value("_SMSTSLogPath"))\MDM-OfflineMediaSupport.log"

Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
   )

   $TimeGenerated = $(Get-Date -UFormat "%D %T")
   $Line = "$TimeGenerated : $Message"
   Add-Content -Value $Line -Path $LogFile -Encoding Ascii

}

# Search for Driver Package. Zip and WIM formats currently supported
$DriverPackageLocation = "$($TSEnv.Value("_SMSTSMDataPath"))\DriverPackage"
Write-Log "DriverPackageLocation set to $DriverPackageLocation"
$DriverPackageCompressedFile = Get-ChildItem -Path $DriverPackageLocation -Recurse -Filter "DriverPackage.*" | Select -First 1
Write-Log "Driver Package found is $($DriverPackageCompressedFile.Name)"

# Set Drivers folder for mounted, or extracted drivers
$DriversLocation = "$($TSEnv.Value("_SMSTSMDataPath"))\Drivers"
Write-Log "Drivers Final Location set to: $DriversLocation"

# Mount or extract driver package before drivers are staged in the driver store
Switch -wildcard ($DriverPackageCompressedFile.Name) {
	"*.zip" {
        Write-Log "Zip Format detected, extract Zip file to drivers folder"
        Expand-Archive -Path $DriverPackageCompressedFile.FullName -DestinationPath $DriversLocation -Force -ErrorAction Stop
    }         

	"*.wim" {
        Write-Log "WIM Format detected, mount wim file to drivers folder"
        New-Item -Path $DriversLocation -ItemType Directory -Force
        Mount-WindowsImage -ImagePath $DriverPackageCompressedFile.FullName -Path $DriversLocation -Index 1 -ErrorAction Stop
    }     
}    

# Stage Drivers via DISM Command
Write-Log "Stage Drivers via DISM Command"
$OSDTargetSystemDrive = "$($TSEnv.Value("OSDTargetSystemDrive"))\"
$DISMLogFile = "$($TSEnv.Value("_SMSTSLogPath"))\MDM-OfflineMediaSupportDISM.log"
DISM.exe /Image:$OSDTargetSystemDrive /Add-Driver /Driver:$DriversLocation /Recurse /logpath:$DISMLogFile
Write-Log "About to run command: DISM.exe /Image:$OSDTargetSystemDrive /Add-Driver /Driver:$DriversLocation /Recurse /logpath:$DISMLogFile"
DISM.exe /Image:$OSDTargetSystemDrive /Add-Driver /Driver:$DriversLocation /Recurse /logpath:$DISMLogFile

# If wim package, unmount folder
Switch -wildcard ($DriverPackageCompressedFile.Name) {
	"*.wim" {
        Write-Log "WIM Format detected, unmounting Drivers folder"
        Dismount-WindowsImage -Path $DriversLocation -Discard
    }     
}   
