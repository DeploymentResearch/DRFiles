# These sample assumes you have added additional meter actions to the network devices
# Add-VMNetworkAdapterAcl –VMName $VMName –Action Meter –Direction Both –RemoteIpAddress 192.168.2.0/24
# Add-VMNetworkAdapterAcl –VMName $VMName –Action Meter –Direction Both –RemoteIpAddress 192.168.28.0/24
#
# I also used this command to list the switch names
# Get-VMNetworkAdapter -VMName GW02-PFSENSE | select SwitchName, IPAddresses, id

$VMName = "GW02-PFSENSE"
$Logfile = "C:\Setup\Lab-Networkinfo-IPU-GW02.log"
$TimeInBetweenTests = 10 # Seconds
$NumberOfTests = '1440' # One test per 10 second = 4 hours

# Enable monitoring and reset the counters
Get-VM -Name $VMName | Enable-VMResourceMetering
Get-VM -Name $VMName | Reset-VMResourceMetering

# Remove any existing logfile
If (test-path $Logfile){ Remove-Item $Logfile -Force }

$i = 1
do {

    # Set TimeStamp to measurement of first VM in each test
    $Time = $(TimeStamp)
    $TimeFormatted = $Time.ToUniversalTime().ToString("MM/dd/yy HH:mm:ss")

    $TimeFormatted + " ---------------------------------------------------------------------------------------------" | Out-File -FilePath $Logfile -Append -Encoding ascii
    $TimeFormatted + " Internet switch (192.168.30.3) is Microsoft:885BB2EB-7883-4D54-B433-BB89C51142F4\B3F811C3-A386-4F63-BB99-3675A4DD8322" | Out-File -FilePath $Logfile -Append -Encoding ascii
    $TimeFormatted + " Stockholm switch (192.168.2.1) is Microsoft:885BB2EB-7883-4D54-B433-BB89C51142F4\E65D030F-1964-4748-B77F-D7D59FF91E58" | Out-File -FilePath $Logfile -Append -Encoding ascii
    $TimeFormatted + " Liverpool switch (192.168.28.1) is Microsoft:885BB2EB-7883-4D54-B433-BB89C51142F4\38C5D50E-C1D6-4859-97D5-91F21DE03B0E" | Out-File -FilePath $Logfile -Append -Encoding ascii
    $TimeFormatted + " ---------------------------------------------------------------------------------------------" | Out-File -FilePath $Logfile -Append -Encoding ascii

    Get-VMNetworkAdapterAcl -VMName $VMName | Out-File -FilePath $Logfile -Append -Encoding ascii

    # Sleep in between tests
    Start-Sleep -Seconds $TimeInBetweenTests

$i++
}
while ($i -le $NumberOfTests)