Dim oTSEnv 

Set oTSEnv = CreateObject("Microsoft.SMS.TSEnvironment") 

Dim oVar
    For Each oVar In oTSEnv.GetVariables
        WScript.Echo " "
        WScript.Echo "  "& oVar & vbTab & oTSEnv(oVar) & vbTab
    Next

