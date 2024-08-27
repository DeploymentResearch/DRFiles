# Folder to archive
$BackupPath = "G:\Demo\VMs"

# Create a Zip Archive - Normal compression and Solid
# -mx5 = Normal compression
# -tzip = Zip archive type
# -mmt32 = 32 CPU Threads
$ZipResult = Measure-Command {
    $DestinationPath = "G:\Demo\7ZIP-Archive.zip"
    $7ZipParams = @{
        FilePath = "C:\Program Files\7-Zip\7z.exe"
        ArgumentList = "a `"$($DestinationPath)`" `"$($BackupPath)`" -y -tzip -mx5 -mmt32"
        WindowStyle  = "Hidden"
    }
    $7ZipParams.PassThru = $true
    (Start-Process @7ZipParams).WaitForExit()
}

# Create a 7z Archive - Normal compression
# -mx5 = Normal compression
# -t7z = 7z archive type
# -mmt32 = 32 CPU Threads
$7ZResult = Measure-Command {
    $DestinationPath = "G:\Demo\7ZIP-Archive.7z"
    $7ZipParams = @{
        FilePath = "C:\Program Files\7-Zip\7z.exe"
        ArgumentList = "a `"$($DestinationPath)`" `"$($BackupPath)`" -y -t7z -mx5 -mmt32"
        WindowStyle  = "Hidden"
    }
    $7ZipParams.PassThru = $true
    (Start-Process @7ZipParams).WaitForExit()
}

# Create a ZPAQ Archive - Compression Method 1
$ZPAQResult = Measure-Command {
    $DestinationPath = "G:\Demo\ZPAQ-Archive.zpaq"
    $ZPAQParams = @{
        FilePath = "F:\Setup\ZPAQ\zpaq64.exe"
        ArgumentList = "add $DestinationPath $BackupPath -method 1"
        WindowStyle  = "Hidden"
    }
    $ZPAQParams.PassThru = $true
    (Start-Process @ZPAQParams).WaitForExit()
}

Write-Host "Zip archiving took $([int]$ZipResult.TotalMinutes) minutes"
Write-Host "7z archiving took $([int]$7ZResult.TotalMinutes) minutes"
Write-Host "ZPAQ archiving took $([int]$ZPAQResult.TotalMinutes) minutes"