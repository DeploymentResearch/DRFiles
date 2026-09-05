<#
.SYNOPSIS
    Repairs a missing MSI in the Windows Installer cache.
.DESCRIPTION
    Detects the installed StifleR client version, downloads the matching MSI, and places it back
    in the installer cache so future repairs and upgrades succeed.
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
      1.0.0 - 2022-09-23 - Initial release
#>

$StifleRClient = Get-CimInstance -Class Win32_Product | Where-Object Name -like "*StifleR Client*" 

$DP = "dp01.corp.viamonstra.com"
$DownloadPath = "C:\Temp"
New-Item -Type Directory -Path $DownloadPath -Force


If ($StifleRClient) {

    $Version = $StifleRClient.Version
    $MSIPath = $StifleRClient.LocalPackage
    $LocalMSIName = Split-Path $MSIPath -Leaf

    If (Test-path -Path $MSIPath){
        $FileFound = "MSI found in local cache"
    }
    Else{
        $FileFound = "MSI Not found in local cache"

        # Download missing files
        switch ($Version) {
            "1.9.9.0" {
                $FileName = "StifleRMSI_1990.zip"
                $URL = "http://$DP/$FileName"
                Start-BitsTransfer -Source $URL -Destination $DownloadPath 
                Expand-Archive -Path $DownloadPath\$FileName -DestinationPath $DownloadPath
                Copy-Item -Path "$DownloadPath\StifleRMSI_1990\StifleR.ClientApp.Installer64.msi" -Destination "C:\Windows\Installer\$LocalMSIName" -Force
            }
            "2.1.0.3" {
                $FileName = "StifleRMSI_2103.zip"
                $URL = "http://$DP/$FileName"
                Start-BitsTransfer -Source $URL -Destination $DownloadPath 
                Expand-Archive -Path $DownloadPath\$FileName -DestinationPath $DownloadPath
                Copy-Item -Path "$DownloadPath\StifleRMSI_2103\StifleR.ClientApp.Installer64.msi" -Destination "C:\Windows\Installer\$LocalMSIName" -Force
            }
            "2.6.1.2" {
                $FileName = "StifleRMSI_2612.zip"
                $URL = "http://$DP/$FileName"
                Start-BitsTransfer -Source $URL -Destination $DownloadPath 
                Expand-Archive -Path $DownloadPath\$FileName -DestinationPath $DownloadPath
                Copy-Item -Path "$DownloadPath\StifleRMSI_2612\StifleR.ClientApp.Installer64.msi" -Destination "C:\Windows\Installer\$LocalMSIName" -Force
            }
            "2.6.6.0" {
                $FileName = "StifleRMSI_2660.zip"
                $URL = "http://$DP/$FileName"
                Start-BitsTransfer -Source $URL -Destination $DownloadPath 
                Expand-Archive -Path $DownloadPath\$FileName -DestinationPath $DownloadPath
                Copy-Item -Path "$DownloadPath\StifleRMSI_2660\StifleR.ClientApp.Installer64.msi" -Destination "C:\Windows\Installer\$LocalMSIName" -Force
            }
        }
    }
        
   Write-Host "$env:ComputerName, $Version, $MSIPath, $FileFound"
}
Else{
    Write-Host "$env:ComputerName, Stifler Client Not found"
}

# Download the 2.6.9.0 version always
$FileName = "StifleRClient_2690.zip"
$URL = "http://$DP/$FileName"
Start-BitsTransfer -Source $URL -Destination $DownloadPath 
Expand-Archive -Path $DownloadPath\$FileName -DestinationPath $DownloadPath
