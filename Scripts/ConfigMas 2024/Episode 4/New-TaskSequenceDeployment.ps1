<#
.SYNOPSIS
    Creates a ConfigMgr task sequence deployment to a collection.
.DESCRIPTION
    Deploys the named task sequence to the named collection, as a step in automating a mass
    deployment lab run.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark / deploymentresearch.com
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2025-01-05 - Initial release
#>

# Set variables
$SiteCode = "PS1"
$TaskSequenceName = "Windows 11 Enterprise x64 23H2 MDM BranchCache"
$CollectionName = "MassDeployment - Windows 11 Enterprise x64 23H2"

# Import ConfigMgr Module
Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
Set-Location "$SiteCode`:"

# Get task sequence object for deploymemt
$TS = Get-CMTaskSequence -Name $TaskSequenceName -Fast

# Configure settings for task sequence deployment
# For more settings, see https://learn.microsoft.com/en-us/powershell/module/configurationmanager/new-cmtasksequencedeployment?view=sccm-ps
$TSDeploy_Params = @{
    InputObject                 = $TS
    CollectionName              = $CollectionName
    Availability                = "MediaAndPxe"
    DeployPurpose               = "Required"
    ScheduleEvent               = "AsSoonAsPossible"
    ShowTaskSequenceProgress    = $true
    RerunBehavior               = "RerunIfFailedPreviousAttempt"
    DeploymentOption            = "DownloadContentLocallyWhenNeededByRunningTaskSequence"
    InternetOption              = $false
}

# Create task sequence deployment
New-CMTaskSequenceDeployment @TSDeploy_Params
