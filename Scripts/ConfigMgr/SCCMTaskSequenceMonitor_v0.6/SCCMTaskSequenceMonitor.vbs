' // ***************************************************************************
' // 
' // Copyright (c) Maik Koster.  All rights reserved.
' //
' // File:      SCCMTaskSequenceMonitor.vbs
' // 
' // Version:   0.6
' // 
' // Purpose:   Monitors changes on SCCM Task Sequences and exports them
' //            for Backup/Versioning purposes
' // 
' // Usage:     cscript.exe [//nologo] SCCMTaskSequenceMonitor.vbs
' // 
' // History:   
' //    0.1 MK  04.04.2011  Initial script 
' //    0.2 MK  12.04.2011  Added Status Message query to get User that changed TS 
' //    0.3 MK  04.05.2011  Rewrote script to be used for permanent event consumption
' //    0.4 MK  09.05.2011  Code cleanup. Added XSL transformation. 
' //    0.5 MK  11.05.2011  Added proper handling for Create/Delete events.
' //                        Added 64 Bit support. First public Beta.
' //    0.6 MK  09.11.2011  Updated for ConfigMgr 2012 support.
' //
' // Download: http://mdtcustomizations.codeplex.com/releases/view/65824
' //  
' //
' // Disclaimer: This script is provided "AS IS" without express 
' //             or implied warranty of any kind.
' // 
' // ***************************************************************************


' // ***************************************************************************
' //
' // Variable Declaration
' //
' // ***************************************************************************

Dim SCCMUsername        ' Username (optional). Shouldn't be necessary as script is called by System account.
Dim SCCMPassword        ' Password (optional). Shouldn't be necessary as script is called by System account.
Dim ExportPath          ' Root Path to export the Task Sequences to. Default: "C:\SCCMTSMonitor"
Dim UseOSDTSOnly        ' True = Export only OSD Task Sequences. False (Default) = Export all Task Sequences
Dim UsePrevious         ' True = Export previous instance. False (Default) = Export current/updated Task Sequence
Dim UseVersion          ' True (Default) = Add a Version identifier to the name. False = overwrite last export.
Dim UseName             ' True = Use Task Sequence name for naming. False (Default) = Use PackageID for naming
Dim CreateSubfolder     ' True (Default) = Create a subfolder per Task Sequence. False = Export all to the same folder
Dim AddDate             ' True = Adds the current Date to the name. False (Default) = Don't add current Date to the name
Dim AddTime             ' True = Adds the current Time to the name. False (Default) = Don't add current Time to the name
Dim IncludePackages     ' List of Packages to include. * includes all (Default)
Dim ExcludePackages     ' List of Packages to exclude. Exclude takes precedence
Dim Debug               ' True = Verbose Logging. False (Default) = Info/Error Logging only
Dim VersionLength       ' Amount of digits used for the version. 3 is default.


' // ***************************************************************************
' //
' // Configure the following variables to adjust script behavior to your environment
' //
' // ***************************************************************************

SCCMUsername = ""
SCCMPassword = ""
ExportPath = "E:\SCCMTSMonitor"
UseOSDTSOnly = False
UsePrevious = False
UseVersion = True
UseName = False
CreateSubfolder = True
AddDate = False
AddTime = False
IncludePackages = "*"
ExcludePackages = ""
Debug = False
VersionLength =  3


' // ***************************************************************************
' // Don't change anything after this line !!!
' // ***************************************************************************


' // ***************************************************************************
' //
' // Defining some constants
' //
' // ***************************************************************************

Const LogTypeInfo = 1
Const LogTypeWarning = 2
Const LogTypeError = 3
Const LogTypeVerbose = 4
Const LogTypeDeprecated = 5
Const InstanceCreation = 1
Const InstanceModification = 2
Const InstanceDeletion = 3


' // ***************************************************************************
' // Decide what to do based on caller
' // ***************************************************************************

Dim oWMILocator, oWMIService
Dim sTSFilterName, sTSConsumerName, sScriptVersion, sScriptDate, sLogFile

sTSFilterName = "TSMonitorFilter"
sTSConsumerName = "TSMonitorConsumer"
sScriptVersion = "0.6"
sScriptDate = "09.11.2011"
sLogFile = "SCCMTSMonitor.log"

CreateLogEntry "SCCM Task Sequence Monitor script has been called.", LogTypeVerbose

Set oWMILocator = CreateObject("WbemScripting.SWbemLocator")
oWMILocator.Security_.AuthenticationLevel = 6
oWMILocator.Security_.ImpersonationLevel = 3

If Not IsNothing(TargetEvent) Then
    ' Called by the Event Filter
    CreateLogEntry "Script called by Event Consumer. Handling Event.", LogTypeVerbose
    HandleEvent(TargetEvent)
Else
    ' Called directly, create/create remove Monitor
    CreateLogEntry "Script called directly. Checking Monitor.", LogTypeVerbose
    HandleMonitor
End If

If Err.number <> 0 Then
    CreateLogEntry "Error  " & err.number & ": " & err.Description & ".", LogTypeInfo
End If


' // ***************************************************************************
' // 
' // Event Handler - Procedure gets called if a Task Sequence got modified
' // 
' // ***************************************************************************

