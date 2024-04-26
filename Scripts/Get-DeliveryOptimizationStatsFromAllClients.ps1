$Devices = @(
    "CH1-PC0004"
    "CH1-PC0005"
    "CH1-PC0006"
)

# Get some DO Data
[System.Collections.ArrayList]$DOData = @()
foreach($Device in $Devices){
    
    $ScriptBlock = {

        $DOData = Get-DeliveryOptimizationPerfSnapThisMonth | Select DownloadHttpBytes, DownloadLanBytes

        $DownloadHttpBytes = $DOData.DownloadHttpBytes
        $DownloadLanBytes = $DOData.DownloadLanBytes
        $TotalDownloadBytes = $DownloadHttpBytes + $DownloadLanBytes

        # DO Efficiency
        $DOEfficiencyPercent = [MATH]::ROUND($DownloadLanBytes / $TotalDownloadBytes, 4)*100

        $DownloadHttpInGB = [MATH]::ROUND($DownloadHttpBytes/1GB,2)
        $DownloadLanInGB = [MATH]::ROUND($DownloadLanBytes/1GB,2)
        $TotalDownloadInGB = [MATH]::ROUND($TotalDownloadBytes/1GB,2)

        Write-Host "--------------------------------------------------------------"
        Write-Host "Download Http: $DownloadHttpInGB GB"
        Write-Host "Download Lan: $DownloadLanInGB GB"
        Write-Host "Total Download: $TotalDownloadInGB GB"
        Write-Host "DO Efficiency: $DOEfficiencyPercent %"
        Write-Host ""

        Return "$DOEfficiencyPercent","$TotalDownloadInGB","$DownloadLanInGB","$DownloadHttpInGB"

    }

    $Result = Invoke-Command -ScriptBlock $ScriptBlock -ComputerName $Device

    # Create custom PS object
    $obj = [PSCustomObject]@{

        # Add values to arraylist
    "DeviceName" = $Device
    "DOEfficiencyPercent" = $Result[0]
    "TotalDownloadInGB" = $Result[1]
    "DownloadLanInGB" = $Result[2]
    "DownloadHttpInGB" = $Result[3]

    }

    # Add all the values
    $DOData.Add($obj)|Out-Null
    
}

Write-Host "--------------------------------------------------------------" -ForegroundColor Green
Write-Host "----------------- FINAL RESULT -------------------------------" -ForegroundColor Green
Write-Host "--------------------------------------------------------------" -ForegroundColor Green
Write-Host ""


$TotalDownloadInGB =  ($DOData.TotalDownloadInGB | Measure-Object -Sum).Sum
$TotalDownloadHttpInGB = ($DOData.DownloadHttpInGB | Measure-Object -Sum).Sum
$TotalDownloadLanInGB = ($DOData.DownloadLanInGB | Measure-Object -Sum).Sum
$AverageDOEfficiencyPercent = [MATH]::ROUND(($DOData.DOEfficiencyPercent | Measure-Object -Average).Average,2)

Write-Host "Total Download: $TotalDownloadInGB GB"
Write-Host "Download Http: $TotalDownloadHttpInGB GB"
Write-Host "Download Lan: $TotalDownloadLanInGB GB"
Write-Host "Average DO Efficiency: $AverageDOEfficiencyPercent %"