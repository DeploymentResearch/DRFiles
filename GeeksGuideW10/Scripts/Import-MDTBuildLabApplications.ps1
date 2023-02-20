# Check for elevation
Write-Host "Checking for elevation"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
    Write-Warning "Aborting script..."
    Break
}

# Check for application source folder
Write-Host "Checking for E:\Labfiles\LTI Support Files\MDT Build Lab\Applications"
If (Test-Path 'E:\Labfiles\LTI Support Files\MDT Build Lab\Applications'){
    Write-Host "Application source folder found, OK, continuing..." -ForegroundColor Green
    Write-Host ""
    } 
Else {
    Write-Warning "Oupps, cannot find Application source folder, aborting script..."
    Break
}


# Import MDT module and connect to the MDT Build Lab deployment share
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "E:\MDTBuildLab"

# Verify that Microsoft folder exist on the MDT Build Lab deployment share
Write-Host "Checking for application target folder in MDT"
If (Test-Path 'DS001:\Applications\Microsoft'){
    Write-Host "Application target folder found, OK, continuing..." -ForegroundColor Green
    Write-Host ""
    } 
Else {
    Write-Warning "Oupps, cannot find the Application target folder"
    Write-Warning "Did you really create the Microsoft folder in the Applications node"
    Write-Warning "Aborting script..."
    Break
}

# Import Applications
import-MDTApplication -path "DS001:\Applications\Microsoft" -enable "True" -Name "Install - Microsoft Silverlight 5.0 x64" -ShortName "Install - Microsoft Silverlight 5.0 x64" -Version "" -Publisher "" -Language "" -CommandLine "cscript.exe Install-MicrosoftSilverlight5x64.wsf" -WorkingDirectory ".\Applications\Install - Microsoft Silverlight 5.0 x64" -ApplicationSourcePath "E:\Labfiles\LTI Support Files\MDT Build Lab\Applications\Install - Microsoft Silverlight 5.0 x64" -DestinationFolder "Install - Microsoft Silverlight 5.0 x64" -Verbose
import-MDTApplication -path "DS001:\Applications\Microsoft" -enable "True" -Name "Install - Microsoft Visual C++ - x86-x64" -ShortName "Install - Microsoft Visual C++ - x86-x64" -Version "" -Publisher "" -Language "" -CommandLine "cscript.exe Install-MicrosoftVisualC++x86x64.wsf" -WorkingDirectory ".\Applications\Install - Microsoft Visual C++ - x86-x64" -ApplicationSourcePath "E:\Labfiles\LTI Support Files\MDT Build Lab\Applications\Install - Microsoft Visual C++ - x86-x64" -DestinationFolder "Install - Microsoft Visual C++ - x86-x64" -Verbose
