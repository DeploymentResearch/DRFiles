# Start basic logging
Start-transcript -path X:\Windows\Temp\PrestartTranscript.log

# Wait for environment to be ready
Start-Sleep -Seconds 2

If ($TSEnv.Value("OSDComputerName")){
    $Null = New-Item -Path HKLM:\SOFTWARE\ViaMonstra -ItemType Directory -Force
    $Null = New-ItemProperty -Path HKLM:\SOFTWARE\ViaMonstra -Name ComputerName -PropertyType String -Value $TSEnv.Value("OSDComputerName") -Force
}
ElseIf ($TSEnv.Value("_SMSTSMachineName")){
    $Null = New-Item -Path HKLM:\SOFTWARE\ViaMonstra -ItemType Directory -Force
    $Null = New-ItemProperty -Path HKLM:\SOFTWARE\ViaMonstra -Name ComputerName -PropertyType String -Value $TSEnv.Value("_SMSTSMachineName") -Force
}
Else {
    # Using hostname
    $Hostname = [System.Net.Dns]::GetHostName().ToUpper()
    $Null = New-Item -Path HKLM:\SOFTWARE\ViaMonstra -ItemType Directory -Force
    $Null = New-ItemProperty -Path HKLM:\SOFTWARE\ViaMonstra -Name ComputerName -PropertyType String -Value $Hostname -Force
}

# Check for Media Expiry Value
If ($TSEnv.Value("_SMSTSMEDIAEXPIRE")){
    # Calculate Media Expiry Value
    [int64]$p1 = ($TSEnv.Value("_SMSTSMEDIAEXPIRE") -split ";")[0]
    [int64]$p2 = ($TSEnv.Value("_SMSTSMEDIAEXPIRE") -split ";")[1]
    [int64]$p = ($p1 -shl 32) + $p2
    $MediaExpiryDate = [DateTime]::FromFileTimeUtc($p).ToString("MM-dd-yyyy")
    #Write-Host "P1 is $p1"
    #Write-Host "P2 is $p2"
    $Null = New-ItemProperty -Path HKLM:\SOFTWARE\ViaMonstra -Name MediaExpiryDate -PropertyType String -Value $MediaExpiryDate -Force
}
Else {
    $Null = New-ItemProperty -Path HKLM:\SOFTWARE\ViaMonstra -Name MediaExpiryDate -PropertyType String -Value "No Expiry Date Defined in Media" -Force
}

& .\Bginfo64.exe .\Media.bgi /timer:0 /NOLICPROMPT /SILENT

# Stop logging
Stop-Transcript