# Name:         Get-DriverPackage
# Description:  Gets the driver package ID for download during a Task Sequence
# Author:       Matthew Teegarden
	
try
{	
    Function Main
	{
		# Function Started
		LogTraceMessage "*** Function Main Started ***"
        Write-Verbose "*** Function Main Started ***"

		# Set Global Environment Variables (Inputs)
		SetGlobalEnvVariables

		# Import PS Modules
		ImportPsModules

        # Set Logging Path
        SetLoggingPath

        # Create and add more funcitons

        # Import Driver Package XML created from SCCM
        ImportDiverPackageXML

        # Get the OS Architecture
        GetOSArchitecture

        # Get the OS Name
        GetOSVersionNumber

        # Get the computer model
        GetModel

        # Get the driver package to download
        GetDriverPackage

		# Function Finished
		LogTraceMessage "*** Function Main Finished ***"
        Write-Verbose "*** Function Main Finished ***"
	}

	Function SetGlobalEnvVariables
	{
		# Function Started
        LogTraceMessage "*** Function SetGlobalEnvVariables Started ***"
        Write-Verbose "*** Function SetGlobalEnvVariables Started ***"

        # Base script variables.  No modification should be necessary

		# Set variables with global scope
		$script:TraceState = ''
		LogTraceMessage "Variable TraceState set to $script:TraceState"
        Write-Verbose "Variable TraceState set to $script:TraceState"

		$script:ErrorMessage = ''
		LogTraceMessage "Variable ErrorMessage set to $script:ErrorMessage"
        Write-Verbose "Variable ErrorMessage set to $script:ErrorMessage"

		$script:ErrorState = 0
		LogTraceMessage "Variable ErrorState set to $script:ErrorState"
        Write-Verbose "Variable ErrorState set to $script:ErrorState"

        #Script variables.  Modify as necessary

        # Add variables here

        $Script:DefaultDriverPacakge = 'TEE00026'
        LogTraceMessage "Variable DefaultDriverPacakge set to $script:DefaultDriverPacakge"
        Write-Verbose "Variable DefaultDriverPacakge set to $script:DefaultDriverPacakge"

 	    # Function Finished
		LogTraceMessage "*** Function SetGlobalEnvVariables Finished ***"
        Write-Verbose "*** Function SetGlobalEnvVariables Finished ***"
	}

	Function ImportPsModules
	{
		# Function Started
        LogTraceMessage "*** Function ImportPsModules Started ***"
        Write-Verbose "*** Function ImportPsModules Started ***"

        $script:tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 

      	# Function Finished
		LogTraceMessage "*** Function ImportPsModules Finished ***"
        Write-Verbose "*** Function ImportPsModules Finished ***"
	}

    Function ImportDiverPackageXML
    {
    	# Function Started
        LogTraceMessage "*** Function ImportDiverPackageXML Started ***"
        Write-Verbose "*** Function ImportDiverPackageXML Started ***"

        $script:Packages = Import-Clixml .\driverpackages.xml

      	# Function Finished
		LogTraceMessage "*** Function ImportDiverPackageXML Finished ***"
        Write-Verbose "*** Function ImportDiverPackageXML Finished ***"
    }

    Function GetOSArchitecture
    {
    	# Function Started
        LogTraceMessage "*** Function GetOSArchitectureL Started ***"
        Write-Verbose "*** Function GetOSArchitecture Started ***"

        $script:OSArchitecture = $script:tsenv.Value("OSArchitecture")
        
        LogTraceMessage "OSArchitecture = $script:OSArchitecture"
        Write-Verbose "OSArchitecture = $script:OSArchitecture"

      	# Function Finished
		LogTraceMessage "*** Function GetOSArchitecture Finished ***"
        Write-Verbose "*** Function GetOSArchitecture Finished ***"
    }

    Function GetOSVersionNumber
    {
    	# Function Started
        LogTraceMessage "*** Function GetOSName Started ***"
        Write-Verbose "*** Function GetOSName Started ***"

        $script:OSVersionNumber = $script:tsenv.Value("OSVersionNumber")
        
        LogTraceMessage "OSVersionNumber = $script:OSVersionNumber"
        Write-Verbose "OSVersionNumber = $script:SVersionNumber"

        If ($script:OSVersionNumber -like "10.*")
        {
            $script:OSVersionNumber = "Win10"
        }
        If ($script:OSVersionNumber -like "6.1*")
        {
            $script:OSVersionNumber = "Win7"
        }

        LogTraceMessage "OSVersionNumber set to $script:OSVersionNumber"
        Write-Verbose "OSVersionNumber set to $script:OSVersionNumber"

      	# Function Finished
		LogTraceMessage "*** Function GetOSName Finished ***"
        Write-Verbose "*** Function GetOSName Finished ***"
    }

    Function GetModel
    {
    	# Function Started
        LogTraceMessage "*** Function ModelStarted ***"
        Write-Verbose "*** Function Model Started ***"

        $script:Model = (Get-CimInstance -ClassName win32_computersystemproduct -Namespace root\cimv2).Name 

        LogTraceMessage "Model = $script:Model"
        Write-Verbose "Model = $script:Model"

      	# Function Finished
		LogTraceMessage "*** Function Model Finished ***"
        Write-Verbose "*** Function Model Finished ***"
    }

    Function GetDriverPackage
    {
    	# Function Started
        LogTraceMessage "*** Function GetDriverPackage ***"
        Write-Verbose "*** Function GetDriverPackage Started ***"

        Foreach ($i in $script:Packages)
        {
            If ($i.name -like "*" + $script:model + "*" -and $i.name -like "*" + $script:OSVersionNumber + "*" -and $i.name -like "*" + $script:OSArchitecture + "*")
            {
                $script:tsenv.Value('OSDDownloadDownloadPackages') = $i.PackageID
                $script:TSOSDDownloadDownloadPackages =  $script:tsenv.Value('OSDDownloadDownloadPackages')
                LogTraceMessage "TSOSDDownloadDownloadPackages = $script:TSOSDDownloadDownloadPackages"
                Write-Verbose "TSOSDDownloadDownloadPackages $script:TSOSDDownloadDownloadPackages"
                
                $script:tsenv.Value("DriverPackageToDownload") = $i.PackageID
                $script:TSDefaultDriverPacakge = $script:tsenv.Value("DriverPackageToDownload")
                LogTraceMessage "TSDefaultDriverPacakge changed to $script:TSDefaultDriverPacakge"
                Write-Verbose "TSDefaultDriverPacakge changed to  $script:TSDefaultDriverPacakge"

                $Script:DefaultDriverPacakge = $i.PackageID
            }
        }

        If ($Script:DefaultDriverPacakge -eq 'TEE00026')
        {
            $script:tsenv.Value("DriverPackageToDownload") = $Script:DefaultDriverPacakge
            $script:TSDefaultDriverPacakge = $script:tsenv.Value("DriverPackageToDownload")
            LogTraceMessage "Default driver package to download = $script:TSDefaultDriverPacakge"
            Write-Verbose "Default driver package to download = $script:TSDefaultDriverPacakge"
        }
  
        
      	# Function Finished
		LogTraceMessage "*** Function GetDriverPackage Finished ***"
        Write-Verbose "*** Function GetDriverPackage Finished ***"
    }

 	Function LogTraceMessage ($strMessage)
	{
		[array]$script:TraceMessage += (Get-Date).ToString() + ':  ' + $strMessage + '~~' 
    }
    
    Function SetLoggingPath
    {
        # Function Started
        LogTraceMessage "*** Function SetLoggingPath ***"
        Write-Verbose "*** Function SetLoggingPath Started ***"

        $script:LoggingPath = $script:tsenv.Value("OSDTargetSystemDrive") + "\windows\temp\Get-DriverPackages.log"

        LogTraceMessage "SetLoggingPath = $script:LoggingPath"
        Write-Verbose "SetLoggingPath = $script:LoggingPath"

        # Function Finished
        LogTraceMessage "*** Function SetLoggingPath Finished ***"
        Write-Verbose "*** Function SetLoggingPath Finished ***"
    }
    
 	# Script Started
	LogTraceMessage "*** Get-DriverPacakge ***"
    Write-Verbose "*** Get-DriverPacakge ***"

	#Main
	Main
	
}

