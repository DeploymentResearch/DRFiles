# Check for elevation
Write-Host "Checking for elevation"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
    Write-Warning "Aborting script..."
    Break
}

# Create and share the Logs folder
New-Item -Path E:\Logs -ItemType directory
New-SmbShare –Name Logs$ –Path E:\Logs -ChangeAccess EVERYONE
icacls E:\Logs /grant '"MDT_BA":(OI)(CI)(M)'
