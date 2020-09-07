Function UserExit(sType, sWhen, sDetail, bSkip) 
  UserExit = Success 
End Function

' Add support for Windows ADK 2004, making command prompts not showing in the remote viewer unless forced to use old layout
If oEnvironment.Item("OSCurrentBuild") >= 19041 Then
	oShell.RegWrite "HKCU\Console\ForceV2","0","REG_DWORD"
End if 
