# Requires Internet Access, if not, use source
# Note: Scripts reboots
Add-WindowsFeature RDC,File-Services,FS-FileServer,Web-App-Dev,Web-Common-Http,Web-Default-Doc,Web-Dir-Browsing,Web-Filtering,Web-Health,Web-Http-Errors,Web-Http-Logging,Web-ISAPI-Ext,Web-Metabase,Web-Mgmt-Compat,Web-Mgmt-Console,Web-Mgmt-Tools,Web-Performance,Web-Security,Web-Server,Web-Stat-Compression,Web-Static-Content,Web-WebServer,Web-Windows-Auth,Web-WMI,Web-Http-Redirect,Web-Scripting-Tools -Restart


# To be tested
# Add-WindowsFeature Web-Windows-Auth,Web-ISAPI-Ext,Web-Metabase,Web-WMI,BITS,RDC,NET-Framework-Features,Web-Asp-Net,Web-Asp-Net45,NET-HTTP-Activation,NET-Non-HTTP-Activ,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Http-Redirect,Web-App-Dev,Web-Net-Ext,Web-Net-Ext45,Web-ISAPI-Filter,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-HTTP-Tracing,Web-Security,Web-Filtering,Web-Performance,Web-Stat-Compression,Web-Mgmt-Console,Web-Scripting-Tools,Web-Mgmt-Compat -Restart
