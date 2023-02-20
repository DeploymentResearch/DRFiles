# Demo script for remote PowerShell
#
# Author: Johan Arwidmark
# Twitter: @jarwidmark
# LinkedIn: https://www.linkedin.com/in/jarwidmark

$LowNumber = 1
$HigNumber = 9

$Srvs = $($LowNumber..$HigNumber|%{"{0:D3}" -f $_})
$Servers = foreach($Srv in $Srvs){"ROGUE-$SRV"}

$Cred = Get-Credential

# Get Free Diskspace (Command)
Invoke-Command -command { $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"; "$Env:Computername C: has {0:#.0} GB free of {1:#.0} GB Total" -f ($disk.FreeSpace/1GB),($disk.Size/1GB) } -computerName $Servers -Credential $Cred

# Get Memory Configuration (ScriptBlock)
Invoke-Command -ScriptBlock { 
    $Memory = get-wmiobject Win32_ComputerSystem
    $MemoryInGB = [math]::round($Memory.TotalPhysicalMemory/1GB, 0)
    Write-Host "$Env:Computername has $MemoryInGB GB RAM" 
} -computerName $Servers -Credential $Cred

# Activate all Hosts against KMS
Invoke-Command -command { cscript.exe C:\Windows\System32\slmgr.vbs /skms "192.168.0.9" } -computerName $Servers -Credential $Cred
Invoke-Command -command { cscript.exe C:\Windows\System32\slmgr.vbs /ato } -computerName $Servers -Credential $Cred
