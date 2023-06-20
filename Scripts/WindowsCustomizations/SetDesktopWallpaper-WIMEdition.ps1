[CmdletBinding()]
Param(
    [Parameter(Position=0,mandatory=$true)]
    [string] $WindowsFolder
)

# Extract WIM file to X:\Windows\Temp\DesktopWallpaper
$WallpaperPath = "X:\Windows\Temp\DesktopWallpaper"
$WallpaperWIM = "$PSScriptRoot\desktopwallpaper.wim"
New-Item -Path $WallpaperPath -ItemType Directory -Force
& DISM.exe /Apply-Image /ImageFile:$WallpaperWIM /Index:1 /ApplyDir:$WallpaperPath

# Replace Windows default wallpaper image
$fileName = Join-Path $WindowsFolder "WEB\wallpaper\Windows\img0.jpg"
takeown /f $fileName
icacls $fileName /Grant 'System:(F)'
Remove-Item $fileName
Copy-Item -Path "$WallpaperPath\img0.jpg" -Destination $fileName

# replace Windows 4k wallpaper images 
$folderName = Join-Path $WindowsFolder "WEB\4K\Wallpaper\Windows"
takeown /f "$folderName\*.*"
icacls "$folderName\*.*" /Grant 'System:(F)'
Remove-Item "$folderName\*.*"
Copy-Item -Path "$WallpaperPath\4k\*.*" -Destination $folderName