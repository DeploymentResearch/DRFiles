# Clear ConfigMgr Cache
$UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
$Cache = $UIResourceMgr.GetCacheInfo()
$CacheElements = $Cache.GetCacheElements() 
foreach ($Element in $CacheElements) { 	$Cache.DeleteCacheElementEx($Element.CacheElementID, $true) }

# Clear BranchCache cache
Clear-BCCache -Force

# Get BranchCache Cache Info
Get-BCDataCache
[Math]::Round(((Get-BCDataCache).CurrentActiveCacheSize/1GB),2)

# Show BranchCache status (netsh branchcache show status all)
netsh br sh st a 

# Get CM Client cache info
$resman = new-object -com "UIResource.UIResourceMgr"; $cacheInfo = $resman.GetCacheInfo()
$ccmcachetotal = ($cacheinfo.TotalSize)/1024
$ccmcachetotalRounded = [math]::Round($ccmcachetotal,2)
$ccmcachefree = ($cacheinfo.FreeSize)/1024
$ccmcachefreeRounded = [math]::Round($ccmcachefree,2)
$ccmcacheused = $ccmcachetotal - $ccmcachefree
$ccmcacheusedRounded = [math]::Round($ccmcacheused,2)
Write-Host "Total Cache Space: $ccmcachetotalRounded GB"
Write-Host "Used Cache Space: $ccmcacheusedRounded GB"
Write-Host "Free Cache Space: $ccmcachefreeRounded GB"


# Test BranchCache by manual BITS download from IIS
# Copy a boot WIM image to C:\inetpub\wwwroot on a BranchCache-enabled DP.
# Then use below commands to download via BITS to C:\Temp
$BCMonPath = "C:\Setup\BCMon 1.3.8.1"
#$BCMonPath = "C:\Setup\BCRelease"
$DownloadPath = "C:\BCTemp"
$FileName = "data.zip" # renamed from .wim because of default MIME types
#$FileName = "ISOCollection.zip" # renamed from .7z because of default MIME types
$DP = "dp01.corp.viamonstra.com"
Write-Host "DP: $DP"
$URL = "http://$DP/$FileName"
Write-Host "URL: $URL"
New-Item -Type Directory -Path $DownloadPath -Force

# Verify the BCMon.exe exists
If (!(Test-Path "$BCMonPath\BCmon.exe")){Write-Warning "BCmon.exe not found in $BCMonPath folder." }

