# Application Install Wrapper sample for MDT and ConfigMg

# Determine where to do the logging 
try {
		$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
}
catch [System.Exception] {
	# Write-Warning -Message "Unable to create Microsoft.SMS.TSEnvironment object"
}

If($tsenv){
    # MDT Task Sequence Environment available
    $LogPath = $tsenv.Value("LogPath") 
}
else {
    # Running outside of Task Sequence Environment available
    $Logpath = "$env:SystemRoot\Temp"
}

$LogFile = "$LogPath\$($myInvocation.MyCommand)" -replace ".ps1",".log"

# Simple log function (replace with CMTrace formatted logging if needed)
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

# Install the application. Assuming installer is in same folder as the installer script
$SetupName = "Visual C++ Redistributable for Visual Studio 2019"
$SetupPath = Split-Path -Parent $MyInvocation.MyCommand.Path 
$SetupFile = "VC_redist.x64.exe"
$SetupArguments = "/install /quiet /norestart"
Write-Log "Starting install of $SetupName"
Write-Log "Command line to start is: $SetupFile $SetupSwitches"
Start-Process -FilePath $SetupPath\$SetupFile -ArgumentList $SetupArguments -NoNewWindow -Wait
Write-Log "Finished installing $SetupName"