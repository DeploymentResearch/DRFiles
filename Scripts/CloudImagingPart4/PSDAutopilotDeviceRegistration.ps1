<#
.SYNOPSIS
    Client-Side script for Cloud OS Deployment, Part 4

.DESCRIPTION
    Uploads Autopilot hardware hash, computer name, and Intune group info to a RestPS web service
	Waits until the device is imported and assigned to an Autopilot profile
	Stages a PSD cleanup script in C:\Windows\Temp

.NOTES
    Author: Johan Arwidmark / deploymentresearch.com
    Twitter (X): @jarwidmark
    LinkedIn: https://www.linkedin.com/in/jarwidmark
    License: MIT
    Source:  https://github.com/DeploymentResearch/DRFiles

.DISCLAIMER
    This script is provided "as is" without warranty of any kind, express or implied.
    Use at your own risk — the author and DeploymentResearch assume no responsibility for any
    issues, damages, or data loss resulting from its use or modification.

    This script is shared in the spirit of community learning and improvement.
    You are welcome to adapt and redistribute it under the terms of the MIT License.

.VERSION
    1.0.2
    Released: 2025-10-01
    Change history:
      1.0.2 - 2025-10-01 - Updated to use new start loader
      1.0.1 - 2021-09-10 - Integration release for the PSD Cloud OS Deployment solution
      1.0.0 - 2020-05-12 - Initial release
#>

# Update PowerShell modules path with PSD modules and import the PSDUtility module
$ModulePath = "C:\MININT\Cache\Tools\Modules"
$env:PSModulePath += ";$ModulePath"
Import-Module PSDUtility -Verbose:$false

# Replace PSDStartLoader with version for Autopilot and the Windows setup specialize pass
Write-PSDLog -Message "Replacing PSDStartLoader with version for Autopilot and the Windows setup specialize pass"
$SourceFile = "C:\MININT\Cache\PSDResources\Autopilot\PSDStartLoaderAutopilot.psm1"
$DestinationFile = "$ModulePath\PSDStartLoader\PSDStartLoader.psm1"
Write-PSDLog -Message "Copying $SourceFile to $DestinationFile"
Copy-Item -Path $SourceFile -Destination $DestinationFile -Force

# Load core modules
Import-Module PSDStartLoader -Global -Force -Verbose:$false

# Install PSD Root CA certificate 
Write-PSDLog -Message "Entering certificate block..."
$Certificates = @()
$CertificateLocations = "$($env:SYSTEMDRIVE)\Deploy\Certificates","$($env:SYSTEMDRIVE)\MININT\Certificates"
foreach($CertificateLocation in $CertificateLocations){
    if((Test-Path -Path $CertificateLocation) -eq $true){
        Write-PSDLog -Message "Looking for certificates in $CertificateLocation"
        $Certificates += Get-ChildItem -Path "$CertificateLocation" -Filter *.cer
    }
}
foreach($Certificate in $Certificates){
    Write-PSDLog -Message "Found $($Certificate.FullName), trying to add as root certificate"
    $Return = Import-PSDCertificate -Path $Certificate.FullName -CertStoreScope "LocalMachine" -CertStoreName "Root"
    If($Return -eq "0"){
        Write-PSDLog -Message "Succesfully imported $($Certificate.FullName)"
    }
    else{
        Write-PSDLog -Message "Failed to import $($Certificate.FullName)"
    }
}

# Start the splashscreen
$PSDStartLoader = New-PSDStartLoader -LogoImgPath "C:\MININT\Cache\scripts\powershell.png" -FullScreen

# wait for UI to loaded on screen
Do{
    Start-Sleep -Milliseconds 300
}
Until($PSDStartLoader.isLoaded)

# Start the progress bar scrolling
Update-PSDStartLoaderProgressBar -Runspace $PSDStartLoader -Status "Gathering device details..." -Indeterminate

$DeviceInfo = Get-PSDLocalInfo -Passthru
$primaryinterface = Get-PSDStartLoaderInterfaceDetails

