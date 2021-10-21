# Creating a drive wim package manually
$ApplicationsPath = "\\cm01\Sources\P2P Test Packages\300 MB Multiple Files"
$TempSource = "E:\Temp\TempSource"
$WimPathSource = "E:\Temp"

Copy-Item -Path $ApplicationsPath -Destination $TempSource -Recurse

New-WindowsImage -CapturePath $TempSource -ImagePath "$WimPathSource\Source.wim" -Name "Source"