# Verify CI from Publication Cache on BranchCache server, show result in command prompt window
Start-Process cmd.exe -ArgumentList "/k `"$BCMonPath\BCmon.exe`" /VerifyCI /URL:$URL"

# Download CI, and query local BranchCache cache for content
Start-Process cmd.exe -ArgumentList "/k `"$BCMonPath\BCmon.exe`" /DownloadCIFromSingleURL /URL:$URL /Folder:$DownloadPath /SaveAll /BCVersion:2.0" -Wait
$CIFileName = "$DownloadPath\$FileName.ci"
# Show result in command prompt window
Start-Process cmd.exe -ArgumentList "/k `"$BCMonPath\BCmon.exe`" /QueryCI $CIFileName"

# Download the file
Clear-BCCache -Force
Measure-command {Start-BitsTransfer -Source $URL -Destination $DownloadPath}
If ($DownloadPath){Remove-Item "$DownloadPath\*" -Force}

# Check P2P efficiency via the Event Log
$Events = Get-WinEvent -FilterHashTable @{ LogName="*Bits*"; ID=60; Data="$URL" } | foreach {
$_ | Add-Member -MemberType NoteProperty -Name name -Value $_.Properties[1].Value;
$_ | Add-Member -MemberType NoteProperty -Name url -Value $_.Properties[3].Value;
$_ | Add-Member -MemberType NoteProperty -Name bytesTotal -Value $_.Properties[8].Value;
$_ | Add-Member -MemberType NoteProperty -Name bytesTransferred -Value $_.Properties[9].Value;
$_ | Add-Member -MemberType NoteProperty -Name bytesTransferredFromPeer -Value $_.Properties[12].Value -PassThru;
} 
$events | Sort-Object TimeCreated -Descending | Select -First 1 TimeCreated, url, bytesTotal, bytesTransferred, bytesTransferredFromPeer

# Check P2P efficiency via the Event Log
$Events = (Get-WinEvent -FilterHashTable @{ LogName='*Bits*'; ID=60 } -ErrorAction SilentlyContinue  ) | 
    Where { ($_.Message -like "*BITS stopped transferring the CCMDTS Job transfer*") -and ($_.Message -like "*SMS_DP*")}| 
    Sort-Object -Descending TimeCreated | foreach {
$_ | Add-Member -MemberType NoteProperty -Name name -Value $_.Properties[1].Value;
$_ | Add-Member -MemberType NoteProperty -Name url -Value $_.Properties[3].Value;
$_ | Add-Member -MemberType NoteProperty -Name bytesTotal -Value $_.Properties[8].Value;
$_ | Add-Member -MemberType NoteProperty -Name bytesTransferred -Value $_.Properties[9].Value;
$_ | Add-Member -MemberType NoteProperty -Name bytesTransferredFromPeer -Value $_.Properties[12].Value -PassThru;
} 
$events | Sort-Object TimeCreated -Descending | Select -First 1 TimeCreated, url, bytesTotal, bytesTransferred, bytesTransferredFromPeer

# Check P2P efficiency via the Event Log
$Events = (Get-WinEvent -FilterHashTable @{ LogName='*Bits*'; ID=60 } -ErrorAction SilentlyContinue  ) | 
    Where { ($_.Message -like "*BITS stopped transferring the CCMDTS Job transfer*")}| 
    Sort-Object -Descending TimeCreated | foreach {
$_ | Add-Member -MemberType NoteProperty -Name name -Value $_.Properties[1].Value;
$_ | Add-Member -MemberType NoteProperty -Name url -Value $_.Properties[3].Value;
$_ | Add-Member -MemberType NoteProperty -Name bytesTotal -Value $_.Properties[8].Value;
$_ | Add-Member -MemberType NoteProperty -Name bytesTransferred -Value $_.Properties[9].Value;
$_ | Add-Member -MemberType NoteProperty -Name bytesTransferredFromPeer -Value $_.Properties[12].Value -PassThru;
} 
$events | Sort-Object TimeCreated -Descending | Select -First 100 TimeCreated, url, bytesTotal, bytesTransferred, bytesTransferredFromPeer


# Get BITS info via Bitsadmin
bitsadmin /Util /Version /Verbose

# List all current jobs
bitsadmin /list /allusers /verbose
Get-BitsTransfer -AllUsers

# List peers during job
#bitsadmin /getpeerstats <job> <file-index>

# Force machine policy evaluation (Machine Policy Assignments Request, that in turn will trigger Machine Policy Evaluation)
$trigger = "{00000000-0000-0000-0000-000000000021}"
Invoke-CimMethod -Namespace 'root\ccm' -ClassName 'sms_client' -MethodName TriggerSchedule -Arguments @{sScheduleID=$trigger}

# Evaluation
Start-Sleep -Seconds 10
$trigger = "{00000000-0000-0000-0000-000000000022}"
Invoke-CimMethod -Namespace 'root\ccm' -ClassName 'sms_client' -MethodName TriggerSchedule -Arguments @{sScheduleID=$trigger}


# Disable Windows Firewall
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Enable Windows Firewall
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Get Windows Firewall status
Get-NetFirewallProfile | Select name, Enabled

# Get network settings (what profile that is active)
Get-NetConnectionProfile | select *

# List Windows firewall settings (does not always show the correct path)
netsh advfirewall show allprofiles

# Enable logging for dropped packages
Set-NetFireWallProfile -Profile Domain -LogBlocked True -LogMaxSize 16384 -LogFileName "C:\Windows\system32\LogFiles\Firewall\domainfw.log"
Set-NetFireWallProfile -Profile Private -LogBlocked True -LogMaxSize 16384 -LogFileName "C:\Windows\system32\LogFiles\Firewall\privatefw.log"
Set-NetFireWallProfile -Profile Public -LogBlocked True -LogMaxSize 16384 -LogFileName "C:\Windows\system32\LogFiles\Firewall\publicfw.log"

# Parse domain firewall log for Dropped packages
$FWLog = "C:\Windows\system32\LogFiles\Firewall\domainfw.log"
Select-String -Path $FWLog -Pattern "3702"

# Show in grid view
$headerFields = @("date","time","action","protocol","src-ip","dst-ip","src-port","dst-port","size","tcpflags","tcpsyn","tcpack","tcpwin","icmptype","icmpcode","info","path")
$FWLogFormatted = Get-Content $FWLog | ConvertFrom-Csv -Header $headerFields -Delimiter ' '
$FWLogFormatted | Out-GridView

# Show in grid view, dropped packages only
$headerFields = @("date","time","action","protocol","src-ip","dst-ip","src-port","dst-port","size","tcpflags","tcpsyn","tcpack","tcpwin","icmptype","icmpcode","info","path")
$FWLogFormatted = Select-String -Path $FWLog -Pattern "DROP UDP" | ConvertFrom-Csv -Header $headerFields -Delimiter ' '
$FWLogFormatted | Out-GridView

# Enable audit for firewall inspection
# Event ID 5152: The Windows Filtering Platform blocked a packet.
# Event ID 5153: A more restrictive Windows Filtering Platform filter has blocked a packet.
auditpol /set /subcategory:"Filtering Platform Packet Drop" /success:enable /failure:enable
auditpol /set /subcategory:"Filtering Platform Connection" /success:enable /failure:enable
# Reproduce the issue, then run below
Set-location "C:\Temp"
netsh wfp show state # Creates a XML file in the current folder
# Open Security Event log
# Use the Search for source IP, destination port, etc.
# In the log entry details, scroll down and note the filter ID used to block the packet
# Open the generated wfpstate.xml file
Notepad C:\Temp\wfpstate.xml
# Search for the noted filterID, and check out the rule name (element “displayData > name” on the corresponding XML node)
# 
# There are a few special firewall rules that can’t be seen within the Windows Firewall app
#
# Port Scanning Prevention Filter
# This rule blocks traffic when no service is listening on a port. I.e. if no service is listening on port ‘80’ the firewall will block all traffic to port 80.
#
# Query User
# This rule is designed to show a Windows Firewall Block/Allow prompt to the user under certain conditions.


# List Group Policies applied on the local computer
gpresult /R /scope computer

# Dump Detail for all Group Policies to a text file
$GPOSettings = "C:\Windows\Temp\GPOSettings.txt"
gpresult /R /scope computer /v > $GPOSettings
Notepad $GPOSettings

# Dump  Group Policies to a HTML file
$GPOresult = "C:\Windows\Temp\GPOSettings.html"
If (Test-Path $GPOresult) {Remove-Item $GPOresult -Force}
gpresult /scope computer /H $GPOresult
start msedge $GPOresult

# Get OU of computer in AD
$SysInfo = New-Object -ComObject "ADSystemInfo"
$ComputerDN = $SysInfo.GetType().InvokeMember("ComputerName", "GetProperty", $Null, $SysInfo, $Null)
$ComputerDN

# Ask for content from the task sequence: Pre-Cache Content for Windows 10 21H2 OSD

# Query BranchCache cache for boot image 
Start-Process cmd.exe -ArgumentList "/k `"$BCMonPath\BCmon.exe`" /QueryCache /PackageID:PS1000BA /Version:24" # Zero Touch WinPE 10 x64 - OSD Toolkit



