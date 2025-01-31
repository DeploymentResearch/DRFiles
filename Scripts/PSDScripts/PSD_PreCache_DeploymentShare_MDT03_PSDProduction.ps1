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
$DeployRoot = "https://mdt03.corp.viamonstra.com/psdproduction"
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

$PreCache = $True
$CIDownload = $False
$Logfile = "C:\Windows\Temp\PSD_PreCache_DeploymentShare.log"

# Delete any existing logfile if it exists
If (Test-Path $Logfile){Remove-Item $Logfile -Force -ErrorAction SilentlyContinue -Confirm:$false}

Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
   )

   $TimeGenerated = $(Get-Date -UFormat "%D %T")
   $Line = "$TimeGenerated : $Message"
   Add-Content -Value $Line -Path $LogFile -Encoding Ascii

}

$request = [System.Net.WebRequest]::Create($DeployRoot)
$topUri = new-object system.uri $DeployRoot
$prefixLen = $topUri.LocalPath.Length

$request.UserAgent = "PSD"
$request.Method = "PROPFIND"
$request.ContentType = "text/xml"
$request.Headers.Set("Depth", "infinity")
$request.Credentials = $Cred

$response = $request.GetResponse()

$sr = new-object System.IO.StreamReader -ArgumentList $response.GetResponseStream(),[System.Encoding]::Default
[xml]$xml = $sr.ReadToEnd()		

# Get the list of files and folders, to make this easier to work with
$results = @()
#$xml.multistatus.response | Where-Object { $_.href -ine $url } | foreach {
$xml.multistatus.response | foreach {
    
    #[xml]$InnerXML = $_.InnerXML
    #break
    #$SizeBytes = $InnerXML.SelectSingleNode("getcontentlength")

    $obj = [PSCustomObject]@{
        href = $_.href
    }
    $results += $obj
}

# Specify files and folders to exclude
$FilesAndFoldersToExclude = @(
    "$DeployRoot/Backup"
    "$DeployRoot/web.config"
    "$DeployRoot/audit.log"
    "$DeployRoot/Out-of-Box%20Drivers"
    "$DeployRoot/PSDUpdateExit.log"
    "$DeployRoot/Operating%20Systems\W11-X64-22H2-OSDToolkit"
)

Foreach ($link in $results) {

    $URL = $link.href
    $VerifiedURL = $false

    #Write-Log "Processing $URL"

    # Do some filtering

    If($URL.EndsWith('/')){
        Write-Log "URL is a folder, skipping processing of $URL" 
        Write-Log "-----------------------------------------------------"
    }
    Else{
        # Check against exlusion list
        $Excluded = $false
        foreach ($ExcludedItem in $FilesAndFoldersToExclude){
            If ($URL -like "*$ExcludedItem*"){
                Write-Log "Excluded URL, skipping processing of $URL" 
                Write-Log "-----------------------------------------------------"
                $Excluded = $true
            }

        }
        If ($Excluded -eq $false){
            Write-Log "All OK. processing $URL"
            $VerifiedURL = $true

        }
    }
    
    If ($VerifiedURL -eq $true){
        
        # Assume link to a valid file
       
        try { 
            [int64]$SizeBytes = (Invoke-WebRequest $URL -Method Head -Credential $Cred).Headers.'Content-Length' 
        }
        catch{
            Write-Log "Error: $_.Exception.Response.StatusCode.Value__ " 
        }

        $SizeMB = [math]::Round(($SizeBytes/1MB),3)
        Write-Log "Only Process files larger then 64 kb, checking size..."
        
        If ($SizeBytes -gt 65536){
        Write-Log "The file on the server is: $SizeBytes bytes ($SizeMB MB). All OK."
        #Write-Log "Generating CI for $URL"
            
            #$BCMonResult = cmd /c "`"$BCMonPath\BCmon.exe`" /GenerateCI /URL:$URL /Username:$Username /Password:$Password"
            #$ContentEncoding = $BCMonResult | Select-String -Pattern "ContentEncoding is peerdist with"

            # Log ContentEncoding if we had it enabled (above section)
            If ($ContentEncoding){
                Write-Log "ContentEncoding result from BCMon: $ContentEncoding"
            }

            If ($CIDownload -eq $true){
            
                Start-Process cmd.exe -ArgumentList "/c `"$BCMon`" CI Download FromSingleURL $URL --folder $CIDownLoadPath --bcversion 2.0"  -Wait
                If (Test-Path $CIDownLoadPath){Remove-Item "$CIDownLoadPath\*" -Force}
            }

            If ($PreCache -eq $true){
                # download the file
                Write-Log "PreCache is enabled, downloading $URL"
                write-host "Downloading $URL"

                $Job = Start-BitsTransfer -Source $URL -Destination $BCDownloadPath -Credential $cred -Authentication Ntlm -Priority Foreground -Asynchronous
                while (($Job.JobState -eq "Transferring") -or ($Job.JobState -eq "Connecting")) {
                    If ($Job.JobState -eq "Connecting"){
                        #Write-Host "BITS Job state is: $($Job.JobState)"
                    }
                    If ($Job.JobState -eq "Transferring"){
                        Write-Host "BITS Job state is: $($Job.JobState). $($Job.BytesTransferred) bytes transferred of $($Job.BytesTotal) total"
                    }

                    Start-Sleep -second 1
                } 
                Switch($Job.JobState){
                    "Transferred" {
                        Write-Host "BITS Job state is: $($Job.JobState). $($Job.BytesTransferred) bytes transferred of $($Job.BytesTotal) total"
                        write-Log "Downloaded $URL"
                        Write-Log "BITS Job state is: $($Job.JobState). $($Job.BytesTransferred) bytes transferred of $($Job.BytesTotal) total"
                        Write-Log "----------------------------------------------------------"
                        Complete-BitsTransfer -BitsJob $Job
                        }
                    "Error" {$Job | Format-List } # List the errors.
                    default {Write-Host "Default action"} #  Perform corrective action.
                }


                

                #Start-BitsTransfer -Source $URL -Destination "C:\BCTemp" -Credential $cred -Authentication Ntlm -Priority Foreground
                # Delete the file after download, its already in the cache
                
                If (Test-Path $BCDownloadPath){Remove-Item "$BCDownloadPath\*" -Force}
                $CurrentSizeOnDiskAsBytes = (Get-BCDataCache).CurrentSizeOnDiskAsNumberOfBytes
                $CurrentSizeOnDiskAsMB = [math]::Round(($CurrentSizeOnDiskAsBytes/1MB),1)
                Write-Log "BranchCache size on disk is $((Get-BCDataCache).CurrentSizeOnDiskAsNumberOfBytes) bytes ($CurrentSizeOnDiskAsMB MB)"
            }


        }
        Else{
            Write-Log "The file on the server is: $SizeBytes bytes ($SizeMB MB). Skipping."
        }

        Write-Log "--------------------------------------------------------------------"
    }

}
