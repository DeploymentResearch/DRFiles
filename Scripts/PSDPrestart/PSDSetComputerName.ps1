<#
.SYNOPSIS
    Sample PSD prestart script that sets the computer name.
.DESCRIPTION
    Reads the MAC addresses of the device and sets the computer name from a lookup, before the
    task sequence selection dialog appears.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  PSD Development Team
    Credits: PSD Development Team
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.1

    Change history:
      1.0.1 - 2022-01-02 - Initial release
#>

param (

)

# Load core modules
Import-Module PSDUtility

# Check for debug in PowerShell and TSEnv
if($TSEnv:PSDDebug -eq "YES"){
    $Global:PSDDebug = $true
}
if($PSDDebug -eq $true)
{
    $verbosePreference = "Continue"
}

# Get MAC addresses for computer
Write-PSDLog "Getting the MAC addresses for computer"
$NetworkAdapters = Get-CimInstance -Namespace "root\cimv2" -Class Win32_NetworkAdapterConfiguration -Filter `
    "NOT MacAddress LIKE '' and  `
    NOT Description LIKE '%miniport%'" 
$FirstWiredMacAddress = ($NetworkAdapters | Select -First 1).MacAddress
Write-PSDLog "MAC address is $FirstWiredMacAddress"

# Set computer name based on prefix plus Mac Address
$Prefix = "PC-"
$ComputerName = $Prefix + $($FirstWiredMacAddress -replace ":","")
Write-PSDLog "Computer name is $ComputerName"

#Write XML File
$v = [xml]"<?xml version=`"1.0`" ?><MediaVarList Version=`"4.00.5345.0000`"></MediaVarList>"
$element = $v.CreateElement("var")
$element.SetAttribute("name", "OSDComputerName") | Out-Null
$element.AppendChild($v.createCDATASection($ComputerName)) | Out-Null
$v.DocumentElement.AppendChild($element) | Out-Null

$path = "X:\MININT\PrestartVariables.xml"
$v.Save($path)
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Prestart Variables are saved in: $path"

