# Simple test, should return with status code 200
Invoke-WebRequest -URI "http://dp01.corp.viamonstra.com/mscomtest/wuidt.gif" -Headers @{"Host"="b1.download.windowsupdate.com"}

# MCC Log files
# C:\Windows\Temp\arr_setup.log
# DO cache server setup log: E:\SMS_DP$\Ms.Dsp.Do.Inc.Setup\DoincSetup.log (On the DP)
# E:\Program Files\Microsoft Configuration Manager\Logs\distmgr.log (On the site server)
# IIS logs: C:\inetpub\logs\LogFiles
# DO cache server operational log: C:\Doinc\Product\Install\Logs

# First add a reference to the MWA dll
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")

# Get the manager and config object
$mgr = new-object Microsoft.Web.Administration.ServerManager
$conf = $mgr.GetApplicationHostConfiguration()

# Get the webFarms section
$section = $conf.GetSection("webFarms")
$webFarms = $section.GetCollection()

# Get the first web farm for simplicity but can be selected using $webFarm.GetAttributeValue("name")
$webFarm = $webFarms[0]

#Get the servers in the farm
$servers = $webFarm.GetCollection()

#Select the first server
$server = $servers[0]

#Just to display the server selected
$server.GetAttributeValue("address")

#Get the ARR section
$arr = $server.GetChildElement("applicationRequestRouting")
$counters = $arr.GetChildElement("counters")


##
# To get the health status of the server we can do
$counters.GetAttributeValue("isHealthy")

## 
# To get the availibility or state of the server
$counters.GetAttributeValue("state")
# 0 = Available
# 1 = Drain
# 2 = Unavailable

#All the counters can be listed with that
$counters.Attributes | Format-List



$counters.GetAttributeValue("totalRequests")



# Get the webFarms section
$section = $conf.GetSection("webFarms")
$webFarms = $section.GetCollection()

Foreach ($webFarm in $webFarms){
    #Get the servers in the farm
    $servers = $webFarm.GetCollection()

    #Select the first server
    $server = $servers[0]

    #Just to display the server selected
    $Address = $server.GetAttributeValue("address")

    #Get the ARR section
    $arr = $server.GetChildElement("applicationRequestRouting")
    $counters = $arr.GetChildElement("counters")

    $totalRequests = $counters.GetAttributeValue("totalRequests")

    Write-host "Total Requests for $Address is: $totalRequests"
}


# Look in C:\Windows\system32\inetsrv\config\schema\arr_schema.xml for details,
# There is a ResetCounters method
$MCCServer = "dp01.corp.viamonstra.com"
$MCC = Invoke-RestMethod http://$($MCCServer):53000/summary
Start-Sleep -Seconds 5

$MCCServer = "dp01.corp.viamonstra.com"
$MCC = Invoke-RestMethod http://$($MCCServer):53000/summary

# Measure Active connections three times
$MCC_AC1 = [Math]::Round($MCC.LastCacheNodeHealthPingRequest.TCPv4ConnectionsActive)
Start-sleep -Seconds 10
$MCC = Invoke-RestMethod http://$($MCCServer):53000/summary
$MCC_AC2 = [Math]::Round($MCC.LastCacheNodeHealthPingRequest.TCPv4ConnectionsActive)
Start-sleep -Seconds 10
$MCC = Invoke-RestMethod http://$($MCCServer):53000/summary
$MCC_AC3 = [Math]::Round($MCC.LastCacheNodeHealthPingRequest.TCPv4ConnectionsActive)
$MCC_ActiveConnections = [math]::Round(($MCC_AC1+$MCC_AC2+$MCC_AC3)/3)

$MissGB = [Math]::Round($MCC.LastCacheNodeHealthPingRequest.DoincCacheTotalMissBytes /1GB,2)
$HitGB = [Math]::Round($MCC.LastCacheNodeHealthPingRequest.DoincCacheTotalHitBytes /1GB,2)

If ($MCC_HitGB -eq 0){
    # Do nothing, can't divide by zero
    $CachePercent = 0
}
Else{
    $CachePercent = "{0:P2}" -f ($MCC_HitGB / ($MCC_MissGB + $MCC_HitGB))
}

$CachePercent = "{0:P2}" -f ($HitGB / ($MissGB + $HitGB))

Write-host "Active Connections are: $MCC_ActiveConnections"
Write-host "Cache HIT (GB): $HitGB GB"
Write-host "Cache MISS (GB): $MissGB GB"
Write-Host "Percent of Content from Cache: $CachePercent"


