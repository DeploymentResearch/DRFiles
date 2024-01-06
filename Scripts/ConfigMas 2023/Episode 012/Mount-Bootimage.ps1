# Set Variables
$MountPath = "E:\Mount"
$WimFile = "E:\Sources\OSD\Boot\Zero Touch WinPE 11 x64\WinPE.wim"

# Mount the boot image
Mount-WindowsImage -ImagePath $WimFile -Path $MountPath -Index 1

# Do Whatever

# Unmount the Boot Image WIM file and save the changes
Dismount-WindowsImage -Path $MountPath -Save 
