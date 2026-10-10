# Script to measure inbound and outbound traffic on a set of Hyper-V VMs, both individual and summarized for all VMs
# Uses the "Hyper-V Virtual Network Adapter" performance counters instead of Hyper-V resource metering
# Note: Values are cumulative since the script was started

$Logfile = "C:\Setup\Lab-Networkinfo.log"
$TimeInBetweenTests = 10 # Seconds
$NumberOfTests = 1440 # One test per 10 seconds = 4 hours

# VM(s) to measure traffic for
$VMsToMeasure = "2PS-R001-001"

# Performance counters to read. The raw value of these counters is the cumulative number of bytes.
# Directions are from the VM's point of view: Received = inbound to the VM, Sent = outbound from the VM
$CounterPaths = "\Hyper-V Virtual Network Adapter(*)\Bytes Received/sec","\Hyper-V Virtual Network Adapter(*)\Bytes Sent/sec"

Function TimeStamp {
    $(Get-Date -UFormat "%D %T")
}

Function FormatGB {
    Param($Bytes)
    # Invariant culture so the log always uses a dot as decimal separator, regardless of host locale
    return ($Bytes / 1GB).ToString("N2", [System.Globalization.CultureInfo]::InvariantCulture)
}

Function GetCounterSamples {
    $Result = Get-Counter -Counter $CounterPaths -ErrorAction SilentlyContinue
    If ($Result){ return $Result.CounterSamples }
}

Function ProcessSamples {
    Param($Samples, $BaselineOnly)

    $Seen = @{}
    Foreach ($Sample in $Samples){

        # Counter instance names contain <VM GUID>--<Adapter GUID>, use the VM GUID to find the VM
        If ($Sample.InstanceName -notmatch '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})--'){ Continue }
        $VMName = $VMLookup[$Matches[1]]
        If (!$VMName){ Continue }

        $Key = $Sample.Path
        $Raw = [double]$Sample.RawValue
        $Seen[$Key] = $true

        If ($BaselineOnly){
            # Starting point, traffic before the script started is not counted
            $Previous[$Key] = $Raw
            Continue
        }

        # A counter instance not seen before (VM started after the baseline) is counted from zero
        $Prev = 0
        If ($Previous.ContainsKey($Key)){ $Prev = $Previous[$Key] }

        # A lower value than last time means the counter was reset (VM restart), count from zero again
        $Delta = $Raw - $Prev
        If ($Delta -lt 0){ $Delta = $Raw }

        If ($Key -like "*\bytes received/sec"){
            $Traffic[$VMName].Inbound += $Delta
        }
        Else {
            $Traffic[$VMName].Outbound += $Delta
        }
        $Previous[$Key] = $Raw
    }

    # Forget counter instances that are gone (VM turned off), so they are counted from zero when they come back
    $Gone = @($Previous.Keys | Where-Object { !$Seen.ContainsKey($_) })
    Foreach ($Key in $Gone){ $Previous.Remove($Key) }
}

# Make sure the log folder exists
$LogFolder = Split-Path -Path $Logfile -Parent
If (!(Test-Path $LogFolder)){ New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null }

# Remove any existing logfile
If (Test-Path $Logfile){ Remove-Item $Logfile -Force }

# Build a lookup table (VM GUID to VM name) and the traffic totals (in bytes) per VM
$VMLookup = @{}
$Traffic = @{}
$Previous = @{}
Foreach ($VMObject in (Get-VM -Name $VMsToMeasure)){
    $VMLookup[$VMObject.Id.ToString()] = $VMObject.Name
    $Traffic[$VMObject.Name] = @{ Inbound = 0; Outbound = 0 }
}
$VMNames = $VMLookup.Values | Sort-Object

# Take the baseline sample
$Samples = GetCounterSamples
If ($Samples){ ProcessSamples -Samples $Samples -BaselineOnly $true }

# Warn about VMs without a counter instance (normal if the VM is off, otherwise the instance name did not match)
Foreach ($VM in $VMNames){
    $VMId = ($VMLookup.GetEnumerator() | Where-Object Value -eq $VM).Key
    If (!($Previous.Keys | Where-Object { $_ -like "*$VMId*" })){
        Write-Warning "No network adapter counter found for $VM yet. This is expected if the VM is turned off."
    }
}

$StartTime = Get-Date
$i = 1
do {

    # Set TimeStamp to the start of each test
    $Time = $(TimeStamp)

    # One counter read covers all VMs. If the read fails, the previous totals are logged again.
    $Samples = GetCounterSamples
    If ($Samples){ ProcessSamples -Samples $Samples -BaselineOnly $false }

    $TotalInboundTraffic = 0
    $TotalOutboundTraffic = 0

    # Log each VM
    Foreach($VM in $VMNames){

        $Time + " $VM Inbound Network Traffic (GB) : $(FormatGB $Traffic[$VM].Inbound)" | Out-File -FilePath $Logfile -Append -Encoding ascii
        $Time + " $VM Outbound Network Traffic (GB) : $(FormatGB $Traffic[$VM].Outbound)" | Out-File -FilePath $Logfile -Append -Encoding ascii

        # Add to the totals
        $TotalInboundTraffic += $Traffic[$VM].Inbound
        $TotalOutboundTraffic += $Traffic[$VM].Outbound

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
