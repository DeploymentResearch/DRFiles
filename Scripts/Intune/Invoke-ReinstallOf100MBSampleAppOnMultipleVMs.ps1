# Set credentials (Use local admin account)
$Username = '.\Administrator'
$Password = 'P@ssw0rd'
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$pass

# Get Multiple VMS
$VMS = Get-VM -Name DA-Intune* | Sort-Object Name

# Clear the DO Cache on all machines
foreach ($VM in $VMs){

    $VMName = $VM.VMName
    # Check if VMS is running
    $VMStatus = (Get-VM -Name $VMName).State
    
    If ($VMStatus -eq "Running"){
        Invoke-Command -VMName $VMName { Delete-DeliveryOptimizationCache -Force } -Credential $Cred
    }  
}


# Start download on each VM
foreach ($VM in $VMs){

    $VMName = $VM.VMName
    # Check if VMS is running
    $VMStatus = (Get-VM -Name $VMName).State
    Write-Host "Working on VM: $VMName" 
    
    If ($VMStatus -eq "Running"){

        # Enable Guest Services (required for Copy-VMFile, and not enabled by default)
        Enable-VMIntegrationService -Name 'Guest Service Interface' –VMName $VMName 
    
        # Copy StifleR Client scripts (overwrite if exist)
        Copy-VMFile -Name $VMName -SourcePath "\\CM01\Demo\_LabEnvironment\Sripts\Invoke-ReinstallOf100MBSampleApp.ps1" –DestinationPath "C:\Windows\Temp" -FileSource Host –CreateFullPath -Force

        Invoke-Command -VMName $VMName { Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force } -Credential $Cred
        Invoke-Command -VMName $VMName { C:\Windows\Temp\Invoke-ReinstallOf100MBSampleApp.ps1 } -Credential $Cred
    }  
    #Start-Sleep -Seconds 20
}

Start-Sleep -Seconds 1800

# Get some DO statistics
[System.Collections.ArrayList]$DOInfo = @()
foreach ($VM in $VMs){

    $VMName = $VM.VMName
    # Check if VMS is running
    $VMStatus = (Get-VM -Name $VMName).State

    $ScriptBlock = {
        Get-DeliveryOptimizationStatus | 
            Where-Object { $_.FileId -like "*956e00ed-3da5-4e87-aaa7-ec7a0f06ef41_1" } | 
            Select FileSize, Status, BytesFromHttp, BytesFromPeers, BytesFromCacheServer, BytesFromLanPeers, BytesFromGroupPeers, BytesFromInternetPeers |
            Select -First 1
    }
    
    If ($VMStatus -eq "Running"){
        $Result = Invoke-Command -VMName $VMName -ScriptBlock $ScriptBlock -Credential $Cred 

        $obj = [PSCustomObject]@{

            # Add values to arraylist
            ComputerName  =  $VMName.SubString(0,13)
            FileSize = $Result.FileSize
            Status = $Result.Status
            BytesFromHttp = $Result.BytesFromHttp
            BytesFromPeers = $Result.BytesFromPeers
            BytesFromCacheServer = $Result.BytesFromCacheServer
            BytesFromLanPeers = $Result.BytesFromLanPeers
            BytesFromGroupPeers = $Result.BytesFromGroupPeers
            BytesFromInternetPeers = $Result.BytesFromInternetPeers
        }

        # Add all the values
        $DOInfo.Add($obj)|Out-Null

    }  
}

$NumberOfDownloads = ($DOInfo | Measure-Object).Count
$NumberOfCachingClients = ($DOInfo.Status | Group-Object -NoElement | Where-Object { $_.Name -eq "Caching" }).Count
$TotalBytesFromHttp = ($DOInfo.BytesFromHttp | Measure-Object -Sum).Sum
$TotalBytesFromPeers = ($DOInfo.BytesFromPeers | Measure-Object -Sum).Sum
$TotalBytesFromCacheServer = ($DOInfo.BytesFromCacheServer | Measure-Object -Sum).Sum
$TotalBytesFromLanPeers = ($DOInfo.BytesFromLanPeers | Measure-Object -Sum).Sum
$TotalBytesFromGroupPeers = ($DOInfo.BytesFromGroupPeers | Measure-Object -Sum).Sum
$TotalBytesFromInternetPeers = ($DOInfo.BytesFromInternetPeers | Measure-Object -Sum).Sum

$DOEfficiency = $TotalBytesFromPeers/($TotalBytesFromHttp + $TotalBytesFromPeers)
$DOEfficiency = $([math]::Round(($DOEfficiency*100),2))

Write-Host "Total bytes from CDN and Cache Server: $TotalBytesFromHttp, peers: $TotalBytesFromPeers"
Write-Host "DO Efficiency is: $DOEfficiency percent"


        