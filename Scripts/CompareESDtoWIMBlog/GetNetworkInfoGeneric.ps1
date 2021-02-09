# Script to measure outbound traffic on a set of Hyper-V VMs, both individual and summarized for all VMs

$Logfile = "C:\Setup\Lab-Networkinfo-ESD-Testing.log"
$TimeInBetweenTests = 10 # Seconds
$NumberOfTests = '1440' # One test per 10 second = 4 hours

# VMs to measure outbound traffic for. 
# In this example a Domain Controller, a ConfigMgr Site Server, and a ConfigMgr DP
$VMsToMeasure = "DEMO-OSD-TP-DP01","GW02-PFSENSE","DEMO-OSD-TP-TEST01","DEMO-OSD-TP-TEST02","DEMO-OSD-TP-TEST03"

# Enable Resource Metering on the selected VMs
Get-VM $VMsToMeasure | Enable-VMResourceMetering

Function TimeStamp {
    # $(Get-Date -UFormat "%D %T")
    #(Get-Date).ToUniversalTime().ToString("MM/dd/yy HH:mm:ss")
    Get-Date
} 

Function GetInboundTraffic{
    Param($VMName)
    $networkinfo = Measure-VM -Name $VMName | `
    Select-Object -property @{Expression = {"{0:N2}" -f(($_.NetworkMeteredTrafficReport | `
    Where-Object direction -Eq 'Inbound' | `
    Measure-Object -property TotalTraffic -sum).Sum / 1024) };Label="Inbound Network Traffic (GB)"}
    return $networkinfo.'Inbound Network Traffic (GB)'
}

Function GetOutboundTraffic{
    Param($VMName)
    $networkinfo = Measure-VM -Name $VMName | `
    Select-Object -property @{Expression = {"{0:N2}" -f(($_.NetworkMeteredTrafficReport | `
    Where-Object direction -Eq 'outbound' | `
    Measure-Object -property TotalTraffic -sum).Sum / 1024) };Label="Outbound Network Traffic (GB)"}
    return $networkinfo.'Outbound Network Traffic (GB)'
}

# Remove any existing logfile
If (test-path $Logfile){ Remove-Item $Logfile -Force }

# Reset the metering counters for all measured VMs
Get-VM -Name $VMsToMeasure | Reset-VMResourceMetering

# Set Starttime for calcultation duration
$StartTime = $(TimeStamp)

$i = 1
do {

    # Set TimeStamp to measurement of first VM in each test
    $Time = $(TimeStamp)
    $TimeFormatted = $Time.ToUniversalTime().ToString("MM/dd/yy HH:mm:ss")
    
    [System.Collections.ArrayList]$AggregateTraffic = @()
    # Measure each VM
    Foreach($VM in $VMsToMeasure){

        $InboundTraffic = (GetInboundTraffic -VMName $VM)
        $TimeFormatted + " $VM Inbound Network Traffic (GB) : $InboundTraffic" | Out-File -FilePath $Logfile -Append -Encoding ascii
        
        $OutboundTraffic = (GetOutboundTraffic -VMName $VM)
        $TimeFormatted + " $VM Outbound Network Traffic (GB) : $OutboundTraffic" | Out-File -FilePath $Logfile -Append -Encoding ascii

        $obj = [PSCustomObject]@{

            # Add values to arraylist
            VMName = $VM
            TimeStamp = $TimeFormatted 
            OutboundTraffic = $OutboundTraffic
            InboundTraffic = $InboundTraffic
            
        }
        
        # Add all the values
        $AggregateTraffic.Add($obj)|Out-Null

    }

    # Log duration
    $Duration = New-TimeSpan –Start $StartTime –End $Time
    "Duration so far is: $($Duration.Hours) hours, $($Duration.Minutes) minutes, $($Duration.Seconds) seconds" | Out-File -FilePath $Logfile -Append -Encoding ascii

    # Sleep in between tests
    Start-Sleep -Seconds $TimeInBetweenTests
$i++
}
while ($i -le $NumberOfTests)
