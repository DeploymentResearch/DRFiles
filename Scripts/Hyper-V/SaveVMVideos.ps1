<#
.Synopsis
    Sample script for Deployment Research
    Script will generate videos of the screen from running Hyper-V VMs, useful for troubleshooting and documentation

.DESCRIPTION
    Created: 2023-06-18
    Version: 1.0
     
    Author   : Johan Arwidmark
    Twitter  : @jarwidmark
    Blog     : https://deploymentresearch.com
    LinkedIn : https://www.linkedin.com/in/jarwidmark/ 
 
    Disclaimer: This script is provided "AS IS" with no warranties, confers no rights and 
    is not supported by the author or DeploymentArtist..

.NOTES
    1. Credits to Eric2XU and Ben Armstrong for great sample scripts
    2. Video conversion requires ffmpeg.exe (winget install ffmpeg)
    3. The script requires, and checks for, that all VM names are unique across all hosts

.EXAMPLE
    N/A
#>

$HyperVHosts = @(
    "2PS-ROGUE-010"
    "2PS-ROGUE-011"
    "2PS-ROGUE-012"
    "2PS-ROGUE-013"
    "2PS-ROGUE-014"
    "2PS-ROGUE-015"
    "2PS-ROGUE-016"
    "2PS-ROGUE-017"
    "2PS-ROGUE-018"
    "2PS-ROGUE-019"
    "2PS-ROGUE-020"
)

# Image Type: https://msdn.microsoft.com/en-us/library/system.drawing.imaging.imageformat(v=vs.110).aspx
# Note: While the Bmp format may give you slightly higher image quality, I recommend using the Png format due to smaller file size 
$ImageType = "png"

# Folder on this machine to save images from all Hyper-V Hosts 
# Note: Files will be saved local on each Host first for better performance, and then copied here
$ImagePath = "E:\temp\vmimages"

# Folder to store the created videos (converted from still images)
$VideoPath = "E:\temp\vmvideos"

# The local path on each Hyper-V Host
$LocalImagePath = "C:\temp\vmimages"

# Folder for ffmpeg
$ffmpegEXE = "E:\Setup\ffmpeg\ffmpeg.exe"

# Amount of time to run image capture for each running VM on each Hyper-V Host
$RunTimeInSeconds = 2700

# Amount of time between image capture
$CaptureFrameRate = 2 

# Framerate for resulting video 
$ResultingVideoFrameRate = 10

# Basic validation
If (!(Test-path $ImagePath)){ Write-Warning "$ImagePath does not exist, aborting...";Break}
If (!(Test-path $VideoPath)){ Write-Warning "$VideoPath Path does not exist, aborting...";Break}
If (!(Test-path $ffmpegEXE)){ Write-Warning "$ffmpegEXE Path does not exist, aborting...";Break}

function WriteVMScreenShot  {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ImagePath,

        [Parameter(Mandatory=$true)]
		[string]$ImageType,

        [Parameter(Mandatory=$false)]
        [string]$ImageName,

        [Parameter(Mandatory=$false)]
        [string]$HyperVHost,

        [Parameter(Mandatory=$false)]
        [string]$VMName
    )

	$FinalImageName = "$ImagePath\$ImageName"
    Write-Host $FinalImageName

    $VMCS = Get-WmiObject -ComputerName $HyperVHost -Namespace root\virtualization\v2 -Class Msvm_ComputerSystem -Filter "ElementName='$($VMName)'" 

	# Get the resolution of the screen at the moment
	$video = $VMCS.GetRelated("Msvm_VideoHead")
	$xResolution = $video.CurrentHorizontalResolution[0]
	$yResolution = $video.CurrentVerticalResolution[0]

	#(get-VMScreenShot $VMCS $xResolution $yResolution).Save($FinalImageName,$ImageType)

    # Get VM Object
	$VMMS = Get-WmiObject -ComputerName $HyperVHost -Namespace root\virtualization\v2 -Class Msvm_VirtualSystemManagementService 

    # Get screenshot
    $image = $VMMS.GetVirtualSystemThumbnailImage($VMCS, $xResolution, $yResolution).ImageData

    # Transform into bitmap
    $BitMap = New-Object System.Drawing.Bitmap -Args $xResolution,$yResolution,Format16bppRgb565
    $Rect = New-Object System.Drawing.Rectangle 0,0,$xResolution,$yResolution
    $BmpData = $BitMap.LockBits($Rect,"ReadWrite","Format16bppRgb565")
    [System.Runtime.InteropServices.Marshal]::Copy($Image, 0, $BmpData.Scan0, $BmpData.Stride*$BmpData.Height)
    $BitMap.UnlockBits($BmpData)

    # Save to file
    $BitMap.Save($FinalImageName,$ImageType)


}

