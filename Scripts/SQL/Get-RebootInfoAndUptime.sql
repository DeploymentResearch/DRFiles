-- Note: System boot time is collected from LastBootUpTime in Win32_OperatingSystem via hardware inventory
SELECT CDR.MachineID, CDR.Name, CDR.ClientState, OS.LastBootUpTime0 FROM vSMS_CombinedDeviceResources as CDR
JOIN v_Gs_Operating_System as OS on CDR.MachineID = OS.ResourceID
WHERE CDR.ClientState <> 0
ORDER BY LastBootUpTime0 Desc