<#
.SYNOPSIS
    Extracts the Windows Server 2022 Standard index from a Windows Server ISO.
.DESCRIPTION
    Mounts the ISO, locates the Standard index in install.wim, and exports it to a standalone
    WIM file. Update the variables at the top to match your environment.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark / deploymentresearch.com
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2022-04-15 - Initial release
#>

# Script to extract the Windows Server 2022 Standard index from a Windows Server 2022 media.
# Update line 5 - 8 to match your environment

# General parameteers
$ISO = "F:\ISO\Windows Server 2022 (updated November 2021).iso" # Path to Windows Server 2022 media
$WIMPath = "C:\Ref" # Target folder for extracted WIM file containing Windows Server 2022 Standard only
$WIMFile = "$WIMPath\REFWS2022-001.wim" # Exported WIM File
$Edition = "Windows Server 2022 Standard (Desktop Experience)" # Edition to export. Note: If using Evaluation Media, use: Windows Server 2022 Standard Evaluation (Desktop Experience)

# Goal is to have a single index WIM File, so checking if target WIM File exist (if WIM exist, a new index will be appended)
If (Test-path $WIMFile){
    Write-Warning "WIM File: $WimFile does already exist. Rename or delete the file, then try again. Aborting..."
    Break 
}

# ISO Validation
If (-not (Test-path $ISO)){
    Write-Warning "ISO File: $ISO does not exist, aborting..."
    Break 
}

# Mount ISO
Mount-DiskImage -ImagePath $ISO | Out-Null
$ISOImage = Get-DiskImage -ImagePath $ISO | Get-Volume
$ISODrive = [string]$ISOImage.DriveLetter+":"

# Source WIM validation
$SourceWIMFile = "$ISODrive\sources\install.wim"
If (-not (Get-WindowsImage -ImagePath $SourceWIMFile | Where-Object {$_.ImageName -ilike "*$($Edition)"})){
    Write-Warning "WIM Edition: $Edition does not exist in WIM: $SourceWIMFile, aborting..."
    Dismount-DiskImage -ImagePath $ISO | Out-Null
    Break
}

# Export WIM
If (!(Test-path $WIMPath)){ New-Item -Path $WIMPath -ItemType Directory -Force | Out-Null } # Create folder if needed
Export-WindowsImage -SourceImagePath $SourceWIMFile -SourceName $Edition -DestinationImagePath $WIMFile

# Dismount ISO
Dismount-DiskImage -ImagePath $ISO | Out-Null