# Query BranchCache cache for drivers
Start-Process cmd.exe -ArgumentList "/k `"$BCMonPath\BCmon.exe`" /QueryCache /PackageID:PS100147 /Version:1" # Drivers - Dell Latitude 3120 - Windows 10 x64
Start-Process cmd.exe -ArgumentList "/k `"$BCMonPath\BCmon.exe`" /QueryCache /PackageID:PS100148 /Version:1" # Drivers - Dell Latitude 3300 - Windows 10 x64
Start-Process cmd.exe -ArgumentList "/k `"$BCMonPath\BCmon.exe`" /QueryCache /PackageID:PS100146 /Version:1" # Drivers - Dell Latitude 3310 - Windows 10 x64
Start-Process cmd.exe -ArgumentList "/k `"$BCMonPath\BCmon.exe`" /QueryCache /PackageID:PS100155 /Version:1" # Drivers - Dell Latitude 5320 - Windows 10 x64

# Query BranchCache cache for OS image 
Start-Process cmd.exe -ArgumentList "/k `"$BCMonPath\BCmon.exe`" /QueryCache /PackageID:PS100139 /Version:1" # Windows 10 Enterprise x64 21H2


# Start TSS v2 tool (https://aka.ms/getTSSv2)
Set-Location C:\Setup\TSSv2
.\TSSv2.ps1 -Scenario NET_Firewall