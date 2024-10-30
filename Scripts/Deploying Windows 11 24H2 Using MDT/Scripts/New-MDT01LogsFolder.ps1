#Requires -RunAsAdministrator

# Create and share the Logs folder
New-Item -Path E:\Logs -ItemType directory
New-SmbShare –Name Logs$ –Path E:\Logs -ChangeAccess EVERYONE
icacls E:\Logs /grant '"MDT_BA":(OI)(CI)(M)'
