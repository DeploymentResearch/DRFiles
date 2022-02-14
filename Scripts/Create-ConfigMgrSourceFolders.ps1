# Check for elevation
Write-Host "Checking for elevation"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
    Write-Warning "Aborting script..."
    Break
}

New-Item -Path E:\MigData -ItemType Directory
New-Item -Path E:\Logs -ItemType Directory
New-Item -Path E:\Sources -ItemType Directory
New-Item -Path E:\Sources\OSD -ItemType Directory
New-Item -Path E:\Sources\OSD\Boot -ItemType Directory
New-Item -Path E:\Sources\OSD\DriverPackages -ItemType Directory
New-Item -Path E:\Sources\OSD\DriverSources -ItemType Directory
New-Item -Path E:\Sources\OSD\MDT -ItemType Directory
New-Item -Path E:\Sources\OSD\OS -ItemType Directory
New-Item -Path E:\Sources\OSD\Settings -ItemType Directory
New-Item -Path E:\Sources\Software -ItemType Directory
New-Item -Path E:\Sources\Software\Adobe -ItemType Directory
New-Item -Path E:\Sources\Software\Microsoft -ItemType Directory

net share 'Logs=E:\Logs' '/grant:EVERYONE,change'
icacls E:\Logs /grant '"VIAMONSTRA\CM_NAA":(OI)(CI)(M)'
net share 'Sources=E:\Sources' '/grant:EVERYONE,full'