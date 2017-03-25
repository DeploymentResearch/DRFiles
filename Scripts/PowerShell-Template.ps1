# Name:         PowerShell Template
# Description:  Standard PowerShell template
# Author:       
	
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

        # Create and add more funcitons

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

        $Script:LoggingPath = 'c:\Windows\Temp\Set-DriverPackageXML.log'
        LogTraceMessage "Variable LoggingPath set to $script:LoggingPath"
        Write-Verbose "Variable LoggingPath set to $script:LoggingPath"

        # Add variables here

 	    # Function Finished
		LogTraceMessage "*** Function SetGlobalEnvVariables Finished ***"
        Write-Verbose "*** Function SetGlobalEnvVariables Finished ***"
	}

	Function ImportPsModules
	{
		# Function Started
        LogTraceMessage "*** Function ImportPsModules Started ***"
        Write-Verbose "*** Function ImportPsModules Started ***"

      	# Function Finished
		LogTraceMessage "*** Function ImportPsModules Finished ***"
        Write-Verbose "*** Function ImportPsModules Finished ***"
	}

 	Function LogTraceMessage ($strMessage)
	{
		[array]$script:TraceMessage += (Get-Date).ToString() + ':  ' + $strMessage + '~~' 
    }
    
 	# Script Started
	LogTraceMessage "*** Set Driver Pacakge XML ***"
    Write-Verbose "*** Set Driver Pacakge XML ***"

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
	LogTraceMessage "*** Name of script Finished ***"
    Write-Verbose "*** name of script finished Finished ***"

    # Write to log file
    $script:TraceMessage | Out-File $script:LoggingPath

} 
