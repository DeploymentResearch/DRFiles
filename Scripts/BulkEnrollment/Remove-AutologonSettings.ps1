$RegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Set-ItemProperty $RegistryPath 'AutoAdminLogon' -Value "0" -Type String 
Set-ItemProperty $RegistryPath 'AutoLogonCount' -Value "0" -Type String 
Set-ItemProperty $RegistryPath 'DefaultUsername' -Value "" -type String 
Set-ItemProperty $RegistryPath 'DefaultDomainName' -Value "VIAMONSTRA" -type String
Set-ItemProperty $RegistryPath 'DefaultPassword' -Value "" -type String
Set-ItemProperty $RegistryPath 'ForceAutoLogon' -Value "0" -type String
Set-ItemProperty $RegistryPath 'DisableCAD' -Value "0" -type Dword