Update-PSDStartLoaderProgressBar -Runspace $PSDStartLoader -Status "Populating device details..." -PercentComplete 10
# Update UI with device details
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtManufacturer -Value $DeviceInfo.Manufacturer
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtModel -Value $DeviceInfo.Model
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtSerialNumber -Value $DeviceInfo.SerialNumber
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtAssetTag -Value $DeviceInfo.assettag

Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtMac -Value $primaryinterface.MacAddress
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtIP -Value $primaryinterface.IPAddress
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtSubnet -Value $primaryinterface.SubnetMask
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtGateway -Value $primaryinterface.GatewayAddresses
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtDHCP -Value $primaryinterface.DhcpServer

Start-Sleep -Seconds 2
Update-PSDStartLoaderProgressBar -Status "Gathering Hardware Hash for device" -Runspace $PSDStartLoader -PercentComplete 20


# Get variables stored in Variables.dat (TS environment not available at this point)
$path = "C:\MININT\Variables.dat"
if (Test-Path -Path $path) {
    [xml] $v = Get-Content -Path $path
    $v | Select-Xml -Xpath "//var" | foreach { 
        If ($($_.Node.name) -eq "INTUNEGROUP"){ $INTUNEGROUP = $($_.Node.'#cdata-section') }  
        If ($($_.Node.name) -eq "OSDCOMPUTERNAME"){ $OSDCOMPUTERNAME = $($_.Node.'#cdata-section') }  
        If ($($_.Node.name) -eq "USERID"){ $USERID = $($_.Node.'#cdata-section') }  
        If ($($_.Node.name) -eq "USERPASSWORD"){ $USERPASSWORD = $($_.Node.'#cdata-section') }  
        If ($($_.Node.name) -eq "DEPLOYROOT"){ $DEPLOYROOT = $($_.Node.'#cdata-section') }  
    } 
}
Write-PSDLog -Message "Intune Group from PSD deployment is $INTUNEGROUP"
Write-PSDLog -Message "Computer Name from PSD deployment is $OSDCOMPUTERNAME"
Write-PSDLog -Message "Username from PSD deployment is $USERID"
Write-PSDLog -Message "Password from PSD deployment is **SUPRESSED**"
Write-PSDLog -Message "Deployroot from PSD deployment is $DEPLOYROOT"

# Get Autopilot Hardware Hash
$AutopilotOutputFile = "C:\Windows\Temp\AutopilotInfo.csv"
Write-PSDLog "Autopilot result will be saved in $AutopilotOutputFile"
$AutopilotScriptPath = "C:\MININT\Cache\PSDResources\Autopilot\Get-WindowsAutopilotInfo.ps1"
$GetAutoPilotArguments = "$AutopilotScriptPath -OutputFile $AutopilotOutputFile"
Write-PSDLog -Message "About to run the command: $GetAutoPilotArguments"
$GetAutoPilotProcess = Start-Process PowerShell -ArgumentList $GetAutoPilotArguments -NoNewWindow -PassThru -Wait

if(-not($GetAutoPilotProcess.ExitCode -eq 0)){
    Write-PSDLog -Message "Something went wrong running Get-WindowsAutopilotInfo.ps1. Exit code $($GetAutoPilotProcess.ExitCode)"
    Write-PSDLog -Message "Aborting script..."

    Show-PSDInfo -Message "Something went wrong running Get-WindowsAutopilotInfo.ps1. Exit code $($GetAutoPilotProcess.ExitCode). Aborting script..." -Severity Error -OSDComputername $Env:COMPUTERNAME -Deployroot "C:\MININT\CACHE "
    Start-Process PowerShell -Wait
    Break
}

Write-PSDLog -Message "Results saved to $AutopilotOutputFile"

# Log the result 
$AutopilotCSV = Import-Csv $AutopilotOutputFile
$SerialNumber = ($AutopilotCSV | Select -First 1)."Device Serial Number"
Write-PSDLog "Device Serial Number is: $SerialNumber"

# Add ComputerName and IntuneGroup to CSV 
$AutopilotCSV | Add-Member -Type NoteProperty -Name 'ComputerName' -Value $OSDCOMPUTERNAME
$AutopilotCSV | Add-Member -Type NoteProperty -Name 'IntuneGroup' -Value $INTUNEGROUP

