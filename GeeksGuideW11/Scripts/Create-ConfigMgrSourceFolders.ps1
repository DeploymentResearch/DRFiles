# Check for elevation
Write-Host "Checking for elevation"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
    Write-Warning "Aborting script..."
    Break
}

New-Item -Path E:\Sources\OSD -ItemType Directory
New-Item -Path E:\Sources\OSD\Boot -ItemType Directory
New-Item -Path E:\Sources\OSD\DriverPackages -ItemType Directory
New-Item -Path E:\Sources\OSD\DriverSources -ItemType Directory
New-Item -Path E:\Sources\OSD\OS -ItemType Directory


net share 'Sources=E:\Sources' '/grant:EVERYONE,full'