Catch
{
	# Catch Started
	LogTraceMessage "*** Catch Started ***"
    Write-Verbose "*** Catch Started ***"
	
	# Log error messages
	$script:ErrorMessage = $Error[0].Exception.ToString()
	LogTraceMessage "Variable ErrorMessage set to $script:ErrorMessage"
    Write-Verbose "Variable ErrorMessage set to $script:ErrorMessage"
	
	$script:ErrorState = 3
	LogTraceMessage "Variable ErrorState set to $script:ErrorState"
    Write-Verbose "Variable ErrorState set to $script:ErrorState"
	
	# Catch Finished
	LogTraceMessage "*** Catch Finished ***"
    Write-Verbose "*** Catch Finished ***"
}

Finally
{
	# Finally Started
	LogTraceMessage "*** Finally Started ***"
    Write-Verbose "*** Finally Started ***" 

	# Log Error State/Message
	LogTraceMessage "Variable ErrorState = $script:ErrorState"
    Write-Verbose  "Variable ErrorState = $script:ErrorState"
	
	# Finally Finished
	LogTraceMessage "*** Finally Finished ***"
	Write-Verbose "*** Finally Finished ***"
	# Script Finished
	LogTraceMessage "*** Get-DriverPacakge Finished ***"
    Write-Verbose "*** Get-DriverPacakgefinished Finished ***"

    # Write to log file
    $script:TraceMessage | Out-File $script:LoggingPath

}