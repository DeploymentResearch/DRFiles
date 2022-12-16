# Create P2P Test Applications for Microsoft Intune and assign them to a device group in Intune
# The script will create one application for each first level subfolder in the root source defined by the $RootSourceFolderForApplications variable
# The script uses/requires the IntuneWin32App module from @nickolaj 
#
# Author: Johan Arwidmark
# Twitter: @jarwidmark
# LinkedIn: https://www.linkedin.com/in/jarwidmark

# Generic Settings
$ApplicationPrefix = "P2P Test Application" 
$Description = "P2P Test Application"
$RootSourceFolderForApplications = "E:\Demo\Intune\Win32Apps\P2P Test Applications Source" # Change this to match your environment
$TargetFolder = "E:\Demo\Intune\Win32Apps\P2P Test Applications"
$Publisher = "ViaMonstra"
$Installer = "P2P_Install.ps1"
$Uninstaller = "P2P_Uninstall.ps1"
$DeliveryOptimizationPriority = "Foreground" # The NotConfigure option means background priority

# Import Module
Import-Module -Name IntuneWin32App

# Connect to MS Graph
$MSGraph = Connect-MSGraph -ForceInteractive
$TenantID = $MSGraph.TenantId
Connect-MSIntuneGraph -TenantID $TenantID

# Get the Intune group ID
$aadGroup = "sg-devices ViaMonstra P2P Test Applications" # Change this to your device group
$aadGroupID = (Get-Groups -Filter "DisplayName eq '$aadGroup'").id

# Check for target folder
If (!(Test-Path -Path $TargetFolder)){
    Write-Warning "Specified source folder: $TargetFolder, does not exist, aborting..."
    Break
}

# Check for source folder
If (!(Test-Path -Path $RootSourceFolderForApplications)){
    Write-Warning "Specified source folder: $RootSourceFolderForApplications, does not exist, aborting..."
    Break
}

# Get first level folders (only)
$DataSources = Get-ChildItem $RootSourceFolderForApplications -directory
If (!($DataSources | Measure-Object).count -gt 0) {
    Write-Warning "No subfolders found in source folder: $RootSourceFolderForApplications, aborting..."
    Break
}


# Create the Win32 apps
foreach ($Folder in $DataSources){

    $ApplicationName = "$ApplicationPrefix - $($Folder.Name)"
    $DataSource = $Folder.FullName

    $App = $Null
    $App = Get-IntuneWin32App -DisplayName $ApplicationName 
    If (!($null -eq $App)){
            # Do nothing, app already exists
        }
    Else{
        # App does not exist, go ahead and create it
            
        # Create Installer wrapper script
        $InstallerPath = "$DataSource\$Installer"
        $InstallerScript = "New-Item -Path `"C:\Windows\Temp\$($Folder.Name).txt`" -ItemType File -Force"
        New-Item -Path $InstallerPath -ItemType File -Force
        Set-Content $InstallerPath $InstallerScript

        # Create Uninstaller wrapper script
        $UninstallerPath = "$DataSource\$Uninstaller"
        $UninstallerScript = "Remove-Item -Path `"C:\Windows\Temp\$($Folder.Name).txt`" -Force"
        New-Item -Path $UninstallerPath -ItemType File -Force
        Set-Content $UninstallerPath $UninstallerScript

        # Create the IntuneWin Package  
        $OutputFolder = "$TargetFolder\$ApplicationName"
        If (Test-Path $OutputFolder){Remove-Item -Path $OutputFolder -Recurse -Force}
        New-Item -Path $OutputFolder -ItemType Directory -Force
        $IntuneWinFile = New-IntuneWin32AppPackage -SourceFolder $DataSource -SetupFile $Installer -OutputFolder $OutputFolder

        # Create detection rule 
        $DetectionRule = New-IntuneWin32AppDetectionRuleFile -Existence -DetectionType exists -Path "C:\Windows\Temp" -FileOrFolder "$($Folder.Name).txt"
    
        # Create custom requirement rule
        $RequirementRule = New-IntuneWin32AppRequirementRule -Architecture All -MinimumSupportedOperatingSystem 1909

        # Add new Win32 app
        $InstallCommandLine = "powershell.exe -ExecutionPolicy Bypass -File $Installer"
        $UninstallCommandLine = "powershell.exe -ExecutionPolicy Bypass -File $Uninstaller"
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
            -UninstallCommandLine $UninstallCommandLine
            -UseAzCopy
    
        # Assign the Win32 app to the device group
        $Win32AppID = $Win32App.id
        Add-IntuneWin32AppAssignmentGroup -ID $Win32AppID -Include -Intent required -GroupID $AADGroupID -Verbose -DeliveryOptimizationPriority $DeliveryOptimizationPriority
    }    
}

# List the applications   
Get-IntuneWin32App -DisplayName $ApplicationPrefix | Select-Object DisplayName, size
