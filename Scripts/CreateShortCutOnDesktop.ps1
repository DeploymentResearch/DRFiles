# Sample code to create shortcut on Desktop 

$IconLocation = "$Env:USERPROFILE\Desktop\Icons-Land-Multiple-Smiley-Pirate-Smile.ico"
If (!(test-path $IconLocation)){ Write-warning "Oops, icon file is missing, aborting..."; Break }
$WshShell = New-Object -ComObject "WScript.Shell"
$ShortCut = $WshShell.CreateShortcut("$Env:USERPROFILE\Desktop\Link.lnk")
$ShortCut.TargetPath = 'https://google.com'
$ShortCut.IconLocation = $IconLocation
$ShortCut.Save()

