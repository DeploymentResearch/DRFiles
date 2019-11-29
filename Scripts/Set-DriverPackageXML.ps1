# Name:         Set-DriverPackageXML
# Description:  updates the DriverPackage XML file whenever a package status changes according to Satatus Filter Rule Set-DriverPackageXML
# Author:       Matthew Teegarden
	
try
{	
    Function Main
	{
		# Function Started
		LogTraceMessage "*** Function Main Started ***"

		# Set Global Environment Variables (Inputs)
		SetGlobalEnvVariables

		# Import PS Modules
		ImportPsModules

        # Export Driver Packages to XML
        ExportDriverPackageXML

        # Update OSD - Set-DriverPackageXML package
        UpdateSCCMPackage

		# Function Finished
		LogTraceMessage "*** Function Main Finished ***"
	}

	Function SetGlobalEnvVariables
	{
		# Function Started
        LogTraceMessage "*** Function SetGlobalEnvVariables Started ***"

        # Base script variables.  No modification should be necessary

		# Set variables with global scope
		$script:TraceState = ''
		LogTraceMessage "Variable TraceState set to $script:TraceState"

		$script:ErrorMessage = ''
		LogTraceMessage "Variable ErrorMessage set to $script:ErrorMessage"

		$script:ErrorState = 0
		LogTraceMessage "Variable ErrorState set to $script:ErrorState"

        #Script variables.  Modify as necessary

        $Script:LoggingPath = 'c:\Windows\Temp\Set-DriverPackageXML.log'
        LogTraceMessage "Variable LoggingPath set to $script:LoggingPath"

        $script:ConfigurationManagerModule = 'ConfigurationManager'
        LogTraceMessage "Variable ConfigurationManagerModule set to $script:ConfigurationManagerModule"

        $Script:ConfigurationManagerModulePath = 'E:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
        LogTraceMessage "Variable ConfigurationManagerModulePath set to $script:ConfigurationManagerModulePath"

        $script:SQLPSModule = 'SQLPS'
        LogTraceMessage "Variable SQLPSModule set to $script:SQLPSModule"

        $script:DriverPackageID = 'TEE0001D'
        LogTraceMessage "Variable DriverPackageID set to $script:DriverPackageID"

        $script:SCCMSiteCode = 'TEE'
        LogTraceMessage "Variable SCCMSiteCode set to $script:SCCMSiteCode"

        $script:SCCMDB = 'CM_TEE'
        LogTraceMessage "Variable SCCMDB set to $script:SCCMDB"

        $script:SCCMServerFQDN = 'TEE-CM1.EmptyGarden.btls'
        LogTraceMessage "Variable SCCMServerFQDN set to $script:SCCMServerFQDN"

        $script:XMLPackagePath = '\\TEE-CM1.EmptyGarden.btls\SCCMPackages$\OSD - Get-DriverPackage\driverpackages.xml'
        LogTraceMessage "Variable XMLPackagePath set to $script:XMLPackagePath"
  
	    # Function Finished
		LogTraceMessage "*** Function SetGlobalEnvVariables Finished ***"
	}

	Function ImportPsModules
	{
		# Function Started
        LogTraceMessage "*** Function ImportPsModules Started ***"


        If (Get-Module -Name $script:ConfigurationManagerModule) 
        {
            LogTraceMessage "ConfigurationManager module already imported"
        }
        Else
        {
            Import-Module  $Script:ConfigurationManagerModulePath -Force 
		    LogTraceMessage "ConfigurationManager module imported"
        }		


        If (Get-Module -Name $script:SQLPSModule)
        {
            LogTraceMessage "Module SQLPS already imported"
        }
        Else
        {
            Import-Module $script:SQLPSModule -force
		    LogTraceMessage "Module InvokeQueryModule imported"
        }

     	# Function Finished
		LogTraceMessage "*** Function ImportPsModules Finished ***"
	}

    Function ExportDriverPackageXML
    {
        LogTraceMessage "*** Function ExportDriverPackageXML Started ***"

        $SCCMDriverPackages = Invoke-Sqlcmd -Database $script:SCCMDB -Query "Select PackageID, Name from v_Package where name like 'Drivers%' order by name" 
        $SCCMDriverPackages | Export-Clixml -Path $script:XMLPackagePath  -Force
        
        LogTraceMessage "*** Function ExportDriverPackageXML Finished ***"
    }

    Function UpdateSCCMPackage
    {
        LogTraceMessage "*** Function UpdateSCCMPackage Started ***"

        $SCCMDriveLetter = "$($script:SCCMSiteCode):"

        If (-not (Test-Path -Path $SCCMDriveLetter))
	{	    
            $DriveLocation = (Get-Location).drive.name
            LogTraceMessage "DriveLocation before new-psdrive =  $DriveLocation"
            new-psdrive -Name $script:SCCMSiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $script:SCCMServerFQDN
        }
        Set-Location $SCCMDriveLetter
        $SCCMPackage = Get-CMPackage | Where {$_.PackageID -eq $script:DriverPackageID}
        LogTraceMessage "SCCM Package $SCCMPackage.name found"
        
        $SCCMPackage | Update-CMDistributionPoint
        LogTraceMessage "*** Function UpdateSCCMPackage Finished ***"
    }

 
	Function LogTraceMessage ($strMessage)
	{
		[array]$script:TraceMessage += (Get-Date).ToString() + ':  ' + $strMessage + '~~' 
		Write-Verbose -Message $strMessage
    }
    
 	# Script Started
	LogTraceMessage "*** Set Driver Package XML ***"

	#Main
	Main
	
}

Catch
{
	# Catch Started
	LogTraceMessage "*** Catch Started ***"
	
	# Log error messages
	$script:ErrorMessage = $Error[0].Exception.ToString()
	LogTraceMessage "Variable ErrorMessage set to $script:ErrorMessage"
	
	$script:ErrorState = 3
	LogTraceMessage "Variable ErrorState set to $script:ErrorState"
	
	# Catch Finished
	LogTraceMessage "*** Catch Finished ***"
}

Finally
{
	# Finally Started
	LogTraceMessage "*** Finally Started ***"

	# Log Error State/Message
	LogTraceMessage "Variable ErrorState = $script:ErrorState"
	
	# Finally Finished
	LogTraceMessage "*** Finally Finished ***"
	# Script Finished
	LogTraceMessage "*** Set Driver Package XML Finished ***"

    # Write to log file
    $script:TraceMessage | Out-File $script:LoggingPath

}
