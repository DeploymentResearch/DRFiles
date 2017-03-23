'//----------------------------------------------------------------------------
'// Purpose: Custom Script for assign friendly Make and Model alias
'// Version: 1.3 - August 08, 2015 - Johan Arwidmark
'// 
'// Twitter: @jarwidmark
'// Blog   : http://deploymentresearch.com
'//
'// This script is based of Microsoft Sample Code from the deployment guys blog
'// (http://blogs.technet.com/b/deploymentguys) and as such we need to have a 
'// copyright statement. Special thanks goes to Ben Hunter, Michael Murgolo and Steven Markegene. 
'// 
'// Usage: Add the following to your CustomSettings.ini file, and copy the scripts to deployment share / scripts
'// 
'// [Settings]
'// Priority=HardwareInfo
'// Properties=MakeAlias, ModelAlias
'// 
'// [HardwareInfo]
'// UserExit=ModelAliasExit.vbs
'// MakeAlias=#SetMakeAlias()#
'// ModelAlias=#SetModelAlias()#
'//
'// COPYRIGHT STATEMENT
'// This script is provided "AS IS" with no warranties, confers no rights and 
'// is not supported by the authors or Deployment Artist. 
'//----------------------------------------------------------------------------

Function UserExit(sType, sWhen, sDetail, bSkip)

    oLogging.CreateEntry "USEREXIT:ModelAliasExit.vbs started: " & sType & " " & sWhen & " " & sDetail, LogTypeInfo

    UserExit = Success

End Function

Function SetMakeAlias()

    oLogging.CreateEntry "------------ Initialization USEREXIT:ModelAliasExit.vbs|SetMakeAlias -------------", LogTypeInfo

    sMake = oEnvironment.Item("Make")
    SetMakeAlias = ""

    Select Case sMake
	
	        Case "Dell Computer Corporation", "Dell Inc.", "Dell Computer Corp."
            SetMakeAlias = "Dell"
			
	        Case "IBM", "LENOVO"
			SetMakeAlias = "Lenovo"
			
			Case "Hewlett-Packard", "HP"
			SetMakeAlias = "HP"
			
			Case "SAMSUNG ELECTRONICS CO., LTD."
            SetMakeAlias = "Samsung"
			
			Case "Microsoft Corporation"
			SetMakeAlias = "Microsoft"
			
	        Case "VMware, Inc."
			SetMakeAlias = "VMware"
			
			Case Else
            SetMakeAlias = sMake 
	
	End Select

End Function


