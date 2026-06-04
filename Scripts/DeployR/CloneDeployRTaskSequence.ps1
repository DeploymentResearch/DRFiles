# Sample DeployR Script to clone a task sequence
# Run without parameter to prompt for a list of task sequences.
# Credits: Gary Blok

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false, HelpMessage = 'Name of the Task Sequence to clone. If omitted, a grid view appears for selection.')]
    [string]$TS2CloneName
)

#region Import and connect
if (Test-Path -Path 'C:\Program Files\2Pint Software\DeployR\Client\PSModules\DeployR.Utility') {
	Import-Module 'C:\Program Files\2Pint Software\DeployR\Client\PSModules\DeployR.Utility' -ErrorAction Stop
}
elseif (Get-Module -ListAvailable -Name DeployR.Utility) {
	Import-Module DeployR.Utility -ErrorAction Stop
}
else {
	throw 'DeployR.Utility module not found. Install the DeployR client or update -DeployRModulePath.'
}

if (Test-Path 'HKLM:\SOFTWARE\2Pint Software\DeployR\GeneralSettings') {
	$DeployRReg = Get-Item -Path 'HKLM:\SOFTWARE\2Pint Software\DeployR\GeneralSettings'
	$ClientPasscode = $DeployRReg.GetValue('ClientPasscode')
	if ($ClientPasscode) {
		Connect-DeployR -Passcode $ClientPasscode -ErrorAction Stop
	}
	else {
		Connect-DeployR -ErrorAction Stop
	}
}
else {
	Connect-DeployR -ErrorAction Stop
}
#endregion

#region Gather DeployR Content Location
#Grab DeployR Content Location from registry for use in content item creation and task sequence cloning examples below.
$DeployRRegPath = 'HKLM:\SOFTWARE\2Pint Software\DeployR\GeneralSettings'
if (Test-Path -Path $DeployRRegPath) {
    $DeployRReg = Get-Item -Path $DeployRRegPath
    $DeployRCILocation = $DeployRReg.GetValue('ContentLocation')
    if (-not $DeployRCILocation) {
        throw 'ContentLocation value not found in registry. Update the registry or set $DeployRCILocation manually.'
    }
}
else {
    throw 'DeployR general settings registry key not found. Update the registry or set $DeployRCILocation manually.'
}
$TempLocation = "$DeployRCILocation\Temp"
if (-not (Test-Path -Path $TempLocation)) {
    Write-Host "Temp Location $TempLocation does not exist. exiting..."
    exit
}

#endregion

#Clone a DeployR Task Sequence - look up by name if provided, otherwise show a grid view
if ($TS2CloneName) {
	$SelectedTS = Get-DeployRTaskSequence | Where-Object { $_.Name -eq $TS2CloneName } | Select-Object -First 1
	if (-not $SelectedTS) {
		Write-Warning "No Task Sequence found with name: $TS2CloneName"
		Write-Warning "Aborting script..."
		return
	}
}
else {
	$SelectedTS = Get-DeployRTaskSequence |
		Select-Object Name, Id, Description,
			@{ Name = 'Created'; Expression = { [DateTimeOffset]::FromUnixTimeSeconds($_.createdDate).LocalDateTime } },
			@{ Name = 'Modified'; Expression = { [DateTimeOffset]::FromUnixTimeSeconds($_.lastModifiedDate).LocalDateTime } } |
		Sort-Object Name |
		Out-GridView -Title 'Select a Task Sequence to Clone' -OutputMode Single

	if (-not $SelectedTS) {
		Write-Warning "No Task Sequence selected. Aborting script..."
		return
	}
}

$TS2CloneID = $SelectedTS.Id
Write-Host "Selected: $($SelectedTS.Name) ($TS2CloneID)"

$TS2CloneMetaData = Get-DeployRTaskSequence -Id $TS2CloneID 

#Export the task sequence to a temporary location, then import it back as a clone. 
Export-DeployRTaskSequence -Id $TS2CloneID -DestinationFolder $TempLocation
#The exported file is filtered by the original TS ID to ensure we get the correct one if there are multiple exports in the temp folder.
$ExportedTSFile = Get-ChildItem -Path $TempLocation -Filter '*.json' | Where-Object {$_.Name -match $TS2CloneID}
#Import the task sequence back as a clone. The new TS will have the same name as the original, just new time stamp and new GUID.
$ImportTS = Import-DeployRTaskSequence -SourceFile $ExportedTSFile.FullName -Clone

#Update the Name to append "Clone"
$ClonedTS = Get-DeployRTaskSequence -Id $ImportTS.Id
$ClonedTS.name = "$($TS2CloneMetaData.name) - Clone"
Set-DeployRMetadata -Type TaskSequence -Object $ClonedTS
