# Create a Win32 App in Microsoft Intune and assign to a device group in Intune
# The script uses/requires the IntuneWin32App module from @nickolaj 
#
# Author: Johan Arwidmark
# Twitter: @jarwidmark
# LinkedIn: https://www.linkedin.com/in/jarwidmark

# Generic Settings
$ApplicationName = "Adobe Acrobat Reader DC - Demo 2"
$Description = "PDF Viewer"
$RootSourceFolderForApplication = "E:\Demo\Intune\Win32Apps\AdobeAcrobatReader\Source" 
$TargetFolder = "E:\Demo\Intune\Win32Apps\AdobeAcrobatReader\Package"
$Publisher = "ViaMonstra"
$Installer = "AcroRdrDC2100720099_en_US.exe"
$InstallCommandLine = "AcroRdrDC2100720099_en_US.exe /sAll /rs /rps /msi /norestart /quiet EULA_ACCEPT=YES"
$UninstallCommandLine = "MsiExec.exe /x {AC76BA86-7AD7-1033-7B44-AC0F074E4100} /qn"
$DeliveryOptimizationPriority = "Foreground" # The NotConfigure option means background priority
$DetectionFile = "AcroRd32.exe"
$DetectionFolder = "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader"
$Architecture = "All"
$MinimumSupportedWindowsRelease = 1909
$AADGroup = "Demo Apps"

# Import Modules
Import-Module -Name IntuneWin32App
# Get-InstalledModule IntuneWin32App 

# Connect to MS Graph
$MSGraph = Connect-MSGraph -ForceInteractive
$TenantID = $MSGraph.TenantId
Connect-MSIntuneGraph -TenantID $TenantID

# Get the Intune group ID
$AADGroupID = (Get-Groups -Filter "DisplayName eq '$AADGroup'").id


# Check for target folder
If (!(Test-Path -Path $TargetFolder)){
    Write-Warning "Specified source folder: $TargetFolder, does not exist, aborting..."
    Break
}

# Check for source folder
If (!(Test-Path -Path $RootSourceFolderForApplication)){
    Write-Warning "Specified source folder: $RootSourceFolderForApplication, does not exist, aborting..."
    Break
}

# Create the Win32 app
$App = $Null
$App = Get-IntuneWin32App -DisplayName $ApplicationName 
If (!($null -eq $App)){
    # App already exists, abort...
    Break
}
Else{
    # App does not exist, go ahead and create it
        
    # Create the IntuneWin Package  
    $IntuneWinFile = New-IntuneWin32AppPackage -SourceFolder $DataSource -SetupFile $Installer -OutputFolder $OutputFolder

    # Create detection rule 
    $DetectionRule = New-IntuneWin32AppDetectionRuleFile -Existence -DetectionType exists -Path $DetectionFolder -FileOrFolder $DetectionFile

    # Create custom requirement rule
    $RequirementRule = New-IntuneWin32AppRequirementRule -Architecture $Architecture -MinimumSupportedWindowsRelease $MinimumSupportedWindowsRelease

    # Add new Win32 app
    $Win32App = Add-IntuneWin32App `
        -FilePath $IntuneWinFile.Path `
        -DisplayName $ApplicationName `
        -Description $Description `
        -Publisher $Publisher `
        -InstallExperience system `
        -RestartBehavior suppress `
        -DetectionRule $DetectionRule `
        -RequirementRule $RequirementRule `
        -InstallCommandLine $InstallCommandLine `
        -UninstallCommandLine $UninstallCommandLine `
        -UseAzCopy -Verbose

    # Assign the Win32 app to the device group
    $Win32AppID = $Win32App.id
    Add-IntuneWin32AppAssignmentGroup -ID $Win32AppID -Include -Intent required -GroupID $AADGroupID -Verbose -DeliveryOptimizationPriority $DeliveryOptimizationPriority
}    


# List the applications   
Get-IntuneWin32App -DisplayName *P2P* | Select-Object DisplayName, size
