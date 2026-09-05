<#
.SYNOPSIS
    Publishes DeployR task sequence values to the registry for BGInfo.
.DESCRIPTION
    Writes the computer name and other values under HKLM\SOFTWARE\PSD so BGInfo can display
    live deployment status. Add BGInfo and the template to the boot image first.
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
      1.0.0 - 2026-08-25 - Initial release
#>

# Show BGInfo during DeployR
# Add x64 version of Bginfo.exe, and the BGI template to your boot image

If (${TSEnv:ComputerName}){
    $Null = New-Item -Path HKLM:\SOFTWARE\PSD -ItemType Directory -Force
    $Null = New-ItemProperty -Path HKLM:\SOFTWARE\PSD -Name ComputerName -PropertyType String -Value ${TSEnv:ComputerName} -Force
}

& X:\Windows\System32\Bginfo.exe X:\Windows\System32\psd.bgi /timer:0 /NOLICPROMPT /SILENT
