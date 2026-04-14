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