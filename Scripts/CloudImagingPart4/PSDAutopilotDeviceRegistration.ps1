<#
.Synopsis
    This script uploads Autopilot into to a RestPS web service
    
.Description
    This script was written by Johan Arwidmark @jarwidmark

.LINK
    https://github.com/FriendsOfMDT/PSD

.NOTES
          FileName: PSDAutopilotDeviceRegistration.ps1
          Solution: PowerShell Deployment for MDT
          Author: PSD Development Team
          Contact: @jarwidmark
          Primary: @jarwidmark 
          Created: 2020-11-09
          Modified: 2020-11-18

          Version - 0.0.0.1 - () - Finalized functional version 1.

.EXAMPLE
	.\PSDAutopilotDeviceRegistration.ps1
#>

#Requires -RunAsAdministrator
[CmdletBinding()]
param (

)

$LogFile = "C:\Windows\Temp\PSDAutopilotDeviceRegistration.log"

# Delete any existing logfile if it exists
If (Test-Path $Logfile){Remove-Item $Logfile -Force -ErrorAction SilentlyContinue -Confirm:$false}

Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
   )

   $TimeGenerated = $(Get-Date -UFormat "%D %T")
   $Line = "$TimeGenerated $Message"
   Add-Content -Value $Line -Path $LogFile -Encoding Ascii

}


#Write-Log -Message "$($MyInvocation.MyCommand.Name): Starting..."

# Remove any unattend.xml files
Write-Log -Message "Starting to remove existing unattend.xml files"
If (Test-Path "C:\Windows\Panther\unattend.xml" ){Remove-Item "C:\Windows\Panther\unattend.xml" -Force } 
If (Test-Path "C:\Windows\System32\Sysprep\unattend.xml" ){Remove-Item "C:\Windows\System32\Sysprep\unattend.xml" -Force } 


# Get Intune Group from GroupTag variable        
$path = "C:\MININT\Variables.dat"
if (Test-Path -Path $path) {
    [xml] $v = Get-Content -Path $path
    $v | Select-Xml -Xpath "//var" | foreach { 
        If ($($_.Node.name) -eq "GroupTag"){ $GroupTag = $($_.Node.'#cdata-section') }  
        If ($($_.Node.name) -eq "DeployRoot"){ $DeployRoot = $($_.Node.'#cdata-section') }  
    } 
}

Write-Log -Message "GroupTag from PSD deployment wizard is $GroupTag"
Write-Log -Message "Autopilot result will be saved in $AutopilotOutputFile"
$AutopilotOutputFile = "C:\Windows\Temp\AutoPilotInfo.csv"
$AutopilotScriptPath = "C:\Windows\Temp\Get-WindowsAutoPilotInfo.ps1"
$GetAutoPilotArguments = "$AutopilotScriptPath -GroupTag $GroupTag -OutputFile $AutopilotOutputFile"
Write-Log -Message "About to run the command: $GetAutoPilotArguments"
$GetAutoPilotProcess = Start-Process PowerShell -ArgumentList $GetAutoPilotArguments -NoNewWindow -PassThru -Wait

if(-not($GetAutoPilotProcess.ExitCode -eq 0)){
    Write-Log -Message "Something went wrong running Get-WindowsAutoPilotInfo.ps1. Exit code $($GetAutoPilotProcess.ExitCode)"
    Write-Log -Message "Aborting script..."
    Break
}

Write-Log -Message "Results saved to $AutopilotOutputFile"

# Log the result 
$AutopilotCSV = Import-Csv $AutopilotOutputFile
$SerialNumber = ($AutopilotCSV | Select -First 1)."Device Serial Number"
Write-Log -Message "Device Serial Number is: $SerialNumber"
Write-Log -Message "Device GroupTag is: $GroupTag" 

# Convert the CSV file to JSON 
Write-Log -Message "Converting the CSV file to JSON"
$AutopilotJSON = $AutopilotCSV | ConvertTo-Json 
Write-Log -Message "JSON object created for computer: $env:COMPUTERNAME"

# Cleanup
#Write-Log -Message "Removing $AutopilotOutputFile file"
#Remove-item -Path $AutopilotOutputFile -Force 