# Convert the CSV file to JSON 
Write-PSDLog -Message "Converting the CSV file to JSON"
$AutopilotJSON = $AutopilotCSV | ConvertTo-Json 
Write-PSDLog -Message "JSON object created for computer: $OSDCOMPUTERNAME"

# Cleanup
#Write-PSDLog -Message "Removing $AutopilotOutputFile file"
#Remove-item -Path $AutopilotOutputFile -Force 

# Workaround for "The underlying connection was closed" error
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

# Authentication
$pass = ConvertTo-SecureString -AsPlainText $USERPASSWORD -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $USERID,$pass

$bytes = [System.Text.Encoding]::UTF8.GetBytes(
    ('{0}:{1}' -f $Cred.UserName, $Cred.GetNetworkCredential().Password)
)
$Authorization = 'Basic {0}' -f ([Convert]::ToBase64String($bytes))
$Headers = @{ Authorization = $Authorization }


# Upload the JSON object to the Autopilot registration webservice script on your deployment server
# Max allowed time is 30 minutes
try {
    # Construct full Uri
    $DeployRootUri = [System.Uri]"$DeployRoot)"
    $RestPSServer = $DeployRootUri.Host 
    $RestPSMethod = "PSDAutopilotRegistration"
    $RestPSPort = "8080"
    $RestPSProtocol = "https"
    $Uri = "$RestPSProtocol`://$RestPSServer`:$RestPSPort/$RestPSMethod"
    Write-PSDLog -Message "Connecting to $RestPSServer on port $RestPSPort, protocol: $RestPSProtocol, using method $RestPSMethod"
    Write-PSDLog -Message "Full Uri is: $Uri"

    # Update UI with progress details
    Start-Sleep -Seconds 2
    Update-PSDStartLoaderProgressBar -Status "Connecting to RestPS web service at $("$RestPSProtocol`://$RestPSServer") ...." -Runspace $PSDStartLoader -PercentComplete 30

    # Update UI with progress details
    Start-Sleep -Seconds 5
    Update-PSDStartLoaderProgressBar -Status "Registering device with Windows Autopilot, this can take up to 20 minutes...." -Runspace $PSDStartLoader -PercentComplete 50

    # Call RestPS webservice
    $Return = Invoke-RestMethod -Method POST -Uri $Uri -Body $AutopilotJSON -TimeoutSec 1800 -Headers $Headers 

    # Log result
    Write-PSDLog "Webservice returned: $Return" 
    
}
catch [System.Exception] {

    # Log and show error message
    Write-PSDLog -Message "Request to $($Uri) failed with HTTP Status $($_.Exception.Response.StatusCode) and description: $($_.Exception.Response.StatusDescription)"

    Show-PSDInfo -Message "Request to $($Uri) failed with HTTP Status $($_.Exception.Response.StatusCode) and description: $($_.Exception.Response.StatusDescription). Aborting script..." -Severity Error -OSDComputername $Env:COMPUTERNAME -Deployroot "C:\MININT\CACHE "
    Start-Process PowerShell -Wait
    Break
}

# Update UI with progress details
Start-Sleep -Seconds 2
Update-PSDStartLoaderProgressBar -Status "Device registered with Windows Autopilot, assigned computer name is $OSDCOMPUTERNAME..." -Runspace $PSDStartLoader -PercentComplete 90

Start-Sleep -Seconds 5
Update-PSDStartLoaderProgressBar -Status "Starting PSD cleanup..." -Runspace $PSDStartLoader -PercentComplete 100
# Note the above just notifies the user, the cleanup happens a little bit later, initated from the unattend.xml file.

Start-Sleep -Seconds 3
# Close the splash screen
If($PSDStartLoader.isLoaded){
    Close-PSDStartLoader -Runspace $PSDStartLoader 
}

# Copy Cleanup script to C:\Windows\Temp
$CleanupScript = "C:\MININT\Cache\PSDResources\Autopilot\PSDCleanupForAutopilot.ps1"
Copy-Item -path $CleanupScript -Destination "C:\Windows\Temp" -Force

Exit 0

