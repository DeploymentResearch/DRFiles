@echo off
setlocalecho Delete rollback information ...
cd /d %~d0%\$GetCurrent\SafeOS
rundll32.exe GetCurrentOOBE.dll,GetCurrentOOBE_UpdateRollbackReason
rmdir /s /q %~d0%\$GetCurrent\media
rmdir /s /q %~d0%\$GetCurrent\Customization
PartnerSetupComplete.cmd > ..\Logs\PartnerSetupCompleteResult.log
