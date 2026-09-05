<#
.SYNOPSIS
    Extracts and injects drivers from a WIM file during ConfigMgr OSD.
.DESCRIPTION
    Mounts a driver WIM file, injects the drivers into the offline operating system with DISM,
    and logs to the task sequence log path.
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
      1.0.0 - 2024-10-31 - Initial release
#>

# Create Task Sequence Environment Object 
$TSEnv = New-Object -ComObject "Microsoft.SMS.TSEnvironment"

# Set Log file
$LogFile = "$($TSEnv.Value("_SMSTSLogPath"))\InvokeLegacyDriverManagementWithWIM.log"

function Write-Log {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        $Message,
        [Parameter(Mandatory=$false)]
        $ErrorMessage,
        [Parameter(Mandatory=$false)]
        $Component = "Script",
        [Parameter(Mandatory=$false)]
        [int]$Type
    )
    <#
    Type: 1 = Normal, 2 = Warning (yellow), 3 = Error (red)
    #>
   $Time = Get-Date -Format "HH:mm:ss.ffffff"
   $Date = Get-Date -Format "MM-dd-yyyy"
   if ($ErrorMessage -ne $null) {$Type = 3}
   if ($Component -eq $null) {$Component = " "}
   if ($Type -eq $null) {$Type = 1}
   $LogMessage = "<![LOG[$Message $ErrorMessage" + "]LOG]!><time=`"$Time`" date=`"$Date`" component=`"$Component`" context=`"`" type=`"$Type`" thread=`"`" file=`"`">"
   $LogMessage.Replace("`0","") | Out-File -Append -Encoding UTF8 -FilePath $LogFile
}

# Search for WIM Driver Package 
$DriverPackageLocation = "$($TSEnv.Value("_SMSTSMDataPath"))\DriverPackage"
Write-Log "DriverPackageLocation set to $DriverPackageLocation"
$DriverPackageCompressedFile = Get-ChildItem -Path $DriverPackageLocation -Recurse -Filter "DriverPackage.wim" | Select -First 1
Write-Log "Driver Package found is $($DriverPackageCompressedFile.Name)"

# Set Drivers folder for mounted, or extracted drivers
$DriversLocation = "$($TSEnv.Value("_SMSTSMDataPath"))\Drivers"
Write-Log "Drivers Final Location set to: $DriversLocation"

# Mount driver package before drivers are staged in the driver store
New-Item -Path $DriversLocation -ItemType Directory -Force
Mount-WindowsImage -ImagePath $DriverPackageCompressedFile.FullName -Path $DriversLocation -Index 1 -ErrorAction Stop
 
# Stage Drivers via DISM Command
Write-Log "Stage Drivers via DISM Command"
$OSDTargetSystemDrive = "$($TSEnv.Value("OSDTargetSystemDrive"))\"
$DISMLogFile = "$($TSEnv.Value("_SMSTSLogPath"))\InvokeLegacyDriverManagementWithWIM_DISM.log"
Write-Log "About to run command: DISM.exe /Image:$OSDTargetSystemDrive /Add-Driver /Driver:$DriversLocation /Recurse /logpath:$DISMLogFile"
DISM.exe /Image:$OSDTargetSystemDrive /Add-Driver /Driver:$DriversLocation /Recurse /logpath:$DISMLogFile

# Unmount folder
Dismount-WindowsImage -Path $DriversLocation -Discard
