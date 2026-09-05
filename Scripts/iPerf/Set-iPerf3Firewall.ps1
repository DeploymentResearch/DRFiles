<#
.SYNOPSIS
    Creates the firewall rules needed to run an iPerf3 server.
.DESCRIPTION
    Adds inbound and outbound TCP rules for the iPerf3 listening port, so throughput tests can
    run between lab machines.
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

$Port = "5201"

$FirewallInboundParams = @{
    DisplayName = "iPerf3 Server Inbound TCP Rule";
    Direction = "Inbound";
    LocalPort = $Port;
    Protocol = "TCP";
    Action = "Allow";
    ErrorAction = "SilentlyContinue";
}

$FirewallOutboundParams = @{
    DisplayName = "iPerf3 Server Outbound TCP Rule";
    Direction = "Outbound";
    LocalPort = $Port;
    Protocol = "TCP";
    Action = "Allow";
    ErrorAction = "SilentlyContinue";
}

$inboundResult = New-NetFirewallRule @FirewallInboundParams
$outboundResult = New-NetFirewallRule @FirewallOutboundParams

if ($inboundResult -and $outboundResult) {
    Write-Verbose -Message 'iPerf3 server port firewall rules set.'
}
else {
    throw "iPerf3 server port firewall rules could not be set. Message: {0}" -f $error[0].Exception.message
}

