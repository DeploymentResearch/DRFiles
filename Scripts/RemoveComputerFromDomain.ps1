# Set credentials and allow remote administration via PowerShell to all hosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force

$Username = 'VIAMONSTRA\Administrator'
$Password = 'P@ssw0rd'
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$UnjoinCred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$pass

Remove-Computer -UnjoinDomainCredential $UnjoinCred -Force -WorkgroupName "WORKGROUP"
Start-sleep -Seconds 30
Restart-Computer