<#
.SYNOPSIS
    Publishes task sequence values to the registry for BGInfo to display.
.DESCRIPTION
    Writes the computer name and other deployment values under HKLM\SOFTWARE\PSD so a BGInfo
    template can show live deployment status on the WinPE wallpaper.
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
      1.0.0 - 2023-12-31 - Initial release
#>

# Create TS environment object
$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment

If ($TSEnv.Value("OSDComputerName")){
    $Null = New-Item -Path HKLM:\SOFTWARE\PSD -ItemType Directory -Force
    $Null = New-ItemProperty -Path HKLM:\SOFTWARE\PSD -Name ComputerName -PropertyType String -Value $TSEnv.Value("OSDComputerName") -Force
}
Else {
    $Null = New-Item -Path HKLM:\SOFTWARE\PSD -ItemType Directory -Force
    $Null = New-ItemProperty -Path HKLM:\SOFTWARE\PSD -Name ComputerName -PropertyType String -Value $TSEnv.Value("_SMSTSMachineName") -Force
}

& X:\Windows\System32\Bginfo64.exe X:\Windows\System32\psd.bgi /timer:0 /NOLICPROMPT /SILENT
