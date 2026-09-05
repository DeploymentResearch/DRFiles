<#
.SYNOPSIS
    Downloads the missing Avalonia XAML loader files from NuGet.
.DESCRIPTION
    Fetches the Avalonia.Markup.Xaml.Loader package and extracts the .NET 8.0 library, which
    works correctly in the .NET 10 runtime used by the DeployR client.
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
      1.0.0 - 2026-08-31 - Initial release
#>

# Script to download the missing Avalonia files from the Avalonia.Markup.Xaml.Loader NuGet package
# Note: Using the .NET 8.0 library which works fine in the .NET 10 runtime
$ver = '11.3.14'
$url = "https://api.nuget.org/v3-flatcontainer/avalonia.markup.xaml.loader/$ver/avalonia.markup.xaml.loader.$ver.nupkg"
$DownloadPath = "C:\Temp"
$2PintClientPath = "C:\Program Files\2Pint Software\DeployR\Client"

# Create download path if needed
If (-not(Test-Path $DownloadPath)){ New-Item -Path $DownloadPath -ItemType Directory -Force}

# Download and extract the files 
Invoke-WebRequest -Uri $url -OutFile "$DownloadPath\Loader.zip"
Expand-Archive "$DownloadPath\Loader.zip" -DestinationPath "$DownloadPath\Loader" -Force

# Copy the missing files to DeployR Client folder
If (Test-Path $2PintClientPath){
    Copy-Item -Path "$DownloadPath\Loader\lib\net8.0\*" -Destination $2PintClientPath -Verbose
}
Else {
    Write-Warning "2Pint client path: $2PintClientPath not found. Copy the files manually from $DownloadPath\Loader\lib\net8.0"
}


