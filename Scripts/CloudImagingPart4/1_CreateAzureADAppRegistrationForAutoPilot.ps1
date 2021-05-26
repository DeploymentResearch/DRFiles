#
# Written by Johan Arwidmark, @jarwidmark on Twitter
#
# Script to create an Azure AD App Registration with permissions to work with Windows Autopilot
# Requires Global Admin Permissions in Azure AD and Intune, and local administrator rights on the computer

# Script Variables
$LogFile = "C:\Windows\Temp\1_CreateAzureADAppRegistration.log"
$AppName = "Windows Autopilot Demo Setup"
$AppInfoExportFile = "C:\Windows\Temp\AppInfo.txt"


# Delete any existing logfile if it exists
If (Test-Path $Logfile){Remove-Item $Logfile -Force -ErrorAction SilentlyContinue -Confirm:$false}

Function Write-Log{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message
   )

   $TimeGenerated = $(Get-Date -UFormat "%D %T")
   $Line = "$TimeGenerated : $Message"
   Add-Content -Value $Line -Path $LogFile -Encoding Ascii

}

# Install Nuget
Write-Log "Installing Nuget"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Confirm:$false -Force

# Install the WindowsAutopilotInfo PowerShell module
# This will also install the AzureAD and Microsoft.Graph.Intune PowerShell modules
Write-Log "Installing Azure AD PowerShell Module"
Install-Module WindowsAutoPilotIntune -Force

# Connect to Azure AD
#
# Note: If your account has access to multiple tenants, then you need to supply the tenantId as well.
# Connect-AzureAD -Credential $AzureAdCred -TenantId "1499315f-260f-4e76-80db-06c4e5a2bdba"
Import-Module AzureAD
Write-Log "Asking for Azure AD Credentials"
$AzureAdCred = Get-Credential
$UserName = $AzureAdCred.UserName
Write-Log "Username specified was $UserName"
Write-Log "Connecting to Azure AD"
Connect-AzureAD -Credential $AzureAdCred 

# Verify Azure AD Connection
try { 
    $Tenant = Get-AzureADTenantDetail 
} 
catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] { 
    Write-Log "You're not connected to AzureAD"; 
    exit;
}

$TenantName = $Tenant.DisplayName
$TenantInitialDomain = ($tenant.VerifiedDomains | Where-Object { $_.Initial }).Name

Write-Log "Connected to Azure AD Tenant: $TenantName"
Write-Log "Tenant Initial Domain is $TenantInitialDomain"

# Create Azure AD App Registration
Try {
    Write-Log "Creating Azure AD App Registration"
    Write-Log "Verifying if App Registration: $AppName already exists"

    If (Get-AzureADApplication -Filter "DisplayName eq '$($AppName)'" -ErrorAction SilentlyContinue){
        Write-Log "An application with the name $($AppName) already exist, aborting script..."
        Break
    }
    Else{

        Write-Log "All OK, App Registration: $AppName does not exist,go ahead and creating it "

        # Assign Microsoft Graph Permissions to the App Registration
        # Note: Scope = Delegated permission
        # Note: Role = Application permission
        #

        # Get the Service Principal object for Microsoft Graph. 
        $svcprincipalMSGraph = Get-AzureADServicePrincipal -All $true | ? { $_.DisplayName -eq "Microsoft Graph" }
    
        # Set permissions
        $Type = "Microsoft.Open.AzureAD.Model.ResourceAccess"
        $AppPermission1 = New-Object -TypeName $Type -ArgumentList "19dbc75e-c2e2-444c-a770-ec69d8559fc7","Role" # Permission: Directory.ReadWrite.All (Read and write directory data)
        $AppPermission2 = New-Object -TypeName $Type -ArgumentList "62a82d76-70ea-41e2-9197-370581804d09","Role" # Permission: Group.ReadWrite.All (Read and write all groups)
        $AppPermission3 = New-Object -TypeName $Type -ArgumentList "5ac13192-7ace-4fcf-b828-1a26f28068ee","Role" # Permission: DeviceManagementServiceConfig.ReadWrite.All (Read and write Microsoft Intune configuration)
        $AppPermission4 = New-Object -TypeName $Type -ArgumentList "dbaae8cf-10b5-4b86-a4a1-f871c94c6695","Role" # Permission: GroupMember.ReadWrite.All (Read and write group memberships)
        $AppPermission5 = New-Object -TypeName $Type -ArgumentList "9241abd9-d0e6-425a-bd4f-47ba86e767a4","Role" # Permission: DeviceManagementConfiguration.ReadWrite.All (Read and write Microsoft Intune device configuration and policies)
        $AppPermission6 = New-Object -TypeName $Type -ArgumentList "243333ab-4d21-40cb-a475-36241daa0842","Role" # Permission: DeviceManagementManagedDevices.ReadWrite.All (Read and write Microsoft Intune devices)
       
        # Create a Resource Access resource object (permissions object) and assign the Microsoft Graph service principal’s App ID to it.
        $MSGraphPermissions = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
        $MSGraphPermissions.ResourceAppId = $svcprincipalMSGraph.AppId
        $MSGraphPermissions.ResourceAccess = $AppPermission1, $AppPermission2 , $AppPermission3, $AppPermission4, $AppPermission5, $AppPermission6

        # Create the Azure AD App registration
        $AppRegistration = New-AzureADApplication -DisplayName $appName -RequiredResourceAccess $MSGraphPermissions
        $AppID = $AppRegistration.AppId
        Write-Log "App Registration created with client Id (AppId): $AppID"

        # Create the Service Principal for the application
        # $svcprincipalApp =  New-AzureADServicePrincipal -AppId $AppRegistration.AppId
        #Write-Log "Service Principal created display name: $($svcprincipalApp.DisplayName)"

        # Add an owner to the App Registration
        Write-Log "Add an owner to the App Registration"
        $AzureADAdmin = Get-AzureADUser -ObjectID $UserName
        Add-AzureADApplicationOwner -ObjectId $AppRegistration.ObjectId -RefObjectId $AzureADAdmin.ObjectId

        # Create Application Password Credentials (ClientSecret), expire Date set to 2 Years 
        Write-Log "Create Application Password Credentials (ClientSecret), expire Date set to 2 Years"
        $StartDate = Get-Date
        $EndDate = $startDate.AddYears(2)
        $ClientSecret = New-AzureADApplicationPasswordCredential -ObjectId $AppRegistration.ObjectId -CustomKeyIdentifier "Primary" -StartDate $startDate -EndDate $EndDate

        # Save the tenant info, application info and secret key to a text file for later retrieval by other scripts
        Write-Log "Saving Tenant and Application Info to $AppInfoExportFile"
        $AppInfo = New-Object System.Collections.Specialized.OrderedDictionary
        $AppInfo.Add("TenantName",$TenantName)
        $AppInfo.Add("TenantInitialDomain",$TenantInitialDomain)
        $AppInfo.Add("AppName", $appName)
        $AppInfo.Add("AppID", $AppID)
        $AppInfo.Add("ClientSecret", $ClientSecret.Value)

        $CSVObject = New-Object -TypeName psobject -Property $AppInfo
        $CSVObject | Export-Csv -Path $AppInfoExportFile -NoTypeInformation

        # Set the required resource access object to the application id so permissions can be assigned.
        # Set-AzureADApplication -ObjectId $AppRegistration.ObjectId -RequiredResourceAccess $MSGraph

        #
        # TBA: Grant consent, for now do it manually
        #
    }
}
Catch {
        
    Write-Log $Error[0].exception.message         
}