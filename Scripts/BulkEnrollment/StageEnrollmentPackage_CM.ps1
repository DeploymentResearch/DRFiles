# Determine where to do the logging
$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$LogPath = $TSEnv.Value("_SMSTSLogPath")
$Logfile = "$LogPath\$(($MyInvocation.MyCommand.Name).Replace(".ps1",".log"))"
$DismLogfile = "$($Logfile -replace ".{4}$")_DISM.log"

Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
   )

   $TimeGenerated = $(Get-Date -UFormat "%D %T")
   $Line = "$TimeGenerated : $Message"
   Add-Content -Value $Line -Path $LogFile -Encoding Ascii

}

# Delete any existing logfile if it exists
If (Test-Path $Logfile){Remove-Item $Logfile -Force -ErrorAction SilentlyContinue -Confirm:$false}
If (Test-Path $DismLogfile){Remove-Item $DismLogfile -Force -ErrorAction SilentlyContinue -Confirm:$false}

Write-Log -Message "Starting process of staging Enrollment Package via dism.exe"
Write-Log -Message "Note that full DISM Output will be logged to a separate log: $DISMLogFile"

$EnrollmentPackage = $TSEnv.Value("EnrollmentPackage")
$OSVolume = $TSEnv.Value("OSDisk")
Write-Log -Message "Current Enrollment Package is: $EnrollmentPackage"
Write-Log -Message "The target OS Volume in WinPE is: $OSVolume"

# Build and run DISM command
$Dism = "dism.exe"
$ArgumentList = "/Image=$OSVolume\ /Add-ProvisioningPackage /PackagePath:$EnrollmentPackage /LogPath:$DISMLogFile"
Write-Log -Message "About to run command: $Dism $ArgumentList"
$DISMResult = Start-Process -FilePath $Dism -ArgumentList $ArgumentList -Wait -PassThru -WindowStyle Hidden

If (-not($DISMResult.ExitCode -eq 0)){
    Write-Log -Message "Something went wrong during the dism command, Exit code is: $($DISMResult.ExitCode)"
    Write-Log -Message "Aborting script..."
    Break
}

Write-Log "Enrollment Package staging process successful: DISM exit code is: $($DISMResult.ExitCode)"