Sub HandleEvent(oEvent)
    Dim oPackage, oTS, oTSXML
    Dim sSCCMNamespace, sUser, sUserLog
    Dim iEventType

    ' // ***************************************************************************
    ' // Get Namespace
    ' // ***************************************************************************
    sSCCMNamespace = GetNamespace

    If IsNothing(sSCCMNamespace) Then
        CreateLogEntry "HandleEvent: Unable to get SCCM namespace. Skipping further processing.", LogTypeError
        Exit Sub
    End If

    ' // ***************************************************************************
    ' // Create connection
    ' // ***************************************************************************    
    On Error Resume Next
    CreateLogEntry "HandleEvent: Connecting to local Site Server ...", LogTypeVerbose
    Set oWMIService = oWMILocator.ConnectServer(".", sSCCMNamespace, SCCMUser, SCCMPassword)
    CreateLogEntry "HandleEvent: Connected", LogTypeVerbose

        
    ' // ***************************************************************************
    ' // Get User
    ' // ***************************************************************************
    CreateLogEntry "HandleEvent: Getting User that changed the Task Sequence ...", LogTypeVerbose
    ' On creation/deletion we need to wait a moment as the event fires to fast to successfully query for the user
    If oEvent.SystemProperties_("__Class") = "__InstanceCreationEvent" Then 
        Sleep 5
    ElseIf  oEvent.SystemProperties_("__Class") = "__InstanceDeletionEvent" Then
        Sleep 1
    End If
    
    sUser = GetUser(oWMIService, oEvent.TargetInstance.PackageID)

    If sUser <> "" Then
        sUserLog = " by User " & sUser & "."
    Else 
        sUserLog = ". Unable to evaluate User."
    End If

    
    ' // ***************************************************************************
    ' // Evaluate Event type
    ' // ***************************************************************************
    Select Case oEvent.SystemProperties_("__Class")
    Case "__InstanceCreationEvent" 
        ' New Task Sequence has been created
        iEventType = InstanceCreation
        CreateLogEntry "HandleEvent: Task Sequence """ & oEvent.TargetInstance.Name & """ (" & oEvent.TargetInstance.PackageID & ") has been created " & sUserLog, LogTypeInfo
        CreateLogEntry "HandleEvent: Skipping further processing as will be followed by a change event immediately.", LogTypeVerbose
        Exit Sub
    Case "__InstanceDeletionEvent" 
        ' Task Sequence has been deleted
        iEventType = InstanceDeletion
        CreateLogEntry "HandleEvent: Task Sequence """ & oEvent.TargetInstance.Name & """ (" & oEvent.TargetInstance.PackageID & ") has been deleted " & sUserLog, LogTypeInfo
    Case Else
        ' Task Sequence has been modified
        iEventType = InstanceModification
        CreateLogEntry "HandleEvent: Task Sequence """ & oEvent.TargetInstance.Name & """ (" & oEvent.TargetInstance.PackageID & ") has been changed " & sUserLog, LogTypeInfo
    End Select


    ' // ***************************************************************************
    ' // Verify if Package shall be handled at all
    ' // ***************************************************************************
    If Not VerifyPackage(oEvent.TargetInstance) Then 
        CreateLogEntry "HandleEvent: Current Task Sequence is excluded from Export.", LogTypeInfo
        Exit Sub
    End If


    ' // ***************************************************************************
    ' // On Deletion export Info XML with User and Date for Reference purpose only
    ' // Exporting the Target version will currently fail
    ' // TODO: Check if Target version can be exported too
    ' // ***************************************************************************
    If iEventType = InstanceDeletion Then
        CreateLogEntry "HandleEvent: Current Task Sequence has been deleted. Exporting information about deletion and user.", LogTypeInfo

        ' Create Info XML
        WriteInfoXML oEvent.TargetInstance, sUser, iEventType
        Exit Sub
    End If
    

    ' // ***************************************************************************
    ' // Evaluate Instance to use
    ' // ***************************************************************************
    If UsePrevious Then
        Set oPackage = oEvent.PreviousInstance
        CreateLogEntry "HandleEvent: Using previous instance.", LogTypeVerbose
    Else
        Set oPackage = oEvent.TargetInstance
        CreateLogEntry "HandleEvent: Using target instance.", LogTypeVerbose
    End If
    

    ' // ***************************************************************************
    ' // Get Task Sequence 
    ' // ***************************************************************************
    CreateLogEntry "HandleEvent: Getting Sequence from Package...", LogTypeVerbose
    Set oTS = GetTaskSequence(oWMIService, oPackage)

    If IsNothing(oTS) Then
        CreateLogEntry "HandleEvent: Unable to get Sequence from Package! Skipping further processing.", LogTypeError
        Exit Sub
    End If


    ' // ***************************************************************************
    ' // Convert to XML
    ' // ***************************************************************************
    CreateLogEntry "HandleEvent: Converting Sequence to XML ...", LogTypeVerbose
    Set oTSXML = GetTaskSequenceXML(oWMIService, oTS)

    If IsNothing(oTSXML) Then
        CreateLogEntry "HandleEvent: Unable to convert Sequence to XML! Skipping further processing.", LogTypeError
        Exit Sub
    End If


    ' // ***************************************************************************
    ' // Export Task Sequence
    ' // ***************************************************************************
    CreateLogEntry "HandleEvent: Exporting Task Sequence ...", LogTypeVerbose
    ExportTaskSequence oTSXML, oPackage, sUser, iEventType

    CreateLogEntry "HandleEvent: Event processing completed.", LogTypeVerbose
End Sub


' // ***************************************************************************
' //
' // Create Task Sequence Monitor
' //
' // ***************************************************************************

Sub HandleMonitor
    Dim oWbemService, oEventFilterClass, oEventFilter
    Dim oConsumerClass, oConsumer, oBindingClass, oBinding
    Dim sQuery, sSCCMNamespace

    ' // ***************************************************************************
    ' // Need to ensure we have administrative privileges
    ' // ***************************************************************************
    If Not IsAdmin Then
        CreateLogEntry "HandleMonitor: Administrative privileges required!", LogTypeError
        MsgBox "Administrative privileges required!", vbInformation, "Monitor Task Sequences"
        Exit Sub
    End If

    
    ' // ***************************************************************************
    ' // Get Namespace
    ' // ***************************************************************************
    sSCCMNamespace = GetNamespace

    If IsNothing(sSCCMNamespace) Then
        CreateLogEntry "HandleMonitor: Unable to get SCCM namespace. Skipping further processing.", LogTypeError
        Exit Sub
    End If


    ' // ***************************************************************************
    ' // Create Connection to subscription namespace
    ' // ***************************************************************************
    CreateLogEntry "HandleMonitor: Connecting to local subscription Namespace", LogTypeVerbose
    Set oWbemService = oWMILocator.ConnectServer(".","root\subscription", SCCMUser, SCCMPassword)

    
    ' // ***************************************************************************
    ' // Check if Event Filter exists already
    ' // If exits, remove Event Filter and consumer
    ' // If not, create Event Filter and Consumer
    ' // ***************************************************************************
    CreateLogEntry "HandleMonitor: Checking Event Filters ...", LogTypeInfo
    On Error Resume Next
    Set oEventFilter = oWbemService.Get("__EventFilter.Name='" & sTSFilterName & "'")
    If Not IsNothing(oEventFilter) Then
        CreateLogEntry "HandleMonitor: Event Filter exists already. Removing Event Filter and Consumer ...", LogTypeVerbose
        oWbemService.Delete("__EventFilter.Name='" & sTSFilterName & "'")
        CreateLogEntry "HandleMonitor: Removed Event Filter """ & sTSFilterName & """.", LogTypeVerbose
        oWbemService.Delete("ActiveScriptEventConsumer.Name='" & sTSConsumerName & "'")
        CreateLogEntry "HandleMonitor: Removed Event Consumer """ & sTSConsumerName & """.", LogTypeVerbose
        
        CreateLogEntry "HandleMonitor: Removed existing Event Filter and Consumer.", LogTypeInfo
        MsgBox "Removed existing Event Filter and Consumer.", vbInformation, "Monitor Task Sequences"

        Exit Sub
    End If
    On Error Goto 0


    ' // ***************************************************************************
    ' // Create Event Filter
    ' // ***************************************************************************
    CreateLogEntry "HandleMonitor: Creating Event Filter ...", LogTypeVerbose

    Set oEventFilterClass = oWbemService.Get("__EventFilter")
    Set oEventFilter = oEventFilterClass.SpawnInstance_()
        
    oEventFilter.Name = sTSFilterName
    CreateLogEntry "HandleMonitor: Event Filter Name = " & sTSFilterName & ".", LogTypeVerbose
    oEventFilter.QueryLanguage = "WQL"
    'sQuery = "SELECT * FROM __InstanceModificationEvent WITHIN 5 WHERE TargetInstance ISA 'SMS_TaskSequencePackage'"
    sQuery = "SELECT * FROM __InstanceOperationEvent WITHIN 5 WHERE TargetInstance ISA 'SMS_TaskSequencePackage'"
    oEventFilter.Query = sQuery
    CreateLogEntry "HandleMonitor: Event Filter Query = " & sQuery & ".", LogTypeVerbose
    oEventFilter.EventNamespace = sSCCMNamespace
    CreateLogEntry "HandleMonitor: Event Filter Namespace = " & sSCCMNamespace & ".", LogTypeVerbose

    oEventFilter.Put_()

    CreateLogEntry "HandleMonitor: Created Event Filter.", LogTypeInfo

    ' // ***************************************************************************
    ' // Create Event Consumer
    ' // ***************************************************************************
    CreateLogEntry "HandleMonitor: Creating Event Consumer ...", LogTypeVerbose

    Set oConsumerClass = oWbemService.Get("ActiveScriptEventConsumer")
    Set oConsumer = oConsumerClass.SpawnInstance_()

    ScriptPath = Replace(WScript.ScriptFullName, WScript.ScriptName, "") 
    oConsumer.Name = sTSConsumerName
    CreateLogEntry "HandleMonitor: Event Consumer Name = " & sTSConsumerName & ".", LogTypeVerbose
    oConsumer.ScriptFileName = WScript.ScriptFullName 
    CreateLogEntry "HandleMonitor: Event Consumer Script = " & WScript.ScriptFullName & ".", LogTypeVerbose
    oConsumer.ScriptingEngine = "VBScript"

    oConsumer.Put_

    CreateLogEntry "HandleMonitor: Created Event Consumer.", LogTypeInfo

    ' // ***************************************************************************
    ' // Refresh objects to be able to use the Path property
    ' // ***************************************************************************

    oEventFilter.Refresh_()
    oConsumer.Refresh_()
    
    ' // ***************************************************************************
    ' // Create Binding
    ' // ***************************************************************************
    CreateLogEntry "HandleMonitor: Creating Binding ...", LogTypeVerbose

    Set oBindingClass = oWbemService.Get("__FilterToConsumerBinding")
    Set oBinding = oBindingClass.SpawnInstance_()

    oBinding.Filter = oEventFilter.Path_
    CreateLogEntry "HandleMonitor: Event Filter Path = " & oEventFilter.Path_ & ".", LogTypeVerbose
    oBinding.Consumer = oConsumer.Path_
    CreateLogEntry "HandleMonitor: Event Consumer Path = " & oConsumer.Path_ & ".", LogTypeVerbose

    oBinding.Put_()

    CreateLogEntry "HandleMonitor: Created Binding.", LogTypeInfo
    MsgBox "Created Event Filter and Consumer.", vbInformation, "Monitor Task Sequences"
End Sub


' // ***************************************************************************
' //
' // Helper functions
' //
' // ***************************************************************************


' // ***************************************************************************
' // Compares the current package against the Include/Exclude Filters
' // ***************************************************************************
Function VerifyPackage(Package)
    Dim bResult
    bResult = False

    If Not IsNothing(Package) Then

        ' First check if the current package shall be included in the output
        If IncludePackages = "*" Or InStr(1, IncludePackages, Package.PackageID, vbTextCompare) > 0 Then

            'Now verify if there is an explicit exclude for this package
            If InStr(1, ExcludePackages, Package.PackageID, vbTextCompare) = 0 Then

                'Make sure it's an OSD Task Sequence if limited
                If UseOSDTSOnly Then
                    CreateLogEntry "VerifyPackage: Export is limited to OSD Task Sequences", LogTypeVerbose
                    If Package.Type = 2 Then
                        bResult = True
                    Else
                        CreateLogEntry "VerifyPackage: Current Task Sequence is no OSD Task Sequence. Skipping further processing.", LogTypeVerbose
                    End If
                Else
                    bResult = True   
                End If
            Else
                CreateLogEntry "VerifyPackage: Current PackageID is excluded. Skipping further processing.", LogTypeVerbose
            End If
        Else
            CreateLogEntry "VerifyPackage: Current PackageID is not included. Skipping further processing", LogTypeVerbose
        End If
    Else
        CreateLogEntry "VerifyPackage: Package object is emtpy. Skipping further processing", LogTypeVerbose
    End If

    VerifyPackage = bResult
End Function


' // ***************************************************************************
' // Exports the Task Sequence
' // ***************************************************************************
Sub ExportTaskSequence(Sequence, Package, User, EventType)
    On Error Resume Next 
    
    Dim oXML, oRoot, oBootImageID, oCategory, oDepProg, oDesc
    Dim oDuration, oName, oProgramFlags, oSecData, oSourceDate, oSuppOS, oIconSize
    Dim sXSL, sHeader, sWMIDateStringToDate, sPathName
    
    ' // ***************************************************************************
    ' // Preparing the XML Document
    ' // Need to add some elements to be able to import this Task Sequence again
    ' // ***************************************************************************
    CreateLogEntry "ExportTaskSequence: Preparing XML Document ...", LogTypeVerbose
    Set oXML = CreateXMLDocument
    AddXMLHeader oXML, User, EventType

    Set oRoot = oXML.createElement("SmsTaskSequencePackage")
    oXML.appendChild oRoot
        
    Set oBootImageID = oXML.createElement("BootImageID")
    If Package.BootImageID <> "" Then
    	oBootImageID.Text = Package.BootImageID
    End if
    oRoot.appendChild oBootImageID    

    Set oCategory = oXML.createElement("Category")
    If Package.Category <> "" Then
    	oCategory.Text = Package.Category
    End If
    oRoot.appendChild oCategory
    
    Set oDepProg = oXML.createElement("DependentProgram")
    If Package.DependentProgram <> "" Then
    	oDepProg.Text = Package.DependentProgram
    End If
    oRoot.appendChild oDepProg
    
    Set oDesc = oXML.createElement("Description")
    If Package.Description <> "" Then
    	oDesc.Text = Package.Description
    End If
    oRoot.appendChild oDesc
    
    Set oDuration = oXML.createElement("Duration")
    If Package.Duration <> "" Then
    	oDuration.Text = Package.Duration
    End If
    oRoot.appendChild oDuration
    
    Set oName = oXML.createElement("Name")
    If Package.Name <> "" Then
    	oName.Text = Package.Name
    End If
    oRoot.appendChild oName
    
    Set oProgramFlags = oXML.createElement("ProgramFlags")
    If Package.ProgramFlags <> "" Then
    	oProgramFlags.Text = Package.ProgramFlags
    End If
    oRoot.appendChild oProgramFlags
    
    Set oSecData = oXML.createElement("SequenceData")
    oRoot.appendChild oSecData
    oSecData.appendChild Sequence.firstChild
    
    
    Set oSourceDate = oXML.createElement("SourceDate")
    If Package.SourceDate <> "" Then
        sd = Package.SourceDate
                
        sWMIDateStringToDate = Left(sd, 4) & "-" & Mid(sd, 5, 2) & _
            "-" & Mid(sd, 7, 2) & "T" & Mid (sd, 9, 2) & ":" & _
                    Mid(sd, 11, 2) & ":" & Mid(sd, 13, 2)
    	
        oSourceDate.Text = sWMIDateStringToDate
    End If
    oRoot.appendChild oSourceDate
    
    Set oSuppOS = oXML.createElement("SupportedOperatingSystems")
    If PackageSupportedOperatingSystems <> ""  Then
    	oSuppOS.Text = Package.SupportedOperatingSystems
    End If
    oRoot.appendChild oSuppOS
    
    Set oIconSize = oXML.createElement("IconSize")
    If Package.IconSize <> "" Then
    	oIconSize.Text = Package.IconSize
    End If
    oRoot.appendChild oIconSize
    

    ' // ***************************************************************************
    ' // Get Path and Name according to the rules configured
    ' // ***************************************************************************
    sPathName = GetPathAndName(Package)


    ' // ***************************************************************************
    ' // Transform and save XML Document to local folder
    ' // ***************************************************************************
    Set oXML = TransformXML(oXML)

    CreateLogEntry "ExportTaskSequence: Exporting Task Sequence ...", LogTypeVerbose
    oXML.Save(sPathName)

    CreateLogEntry "ExportTaskSequence: Exported Task Sequence to " & sPathname & ".", LogTypeInfo

End Sub


' // ***************************************************************************
' // Creates an informational XML Document with Event Type, Username and Date
' // Used for Creation/Deletion of Task Sequences if we don't have access
' // to the Task Sequence data itself
' // ***************************************************************************
Public Sub WriteInfoXML (Package, User, EventType)
    Dim oXML, oHeader, oRoot
    Dim sPathName, sHeader

    ' Get Path and Name according to current rules
    sPathName = GetPathAndName(Package)

    If EventType = InstanceDeletion Then
        ' Add "_Deleted" to the Name
        sPathName = Replace(sPathName, ".xml", "_Deleted.xml")
    End If

    ' // ***************************************************************************
    ' // Create the XML Document
    ' // ***************************************************************************
    CreateLogEntry "WriteInfoXML: Preparing XML Document ...", LogTypeVerbose
    Set oXML = CreateXMLDocument
    AddXMLHeader oXML, User, EventType

    ' Add emtpy Root element to get a valid XML Document
    Set oRoot = oXML.createElement("SmsTaskSequencePackage")
    oXML.appendChild oRoot

    ' // ***************************************************************************
    ' // Transform and save the XML Document
    ' // ***************************************************************************
    Set oXML = TransformXML(oXML)
    
    oXML.Save(sPathName)
    CreateLogEntry "WriteInfoXML: Exported Task Sequence to " & sPathname & ".", LogTypeInfo
End Sub


' // ***************************************************************************
' // Creates The base XML document for export
' // ***************************************************************************
Function CreateXMLDocument
    Dim oXML, oCreation
        
    Set oXML = CreateObject("MSXML2.DOMDocument")
    Set oCreation = oXML.createProcessingInstruction("xml", "version='1.0'")
    oXML.insertBefore oCreation, oXML.childNodes.Item(0)

    CreateLogEntry "CreateXMLDocument: Created Base XML Document.", LogTypeVerbose
    Set CreateXMLDocument = oXML
End Function


' // ***************************************************************************
' // Add a custom Header for XML export
' // ***************************************************************************
Sub AddXMLHeader (XML, User, EventType)
    Dim oHeader
    Dim sHeader

    CreateLogEntry "AddXMLHeader: Preparing custom Header ...", LogTypeVerbose
    Select Case EventType
    Case InstanceCreation
        sHeader = "Task Sequence created by User " & User & " on " & Now & "." & vbCrLf & vbCrLf
    Case InstanceDeletion
        sHeader = "Task Sequence deleted by User " & User & " on " & Now & "." & vbCrLf & vbCrLf
    Case Else
        sHeader = "Last Task Sequence change by User " & User & " on " & Now & "." & vbCrLf & vbCrLf
    End Select
    
    sHeader = sHeader & "Task Sequence exported by SCCM Task Sequence Monitor (Version " & sScriptVersion & " - " & sScriptDate & ")." & vbCrLf
    sHeader = sHeader & "Check http://mdtcustomizations.codeplex.com for Updates." & vbCrLf & vbCrLf
    sHeader = sHeader & "Copyright (c) Maik Koster.  All rights reserved." & vbCrLf

    Set oHeader = XML.createComment(sHeader)
    XML.appendChild oHeader

    CreateLogEntry "AddXMLHeader: Added custom Header to XML Document.", LogTypeVerbose
End Sub


' // ***************************************************************************
' // Use XSL to transform XML to Human-readable format (indent, etc)
' // ***************************************************************************
Function TransformXML (XML)
    Dim oXSL, oXMLOutput

    CreateLogEntry "TransformXML: Preparing XSL Stylesheet to transform XML ...", LogTypeVerbose
    Set oXSL = CreateObject("MSXML2.DOMDocument")
    Set oXMLOutput = CreateObject("MSXML2.DOMDocument")
    oXSL.async = False

    sXSL = "<?xml version=""1.0"" encoding=""UTF-8""?>"
    sXSL = sXSL & "<xsl:stylesheet version=""1.0"" xmlns:xsl=""http://www.w3.org/1999/XSL/Transform"">"
    sXSL = sXSL & "  <xsl:output method=""xml"" indent=""yes"" encoding=""UTF-8"" />"
    sXSL = sXSL & "  <xsl:template match=""@* | node()"">"
    sXSL = sXSL & "    <xsl:copy>"
    sXSL = sXSL & "      <xsl:apply-templates select=""@* | node()"" />"
    sXSL = sXSL & "    </xsl:copy>"
    sXSL = sXSL & "  </xsl:template>"
    sXSL = sXSL & "</xsl:stylesheet>"

    oXSL.loadXML (sXSL)

    CreateLogEntry "TransformXML: Transforming XML ...", LogTypeVerbose
    XML.transformNodeToObject oXSL, oXMLOutput

    CreateLogEntry "TransformXML: XML Document transformed.", LogTypeVerbose
    Set TransformXML = oXMLOutput
End Function


' // ***************************************************************************
' // Returns the Path and Name based on the current configuration
' // ***************************************************************************
Function GetPathAndName(Package)
    Dim oFSO
    Dim sResult, sXMLName, sCurrentPath
    
    ' Prepare Folder and Name
    Set oFSO = CreateObject("Scripting.FileSystemObject")

    ' Get Base name
    If UseName Then
        sXMLName = Package.Name
        CreateLogEntry "GetPathAndName: Using Package name as base name.", LogTypeVerbose
    Else
        sXMLName = Package.PackageID
        CreateLogEntry "GetPathAndName: Using PackageID as base name.", LogTypeVerbose
    End If

   ' Get Path
    If CreateSubfolder Then
        sCurrentPath = ExportPath & "\" & sXMLName

        ' Ensure Folder exists
        VerifyPathExists sCurrentPath
    Else
        sCurrentPath = ExportPath
    End If

    CreateLogEntry "GetPathAndName: Setting Path to " & sCurrentPath & ".", LogTypeVerbose
    
    ' Add Date if configured
    If AddDate Then
        Dim sDate

        sDate = Year(Now) & PadDigits(Month(Now), 2) & PadDigits(Day(Now), 2) 
        sXMLName = sXMLName & "_" & sDate
        CreateLogEntry "GetPathAndName: Adding Date to name.", LogTypeVerbose
    End If

    ' Add Time if configured
    If AddTime Then
        Dim sTime

        sTime = PadDigits(Hour(Now),2) & PadDigits(Minute(Now), 2) 
        sXMLName = sXMLName & "_" & sTime
        CreateLogEntry "GetPathAndName: Adding Time to name.", LogTypeVerbose
    End If
    
    ' Add Version if configured
    If UseVersion Then
        CreateLogEntry "GetPathAndName: Adding version to name.", LogTypeVerbose
        ' Find next valid version
        Dim bFoundVersion
        Dim iCount
        Dim sCurrentVersion
        bFoundVersion = False
        iCount = 0
        
        Do
            iCount = iCount + 1
            sCurrentVersion = sXMLName & "_" & PadDigits(iCount, VersionLength)

            If Not oFSO.FileExists(sCurrentPath & "\" & sCurrentVersion & ".xml") Then
                bFoundVersion = True
                CreateLogEntry "GetPathAndName: Current Version is " & iCount & ".", LogTypeVerbose
                CreateLogEntry "GetPathAndName: Setting name to " & sCurrentversion & ".", LogTypeVerbose
            End If
        Loop Until bFoundVersion

        sResult = sCurrentPath & "\" & sCurrentVersion & ".xml"
    Else
        sResult = sCurrentPath & "\" & sXMLName & ".xml"
        CreateLogEntry "GetPathAndName: Setting name to " & sXMLName & ".", LogTypeVerbose
    End If

    GetPathAndName = sResult
End Function


' // ***************************************************************************
' // Returns the name of the User who changed the Task Sequence
' // ***************************************************************************
Function GetUser(Connection, TaskSequenceID)
    On Error Resume Next

    Dim oStatusMessages, oMessage
    Dim sQuery, sResult

    sResult = ""
    CreateLogEntry "GetUser: Getting Username ...", LogTypeVerbose

    ' Create WQL Query
    sQuery = "SELECT SMS_StatMsgInsStrings.InsStrValue FROM SMS_StatusMessage INNER JOIN"
    sQuery = sQuery & " SMS_StatMsgInsStrings ON SMS_StatusMessage.RecordID = SMS_StatMsgInsStrings.RecordID INNER JOIN"
    sQuery = sQuery & " SMS_StatMsgInsStrings AS v_StatMsgInsStrings_1 ON SMS_StatusMessage.RecordID = v_StatMsgInsStrings_1.RecordID"
    sQuery = sQuery & " WHERE ((SMS_StatusMessage.MessageID = 30000) OR (SMS_StatusMessage.MessageID = 30001) OR (SMS_StatusMessage.MessageID = 30002))" 'AND (SMS_StatusMessage.MachineName = '" & SCCMServer & "') "
    sQuery = sQuery & " AND (v_StatMsgInsStrings_1.InsStrIndex = 1) AND (v_StatMsgInsStrings_1.InsStrValue = '" & TaskSequenceID & "')"
    sQuery = sQuery & " AND (SMS_StatMsgInsStrings.InsStrIndex = 0)"
    sQuery = sQuery & " ORDER BY SMS_StatusMessage.RecordID DESC"

    ' Get latest Status messages
    CreateLogEntry "GetUser: Executing query """ & sQuery & """.", LogTypeVerbose
    Set oStatusMessages = Connection.ExecQuery(sQuery)

    If Err.number <> 0 Then
        CreateLogEntry "Error  " & err.number & ": " & err.Description & ".", LogTypeInfo
    End If

    ' Pick the first status message
    For Each oMessage in oStatusMessages
        sResult = oMessage.Properties_("InsStrValue")

        If sResult <> "" Then
            CreateLogEntry "GetUser: Found Username " & sResult & ".", LogTypeVerbose
        Else
            CreateLogEntry "GetUser: Unable to get User.", LogTypeWarning
        End If

        Exit For
    Next

    ' Return the name
    GetUser = sResult
End Function


' // ***************************************************************************
' // Returns the Task Sequence from a Task Sequence Package
' // ***************************************************************************
Function GetTaskSequence(Connection, TaskSequencePackage)
	On Error Resume Next
	
	Dim oPackageClass, oInParam, oOutParam
	
    CreateLogEntry "GetTaskSequence: Getting Task Sequence from Task Sequence Package.", LogTypeVerbose

    ' Get the parameters object.
    Set oPackageClass = connection.Get("SMS_TaskSequencePackage")
       
    Set oInParam = oPackageClass.Methods_("GetSequence").inParameters.SpawnInstance_()

    ' Add the input parameters.
    oInParam.Properties_.Item("TaskSequencePackage") =  TaskSequencePackage
    
    ' Get the sequence.
    CreateLogEntry "GetTaskSequence: Executing method ""GetSequence"".", LogTypeVerbose
    Set oOutParam = connection.ExecMethod("SMS_TaskSequencePackage", "GetSequence", oInParam)
     
	If Err.Number<>0 Then
        CreateLogEntry "GetTaskSequence: Unable to get Task Sequence.", LogTypeError
        Set GetTaskSequence = Nothing
        Exit Function
    End If
     
     Set GetTaskSequence = oOutParam.TaskSequence
End Function


' // ***************************************************************************
' // Return the Task Sequence converted to XML
' // ***************************************************************************
Function GetTaskSequenceXML(Connection, TaskSequence)
	Dim oTSClass, oInParam, oOutParam, oXML

    CreateLogEntry "GetTaskSequenceXML: Converting Task Sequence to XML ...", LogTypeVerbose

    CreateLogEntry "GetTaskSequenceXML: Getting Task Sequence class.", LogTypeVerbose
	Set oTSClass = Connection.Get("SMS_TaskSequence")
    CreateLogEntry "GetTaskSequenceXML: Preparing parameters", LogTypeVerbose
    Set oInParam = oTSClass.Methods_("SaveToXML").inParameters.SpawnInstance_()
    
    oInParam.Properties_.Item("TaskSequence") = TaskSequence
    CreateLogEntry "GetTaskSequenceXML: Invoking method ""SaveToXML"".", LogTypeVerbose
    Set oOutParam = Connection.ExecMethod("SMS_TaskSequence", "SaveToXML", oInParam)
    
    If Err.Number<> 0 Then
    	CreateLogEntry "Unable to Get XML!", LogTypeError
    	Exit Function
    End If

    CreateLogEntry "GetTaskSequenceXML: Load XML from Result.", LogTypeVerbose
    Set oXML = CreateObject("MSXML2.DomDocument")
    oXML.loadXML(oOutParam.ReturnValue)

    Set GetTaskSequenceXML = oXML
End Function


' // ***************************************************************************
' // Converts an integer to a string of the specified length, padded with 0
' // ***************************************************************************
Function PadDigits(iValue, iTotalDigits)     
    PadDigits = Right(string(itotalDigits,"0") & iValue, iTotalDigits) 
End Function 


' // ***************************************************************************
' // Create Log Entry
' // partly taken from MDT ZTIUtility.vbs
' // ***************************************************************************
Function CreateLogEntry(sLogMsg, iType)
	Dim sTime, sDate, sTempMsg, oLog, bConsole
        
	' Each of the operations below has the potential to cause a runtime error.
	' However, we must not stop operation if there is a failure, so allways continue.

	On Error Resume Next
    Set oFSO = CreateObject("Scripting.FileSystemObject")
        
	' Special Handling for Debug vs. Non-Debug messages
	If Not Debug Then
		If iType = LogTypeVerbose Then
			Exit Function  ' Verbose Messages are only displayed when Debug = True
		Elseif iType = LogTypeDeprecated Then
			iType = LogTypeInfo ' Deprecated messages are normally Info messages
		End if
	Else  ' Debug = True
		If iType = LogTypeVerbose Then
			iType = LogTypeInfo
		Elseif iType = LogTypeDeprecated Then
			iType = LogTypeError
		End if
	End if

	' Populate the variables to log
	sTime = Right("0" & Hour(Now), 2) & ":" & Right("0" & Minute(Now), 2) & ":" & Right("0" & Second(Now), 2) & ".000+000"
	sDate = Right("0"& Month(Now), 2) & "-" & Right("0" & Day(Now), 2) & "-" & Year(Now)
	sTempMsg = "<![LOG[" & sLogMsg & "]LOG]!><time=""" & sTime & """ date=""" & sDate & """ component=""SCCMTSMonitor"" context="""" type=""" & iType & """ thread="""" file=""SCCMTaskSequenceMonitor.vbs"">"

	' Make sure the LogPath directory exists
	VerifyPathExists ExportPath

	' Create the log entry
	Set oLog = oFSO.OpenTextFile(ExportPath & "\" & sLogFile, 8, True)
	oLog.WriteLine sTempMsg
	oLog.Close
   	On Error Goto 0

End Function


' // ***************************************************************************
' // Verifies if the specified path exists. Will create missing folders if necessary
' // partly taken from MDT ZTIUtility.vbs
' // ***************************************************************************
Public Function VerifyPathExists(sPath)
    Dim oFSO
    Set oFSO = CreateObject("Scripting.FileSystemObject")

	If sPath = "" then
		VerifyPathExists = True
		Exit Function
	End if

	If oFSO.FolderExists(sPath) then
		VerifyPathExists = true
		Exit Function
	Else
		VerifyPathExists oFSO.GetParentFolderName(sPath)
		'On Error Resume Next
		oFSO.CreateFolder sPath
		CreateLogEntry "VerifyPathExists: Created folder " & sPath, LogTypeVerbose

		On Error Goto 0
	End if
End function 


' // ***************************************************************************
' // Checks if an element is empty/nothing depending on the element type
' // ***************************************************************************
Function IsNothing(Value)
    Dim vTest
    Dim iArrayStart
    Dim iCtr, nDim, nRows, nCols, x, y    
    Dim bFlag : bFlag = False

    If IsEmpty(Value) Then
        IsNothing = True
        Exit Function
    End If

    If IsNull(Value) Then
        IsNothing = True
        Exit Function
    End If

    If VarType(Value) = vbString Then
        If Value = "" Then
            IsNothing = True
            Exit Function
        End If
    End If

    If IsNumeric(Value) Then
        If Value = 0 Then
            IsNothing = True
            Exit Function
        End If
    End If

    If IsObject(Value) Then
        If Value Is Nothing Then
            IsNothing = True
            Exit Function
        End If
    End If

    'Check for arrays

    If IsArray(Value) Then
        nDim = NoDim(Value)
        'Handle mutli dim arrays
        If nDim = 0 then
            IsNothing = true
            Exit Function
        Elseif nDim = 1 then 'check single dim array
            On Error Resume Next
            'Handle Single dim arrays
            vTest = Value(0)
            iArrayStart = IIf(Err.Number = 0, 0, 1)
            Err.Clear
            On Error GoTo 0
            For iCtr = iArrayStart To UBound(Value)
                If Not IsNothing(Value(iCtr)) Then
                    'Has something in it
                    bFlag = True
                    Exit For
                End If
            Next 

            IsNothing = Not bFlag
            Exit Function
        Elseif nDim = 2 then
            nRows = Ubound(Value, 2)+1
            nCols = Ubound(Value, 1)+1 

            for x = 0 to nRows - 1
                for y = 0 to nCols - 1
                    If not IsNothing(Value(y,x)) then
                        bFlag = True
                        Exit For
                    End if
                next
                if (bFlag) then
                    Exit For
                end if
            next
            IsNothing = Not bFlag
            Exit Function
        End if
    End If

    IsNothing = False

End Function

' These functions are used by the IsNothing routine

Function IIf(condition,value1,value2)
    If condition Then IIf = value1 Else IIf = value2
End Function

'** will retun the number of dimensions of an array
Function NoDim(arr)

    Dim n, mynextArray

    On Error Resume Next
    For n = 1 to 60
        mynextArray = UBound(arr, n)
        If err.number > 0 Then
            n = n - 1
            Exit For
        End if
    Next
    On Error Goto 0

    NoDim = n 

End Function

' // ***************************************************************************
' // Return local SCCM Namespace
' // ***************************************************************************
Function GetNamespace
    Dim sNamespace, sSiteCode

    ' Get Site Code from WMI
    sSiteCode = GetSiteCode


    If sSiteCode <> "" Then
        sNamespace  = "root\sms\site_" & sSiteCode
        CreateLogEntry "GetNamespace: SCCM Namespace is " & sNamespace & ".", LogTypeVerbose 
    Else
        sNamespace = ""
        CreateLogEntry "GetNamespace: No SiteCode found. Unable to create Namespace.", LogTypeVerbose
    End If
    
    GetNamespace = sNamespace
End Function


' // ***************************************************************************
' // Get current Site Code from WMI
' // ***************************************************************************
Function GetSiteCode
    On Error Resume Next
    Dim oSiteCodeWMIService, oProviderLoc, oLocation
    Dim sSiteCode
    
    sSiteCode = ""

    ' Connect to the server.
    CreateLogEntry "GetSiteCode: Connecting to local Server ...", LogTypeVerbose
    Set oSiteCodeWMIService = oWMILocator.ConnectServer(".", "root\sms", "", "")
    
    If Err.Number<>0 Then
        CreateLogEntry "GetSiteCode: Failed to connect to local server. Unable to retrieve site code.", LogTypeError
        GetSiteCode = sSiteCode
        Exit Function
    Else
        CreateLogEntry "GetSiteCode: Connected", LogTypeVerbose
    End If
    
    ' Determine where the provider is and connect.
    Set oProviderLoc = oSiteCodeWMIService.InstancesOf("SMS_ProviderLocation")

    For Each oLocation In oProviderLoc
        If oLocation.ProviderForLocalSite = True Then
            sSiteCode = oLocation.SiteCode

            CreateLogEntry "GetSiteCode: Found local site code " & sSiteCode, LogTypeVerbose
            Exit For
        End If
    Next

    Err.Clear
    On Error Goto 0 ' Reset Errorhandling

    GetSiteCode = sSiteCode
End Function


' // ***************************************************************************
' // Get current Site Code from Registry (replaced by direct WMI Call)
' // ***************************************************************************
Function GetSiteCodeFromRegistry
    Dim oShell 
    Dim sSiteCode 

    Set oShell = CreateObject("wscript.shell")
    sSiteCode = ""

    ' Will fail if key doesn't exist
    On Error Resume Next
	If Is64Bit Then
		sSitecode = oShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\SMS\Identification\Site Code")
	Else
		sSitecode = oShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS\Identification\Site Code")
    End If
	
	CreateLogEntry "GetSiteCode: Current Site Code is " & sSiteCode & ".", LogTypeVerbose
    Err.Clear
    On Error Goto 0

    GetSiteCode = sSiteCode
End Function


' // ***************************************************************************
' // Verify if current User is Admin
' // Snippet taken from http://csi-windows.com/toolkit/csi-isadmin
' // ***************************************************************************
Function IsAdmin
    Dim oShell : Set oShell = createobject("wscript.shell")
    Dim oExec : Set oExec = oShell.Exec("%comspec% /c dir """ & oShell.RegRead("HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\S-1-5-18\ProfileImagePath") & """  2>&1 | findstr /I /C:""Not Found""")
    Do While oExec.Status = 0
        WScript.Sleep 100
    Loop
    If oExec.ExitCode <> 0 Then 
        IsAdmin = True
    Else
        IsAdmin = False
    End If
End Function


' // ***************************************************************************
' // Custom function to enable the script to "sleep" a certain period of time
' // as we don't have access to the WScript object on Event execution
' // ***************************************************************************
Function Sleep(seconds)
    Dim tStart, tEnd
    tStart = Time()    
    tEnd = DateAdd("s",seconds,tStart)
    CreateLogEntry "Sleep: Sleeping for " & seconds & " second(s).", LogTypeVerbose
    While tEnd >= Time()
    Wend
End Function
 
 
' // ***************************************************************************
' // Checks if the current Operating System is 64 Bit System
' // ***************************************************************************
 Function  Is64Bit
	Dim bResult
	Dim iBit
	
	iBit  = GetObject("winmgmts:root\cimv2:Win32_Processor='cpu0'").AddressWidth 
	
	If iBit = 64 Then
		bResult = True
	Else
		bResult = False
	End If
	
	Is64Bit = bResult
End Function