Function SetModelAlias()

    oLogging.CreateEntry "------------ Initialization USEREXIT:ModelAliasExit.vbs|SetModelAlias -------------", LogTypeInfo

    sMake = oEnvironment.Item("Make")
    sModel = oEnvironment.Item("Model")
    SetModelAlias = ""
    sCSPVersion = ""
    sBIOSVersion = ""

    Set colComputerSystemProduct = objWMI.ExecQuery("SELECT * FROM Win32_ComputerSystemProduct")
    If Err then
        oLogging.CreateEntry "Error querying Win32_ComputerSystemProduct: " & Err.Description & " (" & Err.Number & ")", LogTypeError
    Else
        For Each objComputerSystemProduct in colComputerSystemProduct
            If not IsNull(objComputerSystemProduct.Version) then
                sCSPVersion = Trim(objComputerSystemProduct.Version)
                oLogging.CreateEntry "USEREXIT:ModelAliasExit.vbs|SetModelAlias - Win32_ComputerSystemProduct Version: " & sCSPVersion, LogTypeInfo
            End If
        Next
    End if

    Set colBIOS = objWMI.ExecQuery("SELECT * FROM Win32_BIOS")
    If Err then
        oLogging.CreateEntry "Error querying Win32_BIOS: " & Err.Description & " (" & Err.Number & ")", LogTypeError
    Else
        For Each objBIOS in colBIOS
            If not IsNull(objBIOS.Version) then
                sBIOSVersion = Trim(objBIOS.Version)
                oLogging.CreateEntry "USEREXIT:ModelAliasExit.vbs|SetModelAlias - Win32_BIOS Version: " & sBIOSVersion, LogTypeInfo
            End If
        Next
    End if


    ' Check by Make
    
    Select Case sMake

        Case "Dell Computer Corporation", "Dell Inc.", "Dell Computer Corp."

            ' Next line is optional use, modelalias with spaces removed
            ' SetModelAlias = Replace(sModel, " ", "")

            SetModelAlias = sModel		

        Case "Hewlett-Packard", "HP"

            ' Next line is optional use, modelalias with spaces removed
            ' SetModelAlias = Replace(sModel, " ", "")

            SetModelAlias = sModel		

        Case "IBM", "LENOVO"

            ' Check by Version property of the Win32_ComputerSystemProduct WMI class first

            If Not sCSPVersion = "" Then
            
                Select Case sCSPVersion
                    Case "ThinkPad T61p"
                        SetModelAlias = "ThinkPad T61"
                    Case Else
						' Next line is optional use, modelalias with spaces removed                    
						' SetModelAlias = Replace(sCSPVersion, " ", "")
						
						SetModelAlias = sCSPVersion
                End Select
            
            End If


            ' Check by first 4 characters of the Model

            If SetModelAlias = "" Then 
            
                sModelSubString = Left(sModel,4)
                
                Select Case sModelSubString
                    Case "1706"
                        SetModelAlias = "ThinkPad X60"
                    Case Else
                        SetModelAlias = sModel
                        oLogging.CreateEntry "USEREXIT:ModelAliasExit.vbs|SetModelAlias - Alias rule not found.  ModelAlias set to Model value." , LogTypeInfo
                End Select

            End If



	Case "SAMSUNG ELECTRONICS CO., LTD."
    
		Select Case sModelSubString
                    Case "700T"
                        SetModelAlias = "Slate 7"
                    Case Else
                        SetModelAlias = sModel
                        oLogging.CreateEntry "USEREXIT:ModelAliasExit.vbs|SetModelAlias - Alias rule not found.  ModelAlias set to Model value." , LogTypeInfo
		End Select

        Case "Matsushita Electric Industrial Co.,Ltd."

            'Panasonic Toughbook models
            
            If Left(sModel,2) = "CF" Then 
                SetModelAlias = Left(sModel,5)
            Else
                SetModelAlias = sModel 
                oLogging.CreateEntry "USEREXIT:ModelAliasExit.vbs|SetModelAlias - Alias rule not found.  ModelAlias set to Model value." , LogTypeInfo
            End If


        Case "Microsoft Corporation"

            Select Case sBIOSVersion
                Case "VRTUAL - 1000831"
                    SetModelAlias = "Hyper-V2008BetaorRC0"
                Case "VRTUAL - 5000805", "BIOS Date: 05/05/08 20:35:56  Ver: 08.00.02"
                    SetModelAlias = "Hyper-V2008RTM"
                Case "VRTUAL - 3000919" 
                    SetModelAlias = "Hyper-V2008R2"
                Case "A M I  - 2000622"
                    SetModelAlias = "VS2005R2SP1orVPC2007"
                Case "A M I  - 9000520"
                    SetModelAlias = "VS2005R2"
                Case "A M I  - 9000816", "A M I  - 6000901"
                    SetModelAlias = "WindowsVirtualPC"
                Case "A M I  - 8000314"
                    SetModelAlias = "VS2005orVPC2004"
                Case Else
                    SetModelAlias = sModel 
                    oLogging.CreateEntry "USEREXIT:ModelAliasExit.vbs|SetModelAlias - Alias rule not found.  ModelAlias set to Model value." , LogTypeInfo
            End Select


        Case "VMware, Inc."
            SetModelAlias = sModel

        Case Else
            
            If Instr(sModel, "(") > 2 Then 
                SetModelAlias = Trim(Left(sModel, Instr(sModel, "(") - 2)) 
            Else 
                SetModelAlias = sModel 
                oLogging.CreateEntry "USEREXIT:ModelAliasExit.vbs|SetModelAlias - Alias rule not found.  ModelAlias set to Model value." , LogTypeInfo
            End if 


    End Select


    oLogging.CreateEntry "USEREXIT:ModelAliasExit.vbs|SetModelAlias - ModelAlias has been set to " & SetModelAlias, LogTypeInfo

    oLogging.CreateEntry "------------ Departing USEREXIT:ModelAliasExit.vbs|SetModelAlias -------------", LogTypeInfo

End Function

