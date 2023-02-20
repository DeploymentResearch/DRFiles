Function UserExit(sType, sWhen, sDetail, bSkip) 

UserExit = Success 

End Function 

Function SetName(sMac)

Dim re

Set re = new RegExp
re.IgnoreCase = true
re.Global = true
re.Pattern = ":"
SetName = "PC" & re.Replace(sMac, "")

End Function

