<#
.SYNOPSIS
    Checks whether a computer has a reboot pending.
.DESCRIPTION
    Queries the Component Based Servicing, Windows Update, and pending file rename registry
    locations, and returns true when any of them indicate a pending reboot.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Mikael Nystrom and Johan Arwidmark / deploymentresearch.com
    Credits: Brian Wilhite
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.1.0

    Change history:
      1.1.0 - 2022-01-02 - Initial release
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
