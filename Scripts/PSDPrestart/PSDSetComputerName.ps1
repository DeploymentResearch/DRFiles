<#
.SYNOPSIS
    Sample Prestart script to set computer name
.DESCRIPTION
    Sample Prestart script to set computer name
.LINK
    https://github.com/FriendsOfMDT/PSD
.NOTES
          FileName: PSDSetComputerName.ps1
          Solution: PowerShell Deployment for MDT
          Author: PSD Development Team
          Contact: @Mikael_Nystrom , @jarwidmark
          Primary: @jarwidmark 
          Created: 
          Modified: 2021-09-17
          Version: 1.0.1

.Example
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

