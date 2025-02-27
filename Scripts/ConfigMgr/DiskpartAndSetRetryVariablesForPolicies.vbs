On Error Resume Next 
Dim oShell, oFso
Set oShell = CreateObject("WScript.Shell")
Set oFso = CreateObject("Scripting.FileSystemObject") 

intReturn = oShell.Popup("Do you want to wipe the hard drive", 10, "OS Deployment", vbYesNo + vbQuestion)

If (intReturn = vbYes) Then
    	'Wscript.Echo "Yes was clicked, wipe the disk"
	oShell.Run "diskpart.exe /s x:\diskpart.ini",,true
End If

If (intReturn = vbNo) Then
    	'Wscript.Echo "No was clicked, do nothing"
	' Do nothing
End If

If (intReturn = -1) Then
    	'Wscript.Echo "Dialog timed out, do nothing"
	' Do nothing	
End If

set env = CreateObject("Microsoft.SMS.TSEnvironment")
env("SMSTSAssignmentsDownloadInterval") = "10"
env("SMSTSAssignmentsDownloadRetry") = "5"