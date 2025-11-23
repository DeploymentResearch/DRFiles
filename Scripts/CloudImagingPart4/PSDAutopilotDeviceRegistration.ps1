<#
.SYNOPSIS
    Client-Side script for Cloud OS Deployment, Part 4
    
.DESCRIPTION
    Uploads Autopilot hardware hash, computer name, and Intune group info to a RestPS web service
	Waits until the device is imported and assigned to an Autopilot profile

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
    1.0.3
    Released: 2025-11-16
    Change history:
      1.0.3 - 2025-11-16 - Updated to remove need for long running REST API calls (having client the poll update status instead)
      1.0.2 - 2025-10-01 - Updated to use new start loader
      1.0.1 - 2021-09-10 - Integration release for the PSD Cloud OS Deployment solution
      1.0.0 - 2020-05-12 - Initial release
#>

# Update PowerShell modules path with PSD modules
$ModulePath = "C:\MININT\Cache\Tools\Modules"
$env:PSModulePath += ";$ModulePath"

# Load core modules
#Import-Module PSDUtility -Verbose:$false
Import-Module PSDStartLoader -Global -Force -Verbose:$false

$LogFile = "C:\Windows\Temp\SPSDAutopilotDeviceRegistration.log"

# Standalone logging function (no PSD dependencies)
function Write-Log {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        $Message,
        [Parameter(Mandatory=$false)]
        $ErrorMessage,
        [Parameter(Mandatory=$false)]
        $Component = "Script",
        [Parameter(Mandatory=$false)]
        [int]$Type
    )
    <#
    Type: 1 = Normal, 2 = Warning (yellow), 3 = Error (red)
    #>
   $Time = Get-Date -Format "HH:mm:ss.ffffff"
   $Date = Get-Date -Format "MM-dd-yyyy"
   if ($ErrorMessage -ne $null) {$Type = 3}
   if ($Component -eq $null) {$Component = " "}
   if ($Type -eq $null) {$Type = 1}
   $LogMessage = "<![LOG[$Message $ErrorMessage" + "]LOG]!><time=`"$Time`" date=`"$Date`" component=`"$Component`" context=`"`" type=`"$Type`" thread=`"`" file=`"`">"
   $LogMessage.Replace("`0","") | Out-File -Append -Encoding UTF8 -FilePath $LogFile
}


# Install PSD Root CA certificate 
Write-Log -Message "Entering certificate block..."

$CertStoreScope = "LocalMachine" # Location
$CertStoreName  = "Root"
$RootCACertFile = "C:\MININT\Certificates\PSDCert.cer"

# Verify that RootCACertFile exist
If (Test-Path $RootCACertFile){
    Write-Log "Certificate $RootCACertFile found, all OK"
}
Else{
    Write-Log "Certificate $RootCACertFile Not found, aborting..."
    break
}

# Create Object
Write-Log "Creating Certificate store object"
$CertStore = New-Object System.Security.Cryptography.X509Certificates.X509Store $CertStoreName, $CertStoreScope
$Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 

# Import Certificate
$CertStore.Open('ReadWrite')
$Cert.Import($RootCACertFile)
$CertStore.Add($Cert)
$Result = $CertStore.Certificates | Where-Object Subject -EQ $Cert.Subject
$CertStore.Close()

Write-Log -Message "Certificate Subject: $($Result.Subject)"
Write-Log -Message "Certificate Issuer: $($Result.Issuer)"
Write-Log -Message "Certificate Thumbprint: $($Result.Thumbprint)"
Write-Log -Message "Certificate Expire: $($Result.NotAfter)"

# Start the splashscreen in full screen mode (topmost)
#$PSDStartLoader = New-PSDStartLoader -LogoImgPath "C:\MININT\Cache\scripts\powershell.png" -FullScreen
# Open in Window instead, useful for troubleshooting
$PSDStartLoader = New-PSDStartLoader -LogoImgPath "C:\MININT\Cache\scripts\powershell.png"

# wait for UI to loaded on screen
Do{
    Start-Sleep -Milliseconds 300
}
Until($PSDStartLoader.isLoaded)

# Start the progress bar scrolling
Update-PSDStartLoaderProgressBar -Runspace $PSDStartLoader -Status "Gathering device details..." -Indeterminate

# Run Gather
$DeviceInfo = Get-PSDLocalInfo -Passthru

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

$primaryinterface = Get-PSDStartLoaderInterfaceDetails

Update-PSDStartLoaderProgressBar -Runspace $PSDStartLoader -Status "Populating device details..." -PercentComplete 10
# Update UI with device details
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtComputerName -Value $OSDCOMPUTERNAME
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtManufacturer -Value $DeviceInfo.Manufacturer
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtModel -Value $DeviceInfo.Model
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtSerialNumber -Value $DeviceInfo.SerialNumber
#Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtAssetTag -Value $DeviceInfo.assettag

Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtMac -Value $primaryinterface.MacAddress
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtIP -Value $primaryinterface.IPAddress
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtSubnet -Value $primaryinterface.SubnetMask
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtGateway -Value $primaryinterface.GatewayAddresses
Set-PSDStartLoaderElement -Runspace $PSDStartLoader -ElementName txtDHCP -Value $primaryinterface.DhcpServer

