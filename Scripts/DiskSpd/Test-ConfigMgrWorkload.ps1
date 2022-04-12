#
# Get Diskspd.exe at https://aka.ms/diskspd
#

# Set Variables
$DiskSpdPath = "C:\Setup\Diskspd"
$ExportPath = "C:\Setup\Diskspd"
$ExportFile = "$ExportPath\$($Env:ComputerName)_diskspd_results.csv"

# Get all disk volumes
$Volumes = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3"
$TestFileSize = "20" # GB
$FirstRunDuration = 60 # Seconds
$SecondRunDuration = 300 # Seconds

# Copy Diskspd.exe to C:\Windows\Temp
Copy-Item $DiskSpdPath\diskspd.exe "C:\Windows\Temp"
Set-Location "C:\Windows\Temp"

# Remove previous results
If (Test-path $ExportFile){Remove-Item -Path $ExportFile -Force }

foreach ($Volume in $Volumes){
    $Testfile = "$($Volume.DeviceID)\Testfile.dat"

    # Check for free space. Minimum is size specified in TestFileSize plus 10 GB
    [int]$TestFileSizeInt = [convert]::ToInt32($TestFileSize, 10)
    $NeededFreeSpace = [int]$TestFileSizeInt + 10 #GigaBytes
    $Disk = Get-wmiObject Win32_LogicalDisk -Filter "DeviceID='$($Volume.DeviceID)'" 
    $FreeSpace = [MATH]::ROUND($disk.FreeSpace /1GB)
    Write-Host "Checking free space on $($Volume.DeviceID) Minimum is $NeededFreeSpace GB"

    if($FreeSpace -lt $NeededFreeSpace){
    
        Write-Warning "Oupps, you need at least $NeededFreeSpace GB of free disk space"
        Write-Warning "Available free space on $($Volume.DeviceID) is $FreeSpace GB"
        Write-Warning "Skipping this volume..."
    }
    Else{
        # All good, start the tests
        $TestFileSizeInDiskspdFormat = $TestFileSize+"G"

        # Read test
        Write-Host "Starting first 100% read test on $($Volume.DeviceID)"
        $Result = .\DiskSpd.exe -r -w0 -t8 -o8 -b64K -c"$TestFileSizeInDiskspdFormat" -d"$FirstRunDuration" -h -L $Testfile

        # Format and output result
        foreach ($line in $result) {if ($line -like "total:*") { $total=$line; break } }
        foreach ($line in $result) {if ($line -like "avg.*") { $avg=$line; break } }
        $mbps = $total.Split("|")[2].Trim()
        $iops = $total.Split("|")[3].Trim()
        $latency = $total.Split("|")[4].Trim()
        $cpu = $avg.Split("|")[1].Trim()

        $TestName = "Read Test 01"
        $Hash = New-Object System.Collections.Specialized.OrderedDictionary
        $Hash.Add("ComputerName",$Env:ComputerName)
        $Hash.Add("Test",$TestName)
        $Hash.Add("Disk",$Volume.DeviceID)
        $Hash.Add("IOPS",$iops)
        $Hash.Add("Mbps",$mbps)
        $Hash.Add("Latency",$latency)
        $Hash.Add("CPU",$cpu)

        $CSVObject = New-Object -TypeName psobject -Property $Hash
        $CSVObject | Export-Csv -Path $ExportFile -NoTypeInformation -Append

        Start-Sleep -Seconds 5
        Write-Host "Starting second 100% read test on $($Volume.DeviceID)"
        $Result = .\DiskSpd.exe -r -w0 -t8 -o8 -b64K -c"$TestFileSizeInDiskspdFormat" -d"$SecondRunDuration" -h -L $Testfile

        # Format and output result
        foreach ($line in $result) {if ($line -like "total:*") { $total=$line; break } }
        foreach ($line in $result) {if ($line -like "avg.*") { $avg=$line; break } }
        $mbps = $total.Split("|")[2].Trim()
        $iops = $total.Split("|")[3].Trim()
        $latency = $total.Split("|")[4].Trim()
        $cpu = $avg.Split("|")[1].Trim()

        $TestName = "Read Test 02"
        $Hash = New-Object System.Collections.Specialized.OrderedDictionary
        $Hash.Add("ComputerName",$Env:ComputerName)
        $Hash.Add("Test",$TestName)
        $Hash.Add("Disk",$Volume.DeviceID)
        $Hash.Add("IOPS",$iops)
        $Hash.Add("Mbps",$mbps)
        $Hash.Add("Latency",$latency)
        $Hash.Add("CPU",$cpu)

        $CSVObject = New-Object -TypeName psobject -Property $Hash
        $CSVObject | Export-Csv -Path $ExportFile -NoTypeInformation -Append

        # Write test
        Write-Host "Starting first 100% write test on $($Volume.DeviceID)"
        $Result = .\DiskSpd.exe -r -w100 -t8 -o8 -b64K -c"$TestFileSizeInDiskspdFormat" -d"$FirstRunDuration" -h -L $Testfile

        # Format and output result
        foreach ($line in $result) {if ($line -like "total:*") { $total=$line; break } }
        foreach ($line in $result) {if ($line -like "avg.*") { $avg=$line; break } }
        $mbps = $total.Split("|")[2].Trim()
        $iops = $total.Split("|")[3].Trim()
        $latency = $total.Split("|")[4].Trim()
        $cpu = $avg.Split("|")[1].Trim()

        $TestName = "Write Test 01"
        $Hash = New-Object System.Collections.Specialized.OrderedDictionary
        $Hash.Add("ComputerName",$Env:ComputerName)
        $Hash.Add("Test",$TestName)
        $Hash.Add("Disk",$Volume.DeviceID)
        $Hash.Add("IOPS",$iops)
        $Hash.Add("Mbps",$mbps)
        $Hash.Add("Latency",$latency)
        $Hash.Add("CPU",$cpu)

        $CSVObject = New-Object -TypeName psobject -Property $Hash
        $CSVObject | Export-Csv -Path $ExportFile -NoTypeInformation -Append

        Start-Sleep -Seconds 5
        Write-Host "Starting second 100% write test on $($Volume.DeviceID)"
        $Result = .\DiskSpd.exe -r -w100 -t8 -o8 -b64K -c"$TestFileSizeInDiskspdFormat" -d"$SecondRunDuration" -h -L $Testfile

        # Format and output result
        foreach ($line in $result) {if ($line -like "total:*") { $total=$line; break } }
        foreach ($line in $result) {if ($line -like "avg.*") { $avg=$line; break } }
        $mbps = $total.Split("|")[2].Trim()
        $iops = $total.Split("|")[3].Trim()
        $latency = $total.Split("|")[4].Trim()
        $cpu = $avg.Split("|")[1].Trim()

        $TestName = "Write Test 02"
        $Hash = New-Object System.Collections.Specialized.OrderedDictionary
        $Hash.Add("ComputerName",$Env:ComputerName)
        $Hash.Add("Test",$TestName)
        $Hash.Add("Disk",$Volume.DeviceID)
        $Hash.Add("IOPS",$iops)
        $Hash.Add("Mbps",$mbps)
        $Hash.Add("Latency",$latency)
        $Hash.Add("CPU",$cpu)

        $CSVObject = New-Object -TypeName psobject -Property $Hash
        $CSVObject | Export-Csv -Path $ExportFile -NoTypeInformation -Append

        Remove-Item $Testfile
    
    }

}

