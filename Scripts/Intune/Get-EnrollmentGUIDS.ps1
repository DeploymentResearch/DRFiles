<#
.SYNOPSIS
    Lists the MDM enrollment GUIDs on a device.
.DESCRIPTION
    Reads the Enrollments registry key and reports the enrollment ID, user principal name, MDM
    server, and enrollment type for each entry.
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
      1.0.0 - 2026-04-14 - Initial release
#>

Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" |
  ForEach-Object {
    $props = Get-ItemProperty $_.PSPath
    [PSCustomObject]@{
      EnrollmentID = $_.PSChildName
      UPN          = $props.UPN
      MDMServer    = $props.ProviderID
      EnrollType   = $props.EnrollmentType
    }
  } | Format-Table -AutoSize
