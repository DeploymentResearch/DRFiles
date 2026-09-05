<#
.SYNOPSIS
    Removes a set of remote computers from the domain.
.DESCRIPTION
    Sets the trusted hosts list, then removes each machine from the domain over PowerShell
    remoting and restarts it.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark / deploymentresearch.com
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2022-01-02 - Initial release
#>

# Set credentials and allow remote administration via PowerShell to all hosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force

$Username = 'VIAMONSTRA\Administrator'
$Password = 'P@ssw0rd'
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$UnjoinCred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$pass

Remove-Computer -UnjoinDomainCredential $UnjoinCred -Force -WorkgroupName "WORKGROUP"
Start-sleep -Seconds 30
Restart-Computer
