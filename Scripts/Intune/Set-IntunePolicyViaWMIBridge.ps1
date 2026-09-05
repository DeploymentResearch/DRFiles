<#
.SYNOPSIS
    Configures an MDM policy locally through the WMI Bridge provider.
.DESCRIPTION
    Creates the policy instance in the MDM namespace directly, which is the supported way to
    test a CSP setting without waiting for an Intune policy assignment.
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
      1.0.0 - 2025-05-21 - Initial release
#>

# Sample to configure a MDM policy via the WMI Bridge
New-CimInstance -Namespace 'root\cimv2\mdm\dmmap' -ClassName 'MDM_Policy_Config01_NetworkListManager02' -Property @{ InstanceID='NetworkListManager'; ParentID='./Vendor/MSFT/Policy/Config'; 'AllowedTlsAuthenticationEndpoints'='<![CDATA[https://mdt01.corp.viamonstra.com]]>' } -ErrorAction Stop