# Build list of VMs on all Hyper-V Hosts
$VMInfo = @()
foreach ($Server in $HyperVHosts) {
    $VMs = Get-VM -ComputerName $Server 
        foreach ($VM in $VMs){
            # Build array with VM info
            $VMInfo += [pscustomobject]@{ Server = $Server; VMName = $VM.Name }
        }
}

# Check for VM duplicates, abort if they exist
$a = ($VMInfo).VMName
$b = $a | select –unique
$Result = Compare-object –referenceobject $b –differenceobject $a
If ($Result){
    
    foreach ($Item in $Result) {
        Write-Warning "VM: $($Item.InputObject) is a duplicate" 
    }
    Write-Warning "Duplicate VM Names exist, aborting..."
    Break
}


# Create local images folder on each Hyper-V Host (for better performance and higher framerates)
Invoke-Command -Command { New-Item -Path $using:LocalImagePath -ItemType Directory -Force } -ComputerName $HyperVHosts

# Start saving images from the running VMs
# Due to ffmpeg limitations in the Windows build, this script have to generate names in a sequence per VM
$WriteVMScreenShotDefinition = "function WriteVMScreenShot { ${function:WriteVMScreenShot} }"
foreach ($Server in $HyperVHosts) {
    Invoke-Command -ArgumentList $WriteVMScreenShotDefinition -ComputerName $Server -ScriptBlock {
        Param( $WriteVMScreenShotDefinition )

        . ([ScriptBlock]::Create($WriteVMScreenShotDefinition))

        # Script Assemblies
        Add-Type -AssemblyName "System.Drawing"

        # Get all running VMs
        $VMs = Get-VM | Where-Object { $_.State -ne 'Off' }

        If ($VMs){
            # Running VMs found
        }
        Else {
            # No running VMs found, aborting...
            Break
        }
    
        $RunUntil = (Get-Date).AddSeconds($using:RunTimeInSeconds)
        $StartingSequenceNumber = 1
        While ($RunUntil -gt (Get-Date)) {
            foreach ($VM in $VMs){
                $VMName = $VM.VMName
                $ImageName = $VMName + "_" + ($StartingSequenceNumber | ForEach-Object{"{0:D5}" -f $_}) + ".$using:ImageType"
                write-Host "About to run: writeVMScreenShot -ImagePath $using:LocalImagePath -ImageName "$ImageName" -ImageType $using:ImageType -HyperVHost Localhost -VMName $VMName"
                writeVMScreenShot -ImagePath $using:LocalImagePath -ImageName "$ImageName" -ImageType $using:ImageType -HyperVHost Localhost -VMName  $VMName 
            }
            $SleepTime = [Math]::Round(1000 / $CaptureFrameRate)
            Start-Sleep -Milliseconds $SleepTime

            # Increase sequence number
            $StartingSequenceNumber++
        }
    } -AsJob
}



# Wait until all still images has been capture (wait time defined by the $RunTimeInSeconds variable)
Write-Host "Entering wait cycle..."
Start-Sleep -Seconds $RunTimeInSeconds

break
# Copy the still images from each Hyper-V host to this machine
foreach ($Server in $HyperVHosts) {
    # Convert the local image path to a UNC path
    $UNCToLocalPath = "\\$Server\$($LocalImagePath.replace(':','$'))"
    Copy-Item -Path $UNCToLocalPath\* -Destination $ImagePath
}

# Create one video per VM (from set of VM images)
foreach ($VM in $VMInfo){
    $VMName = $VM.VMName
    Set-Location $ImagePath
    If (Test-Path "$ImagePath\$($VMName)_00001.$imageType"){
        Start-Process cmd.exe -ArgumentList "/c $ffmpegEXE -framerate $ResultingVideoFrameRate -i $ImagePath\$($VMName)_%05d.$imageType $VideoPath\$VMName.mp4 -y" -Wait
    }
    Else {
        Write-warning "No image sequence found for VM: $VMName"
    }
        
}
Write-Host "Videos are saved in the  $VideoPath folder"

# Optional cleanup when testing
# Stop the running jobs
# Get-Job | Where-Object { $_.State -eq 'Running' } | Stop-Job

# Optional cleanup of uploaded/copied images
# If (test-Path $ImagePath) { Remove-item $ImagePath\* -Force }

# Optional cleanup of locally captured images
# Invoke-Command -Command { Remove-Item -Path $using:LocalImagePath -Recurse -Force } -ComputerName $HyperVHosts