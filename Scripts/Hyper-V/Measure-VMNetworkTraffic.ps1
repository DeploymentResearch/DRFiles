# Script to measure inbound and outbound traffic on a set of Hyper-V VMs, both individual and summarized for all VMs
# Note: Values are cumulative since the metering counters were reset at script start

$Logfile = "C:\Setup\Lab-Networkinfo.log"
$TimeInBetweenTests = 10 # Seconds
$NumberOfTests = 1440 # One test per 10 seconds = 4 hours

# VM(s) to measure traffic for
$VMsToMeasure = "2PS-R001-001"

Function TimeStamp {
    $(Get-Date -UFormat "%D %T")
}

Function GetTraffic{
    Param($VMName)
    # One Measure-VM call per VM, so inbound and outbound come from the same sample
    # TotalTraffic is reported in MB, return numeric values in GB (formatting is done when logging)
    $Report = (Measure-VM -Name $VMName).NetworkMeteredTrafficReport
    $InboundSum = ($Report | Where-Object Direction -eq 'Inbound' | Measure-Object -Property TotalTraffic -Sum).Sum
    $OutboundSum = ($Report | Where-Object Direction -eq 'Outbound' | Measure-Object -Property TotalTraffic -Sum).Sum

    return [PSCustomObject]@{
        Inbound  = [double]($InboundSum / 1024)
        Outbound = [double]($OutboundSum / 1024)
    }
}

Function FormatGB {
    Param($Value)
    # Invariant culture so the log always uses a dot as decimal separator, regardless of host locale
    return $Value.ToString("N2", [System.Globalization.CultureInfo]::InvariantCulture)
}

# Make sure the log folder exists
$LogFolder = Split-Path -Path $Logfile -Parent
If (!(Test-Path $LogFolder)){ New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null }

# Remove any existing logfile
If (Test-Path $Logfile){ Remove-Item $Logfile -Force }

# Enable Resource Metering on the selected VMs
Get-VM -Name $VMsToMeasure | Enable-VMResourceMetering

# Reset the metering counters for all measured VMs
Get-VM -Name $VMsToMeasure | Reset-VMResourceMetering

$StartTime = Get-Date
$i = 1
do {

    # Set TimeStamp to measurement of first VM in each test
    $Time = $(TimeStamp)

    $TotalInboundTraffic = 0
    $TotalOutboundTraffic = 0

    # Measure each VM
    Foreach($VM in $VMsToMeasure){

        $Traffic = GetTraffic -VMName $VM
        $Time + " $VM Inbound Network Traffic (GB) : $(FormatGB $Traffic.Inbound)" | Out-File -FilePath $Logfile -Append -Encoding ascii
        $Time + " $VM Outbound Network Traffic (GB) : $(FormatGB $Traffic.Outbound)" | Out-File -FilePath $Logfile -Append -Encoding ascii

        # Add to the totals
        $TotalInboundTraffic += $Traffic.Inbound
        $TotalOutboundTraffic += $Traffic.Outbound

    }

    # Log total traffic
    $Time + " All VMs Total Inbound Network Traffic (GB) : $(FormatGB $TotalInboundTraffic)" | Out-File -FilePath $Logfile -Append -Encoding ascii
    $Time + " All VMs Total Outbound Network Traffic (GB) : $(FormatGB $TotalOutboundTraffic)" | Out-File -FilePath $Logfile -Append -Encoding ascii

    # Sleep until the next scheduled test (compensates for the time the measurements take, so the run does not drift)
    If ($i -lt $NumberOfTests){
        $NextTest = $StartTime.AddSeconds($i * $TimeInBetweenTests)
        $SleepMs = [int]($NextTest - (Get-Date)).TotalMilliseconds
        If ($SleepMs -gt 0){ Start-Sleep -Milliseconds $SleepMs }
    }

    $i++
}
while ($i -le $NumberOfTests)
