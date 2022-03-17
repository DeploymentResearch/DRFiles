# Sample script to install a Root CA in WinPE. 
# This script assumes that you have either injected the certificate to the boot WIM image, or copied it down via the Task Sequence.

$RootCACertFile = "X:\Windows\System32\ViaMonstraRootCA.cer"

$Logfile = "X:\Windows\Temp\ImportRootCA.log"
$CertStoreScope = "LocalMachine" # Location
$CertStoreName  = "Root"


Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
   )

   $TimeGenerated = $(Get-Date -UFormat "%D %T")
   $Line = "$TimeGenerated : $Message"
   Add-Content -Value $Line -Path $LogFile -Encoding Ascii

}

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
