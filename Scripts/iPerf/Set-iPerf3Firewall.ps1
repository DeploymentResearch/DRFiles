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