Start-Sleep -Seconds 2
Update-PSDStartLoaderProgressBar -Status "Gathering Hardware Hash for device" -Runspace $PSDStartLoader -PercentComplete 20



# Get Autopilot Hardware Hash
$AutopilotOutputFile = "C:\Windows\Temp\AutopilotInfo.csv"
Write-Log "Autopilot result will be saved in $AutopilotOutputFile"
$AutopilotScriptPath = "C:\MININT\Cache\PSDResources\Autopilot\Get-WindowsAutopilotInfo.ps1"
$GetAutoPilotArguments = "$AutopilotScriptPath -OutputFile $AutopilotOutputFile"
Write-Log -Message "About to run the command: $GetAutoPilotArguments"
$GetAutoPilotProcess = Start-Process PowerShell -ArgumentList $GetAutoPilotArguments -NoNewWindow -PassThru -Wait

if(-not($GetAutoPilotProcess.ExitCode -eq 0)){
    Write-Log -Message "Something went wrong running Get-WindowsAutopilotInfo.ps1. Exit code $($GetAutoPilotProcess.ExitCode)"
    Write-Log -Message "Aborting script..."

    Show-PSDInfo -Message "Something went wrong running Get-WindowsAutopilotInfo.ps1. Exit code $($GetAutoPilotProcess.ExitCode). Aborting script..." -Severity Error -OSDComputername $Env:COMPUTERNAME -Deployroot "C:\MININT\CACHE "
    Start-Process PowerShell -Wait
    Break
}

Write-Log -Message "Results saved to $AutopilotOutputFile"

# Log the result 
$AutopilotCSV = Import-Csv $AutopilotOutputFile
$SerialNumber = ($AutopilotCSV | Select -First 1)."Device Serial Number"
Write-Log "Device Serial Number is: $SerialNumber"

# Add ComputerName and IntuneGroup to CSV 
$AutopilotCSV | Add-Member -Type NoteProperty -Name 'ComputerName' -Value $OSDCOMPUTERNAME
$AutopilotCSV | Add-Member -Type NoteProperty -Name 'IntuneGroup' -Value $INTUNEGROUP

# Convert the CSV file to JSON 
Write-Log -Message "Converting the CSV file to JSON"
$AutopilotJSON = $AutopilotCSV | ConvertTo-Json 
Write-Log -Message "JSON object created for computer: $OSDCOMPUTERNAME"

# Workaround for "The underlying connection was closed" error
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

# Add support for servers, proxies, load balancers, or API gateways that don’t handle the 100-Continue handshake correctly.
[System.Net.ServicePointManager]::Expect100Continue = $false

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
$Result = Invoke-RestMethod -Method POST -Uri $Uri -Body $AutopilotJSON -Headers $Headers -ErrorAction Stop
Write-Log "Response from API was $Result"

# Loop and wait for registration completion
$RestPSMethod   = "PSDGetCurrentAutopilotJob"
$RestPSArgument = "jobid=$($Result.id)"
$Uri            = "$RestPSProtocol`://$RestPSServer`:$RestPSPort/$RestPSMethod`?$RestPSArgument"

$TimeoutMinutes = 30
$PollInterval   = 60    # seconds
$Stopwatch      = [System.Diagnostics.Stopwatch]::StartNew()

do {
    try {
        $State = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers

        # if API returns an object with a "status" field
        if ($State -eq 'completed') {
            Write-Log "Job completed after $($Stopwatch.Elapsed.TotalMinutes.ToString('0.0')) minutes."

            Update-PSDStartLoaderProgressBar -Status "Registration successful! Assigned computer name is $OSDCOMPUTERNAME..." -Runspace $PSDStartLoader -PercentComplete 90

            Start-Sleep -Seconds 5
            Update-PSDStartLoaderProgressBar -Status "Starting PSD cleanup..." -Runspace $PSDStartLoader -PercentComplete 100
            # Note the above just notifies the user, the cleanup happens a little bit later, initated from the unattend.xml file.
            break
        }

        # optional: display progress
        Write-Log "[$($Stopwatch.Elapsed.Minutes)m] Current state: $State"
    }
    catch {
        Write-Log "Error checking job state: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds $PollInterval

} while ($Stopwatch.Elapsed.TotalMinutes -lt $TimeoutMinutes)

if ($Stopwatch.Elapsed.TotalMinutes -ge $TimeoutMinutes -and $State.status -ne 'completed') {
    Write-Log "Timed out after $TimeoutMinutes minutes. Last known state: $($State)"
    Update-PSDStartLoaderProgressBar -Status "Registration Timed out after $TimeoutMinutes minutes. Last known state: $($State)" -Runspace $PSDStartLoader -PercentComplete 90
}