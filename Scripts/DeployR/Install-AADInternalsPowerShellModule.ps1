[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module PowerShellGet -Force -AllowClobber

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module AADInternals -SkipPublisherCheck -Scope AllUsers