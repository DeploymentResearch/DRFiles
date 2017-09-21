<#
Created:	 2014-01-08
Version:	 1.1
Author       Mikael Nystrom and Johan Arwidmark       
Homepage:    http://www.deploymentfundamentals.com
Credits:     Brian Wilhite

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and 
is not supported by the authors or DeploymentArtist.

Author - Mikael Nystrom
    Twitter: @mikael_nystrom
    Blog   : http://deploymentbunny.com

Author - Johan Arwidmark
    Twitter: @jarwidmark
    Blog   : http://deploymentresearch.com
#>

Function Check-PendingReboot{

    $computername = $env:COMPUTERNAME

    # Connection to local or remote Registry
    $RegConnection = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"LocalMachine",$computername)

    # Query the Component Based Servicing Registry Key
    $RegSubKeysCBS = $RegConnection.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\").GetSubKeyNames()
    $CBSRebootPend = $RegSubKeysCBS -contains "RebootPending"

    # Query the Windows Update Auto Update Registry Key
    $RegWUAU = $RegConnection.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
    $RegWUAURebootReq = $RegWUAU.GetSubKeyNames()
    $WUAURebootReq = $RegWUAURebootReq -contains "RebootRequired"
						
    # Query the PendingFileRenameOperations Registry Key
    $RegSubKeySM = $RegConnection.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\")
    $RegValuePFRO = $RegSubKeySM.GetValue("PendingFileRenameOperations",$null)

    # Closing registry connection
    $RegConnection.Close()

    # If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true
    If ($RegValuePFRO)
	    {
		    $PendFileRename = $true

	    }

    # Check if any of the variables are true
    If ($CBSRebootPend -or $WUAURebootReq -or $PendFileRename)
	    {
            Write-Output "There is a pending reboot for $computername"
            Write-Output "Please reboot $computername"
	    }
						
    Else 
        {
            Write-Output "No reboot is pending for $computername"

        }
}
. Check-PendingReboot
