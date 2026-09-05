<#
.SYNOPSIS
    Tattoos the registry with deployment variables during OS deployment.
.DESCRIPTION
    Writes the task sequence name, deployment time, and related values to a registry key so the
    deployment history stays visible on the device after it is built.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Jorgen Nilsson, ccmexec.com
    Credits: Original script by Jorgen Nilsson, ccmexec.com
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2025-07-29 - Initial release
#>

# Name: OSDTattoo
# Authors: Jörgen Nilsson CCMEXEC
# Script to tattoo the registry with deployment variables during OS deploymnet 
$RegKeyName = "CMOSD"

# Set values
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$FullRegKeyName = "HKLM:\SOFTWARE\" + $regkeyname 

# Create Registry key
New-Item -Path $FullRegKeyName -type Directory -Force -ErrorAction SilentlyContinue

# Get values
$OSDStartTime = $tsenv.value("OSDNTPStartTime")
$OSDFinishTime = $tsenv.value("OSDNTPFinishTime")
$OSDDuration = $tsenv.value("OSDNTPDeploymentTime")
$Organisation = $tsenv.value("_SMSTSOrgName")
$AdvertisementID = $tsenv.Value("_SMSTSAdvertID")
$TaskSequenceID = $tsenv.value("_SMSTSPackageID")
$Packagename = $tsenv.value("_SMSTSPackageName")
$ComputerName = $env:computername
$InstallationMode = $tsenv.value("_SMSTSLaunchMode")

# Write values
New-ItemProperty $FullRegKeyName -Name "OSD Start Time" -Value $OSDStartTime -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty $FullRegKeyName -Name "OSD Finish TIme" -Value $OSDFinishTime -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty $FullRegKeyName -Name "OSD Duration" -Value $OSDDuration -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty $FullRegKeyName -Name "OrganisationName" -Value $Organisation -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty $FullRegKeyName -Name "AdvertisementID" -Value $AdvertisementID -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty $FullRegKeyName -Name "TaskSequenceID" -Value $TaskSequenceID -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty $FullRegKeyName -Name "Task Sequence Name" -Value $Packagename -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty $FullRegKeyName -Name "Installation Type" -Value $InstallationMode -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty $FullRegKeyName -Name "Computername" -Value $ComputerName -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty $FullRegKeyName -Name "OS Version" -value (Get-CimInstance Win32_Operatingsystem).version -PropertyType String -Force | Out-Null
