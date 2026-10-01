# Load registry hive
reg.exe load HKLM\TempUser "C:\Users\Default\NTUSER.DAT" | Out-Host

# Stop Start menu from opening on first logon
reg.exe add "HKLM\TempUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v StartShownOnUpgrade /t REG_DWORD /d 1 /f | Out-Host

# Cleanup and unload registry hive
[gc]::collect()
Start-Sleep -Seconds 5
reg.exe unload HKLM\TempUser | Out-Host
