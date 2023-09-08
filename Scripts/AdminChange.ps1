# Setting variables for new and old admin accounts.
$OldAdminName = "Alpha"
$NewAdminName = "Beta"
$Password = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force

# Set Log File Location
$Logfile = "C:\Windows\Temp\AdminChange.log"

# Delete any existing logfile if it exists
If (Test-Path $Logfile){Remove-Item $Logfile -Force -ErrorAction SilentlyContinue -Confirm:$false}

# Simple logging function
Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
   )

   $TimeGenerated = $(Get-Date -UFormat "%D %T")
   $Line = "$TimeGenerated : $Message"
   Add-Content -Value $Line -Path $LogFile -Encoding Ascii

}

# Rename Administrator
Write-Log "Renaming current Administrator account to $OldAdminName"
try {
    $CurrentAdminName = Get-LocalUser | Where-Object { $_.SID -like "S-1-5-*-500" } -ErrorAction Stop
    Write-Log "Current Administrator name is: $CurrentAdminName"
    Write-Log "Current Administrator SID is: $($CurrentAdminName.SID.Value)"
    Rename-LocalUser -Name $CurrentAdminName -NewName $OldAdminName  -ErrorAction Stop
    Write-Log "$CurrentAdminName renamed to $OldAdminName"

}
catch{
    $errorMessage = $_.Exception.Message
    write-Log "Command Failed, error message: $errorMessage"
    Write-Log "Aborting script..."
    Break
}

# Disable the renamed admin account 
Write-Log "Disable the renamed admin account "
try {
    $RenamedAdminaccount = Get-LocalUser -SID $CurrentAdminName.SID.Value -ErrorAction Stop
    Write-Log "Renamed Administrator name is: $RenamedAdminaccount"
    Write-Log "Renamed Administrator SID is: $($RenamedAdminaccount.SID.Value)"
    Disable-LocalUser -SID $RenamedAdminaccount.SID.Value  -ErrorAction Stop
    Write-Log "$RenamedAdminaccount disabled"

}
catch{
    $errorMessage = $_.Exception.Message
    write-Log "Command Failed, error message: $errorMessage"
    Write-Log "Aborting script..."
    Break
}


# Create new Account, set password to not expire.
Write-Log "Create new Account named $NewAdminName"
try {
    New-LocalUser -name $NewAdminName -password $Password -PasswordNeverExpires:$true -ErrorAction Stop
    Write-Log "New account created"

}
catch{
    $errorMessage = $_.Exception.Message
    write-Log "Command Failed, error message: $errorMessage"
    Write-Log "Aborting script..."
    Break
}

# Add new account to Administrators group
Write-Log "Add $NewAdminName to Administrators group"
try {
    $AdminGroup = Get-Localgroup | Where-Object { $_.SID -like "S-1-5-*-544" } -ErrorAction Stop
    Write-Log "Local adminstrators group name is: $AdminGroup"
    Write-Log "Local adminstrators group SID is: $($AdminGroup.SID.Value)"
    Add-LocalGroupMember -Group $AdminGroup -Member $NewAdminName -ErrorAction Stop
    Write-Log "$NewAdminName added to local adminstrators group: $AdminGroup"

}
catch{
    $errorMessage = $_.Exception.Message
    write-Log "Command Failed, error message: $errorMessage"
    Write-Log "Aborting script..."
    Break
}

