# Borrowed from https://github.com/petripaavola/IntuneDeviceDetailsGUI
# Thank you Petri

function Invoke-MSGraphGetRequestWithMSGraphAllPages {
    param (
        [Parameter(Mandatory = $true)]
        [String]$url
    )

    $MgGraphRequest = $null
    $AllMSGraphRequest = $null

	Start-Sleep -Milliseconds $TimeOutBetweenGraphAPIRequests

    try {

		# Save results to this variable
		$allGraphAPIData = @()

		do {

			$MgGraphRequest = $null
			$MgGraphRequest = Invoke-MgGraphRequest -Uri $Url -Method 'Get' -OutputType PSObject -ContentType "application/json"

			if($MgGraphRequest) {

				# Test if object has attribute named Value (whether value is null or not)
				#if((Get-Member -inputobject $MgGraphRequest -name 'Value' -Membertype Properties) -and (Get-Member -inputobject $MgGraphRequest -name '@odata.context' -Membertype Properties)) {
				if(Get-Member -inputobject $MgGraphRequest -name 'Value' -Membertype Properties) {
					# Value property exists
					$allGraphAPIData += $MgGraphRequest.Value

					# Check if we have value starting https:// in attribute @odate.nextLink
					# and check that $Top= parameter was NOT used. With $Top= parameter we can limit search results
					# but that almost always results .nextLink being present if there is more data than specified with top
					# If we specified $Top= ourselves then we don't want to fetch nextLink values
					#
					# So get GraphAllPages if there is valid nextlink and $Top= was NOT used in url originally
					if (($MgGraphRequest.'@odata.nextLink' -like 'https://*') -and (-not ($url.Contains('$top=')))) {
						# Save nextLink url to variable and rerun do-loop
						$Url = $MgGraphRequest.'@odata.nextLink'
						Start-Sleep -Milliseconds $TimeOutBetweenGraphAPIRequests

						# Continue to next round in Do-loop
						Continue

					} else {
						# We dont have nextLink value OR
						# $top= exists so we return what we got from first round
						#return $allGraphAPIData
						$Url = $null
					}
					
				} else {
					# Sometimes we get results without Value-attribute (eg. getting user details)
					# We will return all we got as is
					# because there should not be nextLink page in this case ???
					return $MgGraphRequest
				}
			} else {
				# Invoke-MGGraphRequest failed so we return false
				return $null
			}
			
		} while ($Url) # Always run once and continue if there is nextLink value


		# We should not end here but just in case
        return $allGraphAPIData

    } catch {
        Write-Error "There was error with MGGraphRequest with url $url!"
        return $null
    }
}

function Get-BitlockerRecoveryKeys {
	Param(
		[Parameter(Mandatory=$true)]
		$azureADDeviceId
	)

	$BitlockerRecoveryKeyInformationArray = @()

	# Get Bitlocker Recovery keys Key Ids first (without actual Bitlocker Recovery Key value)
	$uri = "https://graph.microsoft.com/beta/informationProtection/bitlocker/recoveryKeys?`$filter=deviceId%20eq%20%27$($azureADDeviceId)%27"
	$BitlockerRecoveryKeyIds = Invoke-MSGraphGetRequestWithMSGraphAllPages $uri

	if($BitlockerRecoveryKeyIds) {

		# We may have multiple Keys so loop each key and get actual RecoveryKey value from each Key
		foreach ($BitlockerRecoveryKeyId in $BitlockerRecoveryKeyIds) {

			# Get each Bitlocker Recovery Key values
			$uri = "https://graph.microsoft.com/beta/informationProtection/bitlocker/recoveryKeys/$($BitlockerRecoveryKeyId.Id)?`$select=key"
			$BitlockerRecoveryKeyIdInformation = Invoke-MSGraphGetRequestWithMSGraphAllPages $uri

			if($BitlockerRecoveryKeyIdInformation) {
				$BitlockerRecoveryKeyInformationArray += $BitlockerRecoveryKeyIdInformation
			}
		}
		
	} else {
		return $null
	}

	return $BitlockerRecoveryKeyInformationArray
}

# Install the module. (You need admin on the machine.)
# Install-Module Microsoft.Graph
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.DeviceManagement
$TenantID = "" # Add your Tenant ID
$TimeOutBetweenGraphAPIRequests = 300

$Scopes = @(
    "DeviceManagementManagedDevices.Read.All",
    "DeviceManagementManagedDevices.ReadWrite.All",
    "DeviceManagementManagedDevices.PrivilegedOperations.All"
)

$Tenant = Connect-MgGraph -TenantId $TenantID -Scopes $Scopes

# Get all Windows Devices
#$Devices = Get-MgDeviceManagementManagedDevice -Filter "contains(operatingsystem, 'Windows')"
$Devices = Get-MgDeviceManagementManagedDevice -Filter "startswith(deviceName, 'DA')" | Sort-Object DeviceName
$Devices | Select DeviceName 

# Get BitLocker Recovery Key
Foreach ($Device in $Devices) {
    Write-Host "Working on $($Device.DeviceName)"
    
    $Result = Get-BitlockerRecoveryKeys -azureADDeviceId $Device.AzureAdDeviceId | Select -First 1
    If ($Result) {
        Write-Host "Recovery Key found" -ForegroundColor Green
        Write-Host "Recovery Key is: $($Result.Key)"
        Write-Host ""
    }

}
