#Script relies on IntuneWin32App module from Nickolaj Andersen (https://github.com/MSEndpointMgr/IntuneWin32App) 
#App registration requires DeviceManagementApps.ReadWrite.All,DeviceManagementConfiguration.ReadWrite.All,DeviceManagementRBAC.Read.All,Group.Read.All

$TenantID = ""
$ClientID = ""
$ClientSecret = ""

#Create Application
Connect-MSIntuneGraph -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret

$Name = 'Notepad++ 8.9.1 x64 - Intune Internals Demo'
$Description = 'Text Editor'
$Publisher = 'Don Ho'
$packagePath = 'C:\Demo\Intune\Win32Apps\Notepad++\Package'
$File = 'npp.8.9.1.Installer.x64.intunewin'
$InstallationParameters = 'npp.8.9.1.Installer.x64.exe /S'
$UninstallationCommand = '"%ProgramFiles%\Notepad++\uninstall.exe" /S"'
$installedPath = "%ProgramFiles%\Notepad++"
$installedName = "notepad++.exe"
$Version = '8.9.1'

$detectionRule = New-IntuneWin32AppDetectionRuleFile -Existence -Path $installedPath -FileOrFolder $installedName -Check32BitOn64System $false -DetectionType "exists"
$requirementRule = New-IntuneWin32AppRequirementRule -Architecture x64 -MinimumSupportedWindowsRelease W10_2004


Add-IntuneWin32App -FilePath (Join-Path -Path $packagePath -ChildPath $File) `
    -DisplayName $Name `
    -Description $Description `
    -Publisher $Publisher `
    -InstallExperience system `
    -RestartBehavior suppress `
    -DetectionRule $detectionRule `
    -RequirementRule $requirementRule `
    -InstallCommandLine $InstallationParameters `
    -UninstallCommandLine $UninstallationCommand `
    -AppVersion $Version `
    -Verbose


#Create Entra ID group and add a user
#Find-MgGraphCommand -command Get-MgUser | Select -First 1 -ExpandProperty Permissions

$Scopes = @(
    "User.ReadWrite.All"
    "Group.ReadWrite.All"
)

Connect-MgGraph -TenantId $TenantID -Scopes $Scopes -UseDeviceCode

$groupName = "sg-cmp-Notepad++ (Required)"
$groupNickname = "notepadplusplus"
$deviceId = Get-MgDevice -Filter "displayName eq 'PC-001'"

$newAppGroup = New-MgGroup -DisplayName $groupName -MailEnabled:$False -MailNickname $groupNickname -SecurityEnabled
New-MgGroupMember -GroupId $newAppGroup.Id -DirectoryObjectId $deviceId.Id

#Assign Win32App
$App = $null
$maxRetries = 30
$retryDelaySeconds = 10
$retryCount = 0

do {
    $App = Get-IntuneWin32App -DisplayName $Name | Select-Object -First 1

    if (-not $App) {
        Write-Output ("[{0}] Win32 app '{1}' not found yet. Retry {2}/{3} in {4} seconds..." -f (Get-Date -Format s), $Name, ($retryCount + 1), $maxRetries, $retryDelaySeconds)
        Start-Sleep -Seconds $retryDelaySeconds
        $retryCount++
    }
} while (-not $App -and $retryCount -lt $maxRetries)

if (-not $App) {
    throw "Win32 app '$Name' was not found after $($maxRetries * $retryDelaySeconds) seconds."
}

Add-IntuneWin32AppAssignmentGroup -Include -GroupID $newAppGroup.Id -ID $App.Id -Intent required -DeliveryOptimizationPriority foreground