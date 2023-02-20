$LogFile = "C:\Windows\Temp\ViaMonstraTools_Uninstall.log"
$TargetFolder = "C:\Tools"

# Delete any existing logfile if it exists
If (Test-Path $LogFile){Remove-Item $LogFile -Force -ErrorAction SilentlyContinue -Confirm:$false}

Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
    )

    $TimeGenerated = $(Get-Date -UFormat "%D %T")
    $Line = "$TimeGenerated : $Message"
    Add-Content -Value $Line -Path $LogFile -Encoding Ascii
}

Write-Log "Starting the ViaMonstra Lab Tools Uninstaller"

# Make sure target folder exists
If (!(Test-Path $TargetFolder)){ 
    Write-Log "Target folder $TargetFolder does not exist, do nothing"
}
else {
    Write-Log "About to delete $TargetFolder"
    try {
        Remove-Item -Path $TargetFolder -Recurse -Force -ErrorAction Stop
        Write-Log "$TargetFolder successfully deleted"
    } 
    catch {
        Write-Log "Failed to delete TargetFolder. Error is: $($_.Exception.Message))"
    }
}