# Create empty folder for x86 components (not used, but MDT looks for the folder)
$x86Folder = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs"
New-Item -Path $x86Folder -ItemType Directory -Force
