# Install the Self-Signed Root Cert 
#$RootCert = "\\MDT03\PSD-0227$\PSDResources\Certificates\PSDCert.cer"
#Import-Certificate -FilePath $RootCert -CertStoreLocation Cert:\LocalMachine\Root

# Get BranchCache Cache Info
Get-BCDataCache
$CurrentActiveCacheSizeInGB = [math]::Round((Get-BCDataCache).CurrentActiveCacheSize/1GB,3)
Write-Host "Current Active BranchCache size is: $CurrentActiveCacheSizeInGB GB"

# Clear BranchCache cache
#Clear-BCCache -Force

# Set Generic Variables and download URL
$url = "https://mdt03.corp.viamonstra.com/psdproduction/boot/LiteTouchPE_x64.wim"
$BCMon = "C:\Setup\BCMon\BCMon.Net.exe"

# Verify the BCMon.exe exists
If (!(Test-Path "$BCMon")){
    Write-Warning "$(Split-Path -Path $BCMon -Leaf) not found in $(Split-Path -Path $BCMon). Aborting script!" 
    Break
}

$BCDownloadPath = "C:\BCTemp"
New-Item -Path $BCDownloadPath -ItemType Directory -Force | Out-Null 
$CIDownLoadPath = "C:\BCCITemp"
New-Item -Path $CIDownLoadPath -ItemType Directory -Force | Out-Null 

$Username = 'MDT03\MDT_BA'
$Password = 'CHANGE_ME'
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$pass

# Download the boot image into the BranchCache cache
Start-BitsTransfer -Source $URL -Destination C:\BCTemp -Credential $cred -Authentication Ntlm
Remove-Item "C:\BCTemp\*" -Force

# Download CI from FromSingleURL
Start-Process cmd.exe -ArgumentList "/k `"$BCMon`" CI Download FromSingleURL $URL --folder $CIDownLoadPath --bcversion 2.0" -Wait

# Query local BranchCache cache for content from downloaded CI
$CIFileName = "$CIDownLoadPath\LiteTouchPE_x64.wim.ci"
Start-Process cmd.exe -ArgumentList "/k `"$BCMon`" CI Query $CIFileName"
