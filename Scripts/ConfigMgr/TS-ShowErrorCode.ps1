<#
.SYNOPSIS
    Exits a task sequence step with a custom error code.
.DESCRIPTION
    Reads the ErrorReturnCode task sequence variable and exits with that value, which is a
    quick way to test failure handling and error reporting in a task sequence.
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
      1.0.0 - 2025-07-29 - Initial release
#>

$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
exit $tsenv.Value("ErrorReturnCode")
