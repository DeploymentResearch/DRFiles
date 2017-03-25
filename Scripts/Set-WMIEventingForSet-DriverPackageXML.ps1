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

        # Create and add more funcitons

        # Create WMI EventFilter
        WMI-InstanceFilter

        # Create WMI InstanceConsumer
        WMI-InstanceConsumer

        # Create WMI FilterToConsumerBinding
        WMI-FilterToConsumerBinding

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

        $Script:LoggingPath = 'c:\Windows\Temp\Set-WMIEventingForSet-DriverPackageXML.log'
        LogTraceMessage "Variable LoggingPath set to $script:LoggingPath"
        Write-Verbose "Variable LoggingPath set to $script:LoggingPath"

        # Add variables here

        $Script:SiteServer = "TEE-CM1.EmptyGarden.btls"
        LogTraceMessage "Variable SiteServer set to $script:SiteServer"
        Write-Verbose "Variable SiteServer set to $script:SiteServer"

        $Script:SiteCode = "TEE"
        LogTraceMessage "Variable SiteCode set to $script:SiteCode"
        Write-Verbose "Variable SiteCode set to $script:SiteCode"

        $Script:ScriptPath = "\\TEE-CM1.EmptyGarden.btls\SCCMPackages$\OSD - Get-DriverPackage\Set-DriverPackageXML.ps1"
        LogTraceMessage "Variable ScriptPath set to $script:ScriptPath"
        Write-Verbose "Variable ScriptPath set to $script:ScriptPath"

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

    Function WMI-InstanceFilter
    {
    	# Function Started
        LogTraceMessage "*** Function WMI-InstanceFilter Started ***"
        Write-Verbose "*** Function WMI-InstanceFilter Started ***"

        $PropertyHash = @{
            QueryLanguage = "WQL";
            Query = "SELECT * FROM __InstanceOperationEvent Within 60 Where TargetInstance ISA 'SMS_Package' and TargetInstance.Name like 'Drivers - %'";
            Name = "SCCM_DriverUpdateXML";
            EventNameSpace="root/sms/site_$($SiteCode)"
            }

        $Script:InstanceFilter = New-CimInstance -Namespace root/subscription -ClassName __EventFilter -Property $PropertyHash -Verbose -ErrorAction Stop 


      	# Function Finished
		LogTraceMessage "*** Function WMI-InstanceFilter Finished ***"
        Write-Verbose "*** Function WMI-InstanceFilter Finished ***"
    }

    Function WMI-InstanceConsumer
    {
    	# Function Started
        LogTraceMessage "*** Function WMI-InstanceConsumer Started ***"
        Write-Verbose "*** Function WMI-InstanceConsumer Started ***"

        $PropertyHash =@{
            Name = "SCCM_DriverUpdateXML";
            ExecutablePath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe";
            CommandLineTemplate="C:\Windows\\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -file `"$ScriptPath`""
            }

        $Script:InstanceConsumer = New-CimInstance -Namespace root/subscription -ClassName CommandLineEventConsumer -Property $PropertyHash -Verbose -ErrorAction Stop

      	# Function Finished
		LogTraceMessage "*** Function WMI-InstanceConsumer Finished ***"
        Write-Verbose "*** Function WMI-InstanceConsumer Finished ***"
    }

    Function WMI-FilterToConsumerBinding
    {
    	# Function Started
        LogTraceMessage "*** Function WMI-FilterToConsumerBinding Started ***"
        Write-Verbose "*** Function WMI-FilterToConsumerBinding Started ***"

        $PropertyHash = @{
            Filter = [ref]$Script:InstanceFilter; 
            Consumer = [ref]$Script:InstanceConsumer
        }
         
        $InstanceBinding= New-CimInstance -Namespace root/subscription -ClassName __FilterToConsumerBinding  -Property $PropertyHash -Verbose -ErrorAction Stop

      	# Function Finished
		LogTraceMessage "*** Function WMI-FilterToConsumerBinding Finished ***"
        Write-Verbose "*** Function WMI-FilterToConsumerBinding Finished ***"
    }

 	Function LogTraceMessage ($strMessage)
	{
		[array]$script:TraceMessage += (Get-Date).ToString() + ':  ' + $strMessage + '~~' 
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