Function Show-PSDBackgroundInfo{
    Param
    (
        $Message,
        $ImagePath
    )

    $BackColor = "#F0F0F0"
    $Label1Text = "Information"

    try {
        Add-Type -AssemblyName System.Windows.Forms -IgnoreWarnings
        [System.Windows.Forms.Application]::EnableVisualStyles()
    }
    catch [System.UnauthorizedAccessException] {
        # This should never happen, but we're catching if it does anyway.
        Start-Process PowerShell -ArgumentList {
            Write-warning -Message 'Access denied when trying to load required assemblies, cannot display the summary window.'
            Pause
        } -Wait
        exit 1
    }
    catch [System.Exception] {
        # This should never happen either, but we're catching if it does anyway.
        Start-Process PowerShell -ArgumentList {
            Write-warning -Message 'Unable to load required assemblies, cannot display the summary window.'
            Pause
        } -Wait
        exit 1
    }

    $Form                            = New-Object system.Windows.Forms.Form
    $Form.WindowState                = 'Maximized'
    $Form.FormBorderStyle            = 'None'
    $Form.text                       = "PSD"
    $Form.StartPosition              = "CenterScreen"
    $Form.MaximizeBox                = $false
    $Form.BackColor                  = $BackColor
    $Form.TopMost                    = $true
    $Form.Icon                       = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")

    $BackgroundImage = [system.drawing.image]::FromFile($ImagePath)
    
   
    $Form.BackgroundImage = $BackgroundImage
    $Form.BackgroundImageLayout = "Stretch" # None, Tile, Center, Stretch, Zoom

    # Show overlay with GIF progress animation
    #$pic = New-Object System.Windows.Forms.PictureBox
    #$pic.BackColor = [System.Drawing.Color]::Transparent
    #$pic.Dock = [System.Windows.Forms.DockStyle]::Fill
    #$pic.ImageLocation = "https://i.stack.imgur.com/repwc.gif"
    #$pic.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::CenterImage

    $Label1                          = New-Object system.Windows.Forms.Label
    $Label1.text                     = "$Label1Text"
    $Label1.AutoSize                 = $true
    $Label1.width                    = 25
    $Label1.height                   = 10
    $Label1.location                 = New-Object System.Drawing.Point(25,10)
    $Label1.Font                     = 'Segoe UI,14'

    $TextBox1                        = New-Object system.Windows.Forms.TextBox
    $TextBox1.multiline              = $True
    $TextBox1.width                  = 550
    $TextBox1.height                 = 100
    $TextBox1.location               = New-Object System.Drawing.Point(25,60)
    $TextBox1.Font                   = 'Segoe UI,12'
    $TextBox1.Text                   = $Message
    $TextBox1.ReadOnly               = $True

    $Button1                         = New-Object system.Windows.Forms.Button
    $Button1.text                    = "Ok"
    $Button1.width                   = 60
    $Button1.height                  = 30
    $Button1.location                = New-Object System.Drawing.Point(500,300)
    $Button1.Font                    = 'Segoe UI,12'

    
    $Form.controls.AddRange(@($TextBox1))

    #$Form.controls.AddRange(@($TextBox1,$pic))

    $script:MainForm_textbox1 = $textbox1.Text

    [void]$Form.Show()

    return $Form

}

$ImageLocation = "C:\Windows\Temp\PSDBackground.bmp"
$PSDBackgroundInfo = Show-PSDBackgroundInfo -Message "Preparing Windows Autopilot" -ImagePath $ImageLocation 
Start-Sleep -Seconds 10
$PSDBackgroundInfo.Close()
### Auth
$Username = 'MDT_BA'
$Password = 'P@ssw0rd'
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$pass

$bytes = [System.Text.Encoding]::UTF8.GetBytes(
    ('{0}:{1}' -f $Cred.UserName, $Cred.GetNetworkCredential().Password)
)
$Authorization = 'Basic {0}' -f ([Convert]::ToBase64String($bytes))
$Headers = @{ Authorization = $Authorization }
### Auth


# Upload the JSON object to the Autopilot registration webservice script on your deployment server
# Max allowed time is 30 minutes
$DeployRootUri = [System.Uri]"$DeployRoot)"
#$RestPSServer = $DeployRootUri.Host 
$RestPSServer = "mdt04.corp.viamonstra.com" 
$RestPSMethod = "RPSDAutopilotRegistration"
$RestPSPort = "8080"
Write-Log -Message "Connecting to $RestPSServer on port $RestPSPort, using method $RestPSMethod"
$Return = Invoke-RestMethod -Method POST -Uri "http://$RestPSServer`:$RestPSPort/$RestPSMethod" -Body $AutopilotJSON -TimeoutSec 1800 -Headers $Headers 

Write-Log "Webservice returned: $Return" 

# Close the splash screen
$PSDBackgroundInfo.Close()





