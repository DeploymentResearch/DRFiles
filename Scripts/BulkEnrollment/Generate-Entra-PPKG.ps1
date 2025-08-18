# -----------------------------------------------------------------------------
# File: Generate-Entra-PPKG.ps1
# Credits: Michael Niehaus
# Path/Filename/XML modifications: Johan Arwidmark
#
# Description:
# A sample script to generate a provisioning package that can be used to join
# one or more devices to an Azure AD tenant (AAD join). This uses the
# AADInternals module, available on the PowerShell Gallery, as well as the 
# ICD.EXE tool from the Windows 10/11 ADK.
#
# Provided as-is with no support. See https://oofhours.com for related 
# information.
# -----------------------------------------------------------------------------

# Set Working Path
$WorkingPath ="C:\Temp"
Set-Location $WorkingPath

# Base Filename for XML and PPKG
$FileName = "$WorkingPath\BulkEnrollment-Expires-$((Get-Date).AddDays(179).ToString("yyyy-MM-dd-hh-mm-ss"))"

# Make sure NuGet is installed
$provider = Get-PackageProvider NuGet -ErrorAction Ignore
if (-not $provider) {
    Find-PackageProvider -Name NuGet -ForceBootstrap -IncludeDependencies
}

# Import the AADInternals module, installing if necessary
$module = Import-Module AADInternals -PassThru -ErrorAction Ignore
if (-not $module) {
    Install-Module AADInternals -Force
    Import-Module AADInternals -Force
}

# Get the access token
$user = Get-AADIntAccessTokenForAADGraph -Resource urn:ms-drs:enterpriseregistration.windows.net -SaveToCache

# Create a new BPRT (bulk token/bulk PRT)
$bprt = New-AADIntBulkPRTToken -Expires ((Get-Date).AddDays(179))

# Generate the customizations xml file
$xmlObject = [xml]$xml = @"
<?xml version="1.0" encoding="utf-8"?>
<WindowsCustomizations>
  <PackageConfig xmlns="urn:schemas-Microsoft-com:Windows-ICD-Package-Config.v1.0">
    <ID>{$((New-Guid).Guid)}</ID>
    <Name>$FileName</Name>
    <Version>1.0</Version>
    <OwnerType>ITAdmin</OwnerType>
    <Rank>0</Rank>
    <Notes></Notes>
  </PackageConfig>
  <Settings xmlns="urn:schemas-microsoft-com:windows-provisioning">
    <Customizations>
      <Common>
        <Accounts>
          <Azure>
            <Authority>https://login.microsoftonline.com/common</Authority>
            <BPRT>$bprt</BPRT>
          </Azure>
        </Accounts>
      </Common>
    </Customizations>
  </Settings>
</WindowsCustomizations>
"@
# Save as proper XML file
$xmlObject.Save("$FileName.xml") 

# Find the ADK and ICD.exe
if (Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots") {
    $kitsRoot = Get-ItemPropertyValue -Path "HKLM:\Software\WOW6432Node\Microsoft\Windows Kits\Installed Roots" -Name KitsRoot10
} elseif (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots") {
    $kitsRoot = Get-ItemPropertyValue -Path "HKLM:\Software\Microsoft\Windows Kits\Installed Roots" -Name KitsRoot10
} else {
    Write-Error "ADK is not installed."
    return
}
$icdExe = "$kitsRoot\Assessment and Deployment Kit\Imaging and Configuration Designer\x86\ICD.exe"
if (-not (Test-Path $icdExe)) {
    Write-Error "ICD.exe not found."
    return
}

# Generate the PPKG
& "$icdExe" /Build-ProvisioningPackage /CustomizationXML:$FileName.xml /PackagePath:"$FileName.ppkg"
