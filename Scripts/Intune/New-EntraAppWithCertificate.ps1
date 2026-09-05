<#
.SYNOPSIS
    Creates a self-signed certificate for Entra ID app authentication.
.DESCRIPTION
    Generates the certificate, exports the public key for upload to the app registration, and
    shows how to connect to Graph using the certificate thumbprint.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark / deploymentresearch.com
    Credits: Reference: Christian Frohn, christianfrohn.dk
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2026-04-14 - Initial release
#>

#Thank you Christian Frohn for the reference: https://www.christianfrohn.dk/2022/04/23/connect-to-microsoft-graph-with-powershell-using-a-certificate-and-an-azure-service-principal/

#Create a self-signed certificate to use for authentication.
$CN = "Intune PowerShell - Custom" #Name of your cert. I named it the same as my Entra app registration
$cert = New-SelfSignedCertificate -Subject "CN=$CN" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature -NotAfter (Get-Date).AddYears(5)
 
#Store the thumbprint value
$Thumbprint = $Cert.Thumbprint
 
#Export certificate to users download folder. Use this to upload to Entra.
Get-ChildItem Cert:\CurrentUser\my\$Thumbprint | Export-Certificate -FilePath $env:USERPROFILE\Downloads\$($CN).cer

#Connecting after certificate has been uploaded to Entra App Registration
$AppID = ""
$TenantID = ""

Connect-MgGraph -ClientId $AppID -TenantId $TenantID -CertificateThumbprint $Thumbprint
