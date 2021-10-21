$WimFile = Get-ChildItem Source.wim
$MountPath = "C:\Users\Public\mount_" + $WimFile.BaseName
$ScriptDir = split-path -parent $MyInvocation.MyCommand.Path

# Mount the WIM file
New-Item -Path $MountPath -ItemType Directory
Mount-WindowsImage -ImagePath $wimFile.FullName -Index 1 -Path $mountPath

# Install the app
$SetupFile = "msiexec"
$SetupSwitches = "/i $MountPath\snagit.msi /q"
Start-Process -FilePath $SetupFile -ArgumentList $SetupSwitches -NoNewWindow -Wait
    
# Dismount the WIM file and Remove mount folder
Dismount-WindowsImage -Path $MountPath -Discard
Remove-Item -Path $MountPath -Force