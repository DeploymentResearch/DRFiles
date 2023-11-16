SELECT DISTINCT 
       CS.Manufacturer0 'Manufacturer',
       CS.Model0 Model,
       Count(*) as 'Quantity',
       CONVERT(date,BIOS.ReleaseDate0) as BIOSDate,
       BIOS.SMBIOSBIOSVersion0 as BIOSVersion
FROM v_R_System  as sys
       INNER JOIN v_GS_COMPUTER_SYSTEM CS ON sys.ResourceID=CS.ResourceID
       INNER JOIN v_GS_PC_BIOS BIOS ON sys.ResourceID=BIOS.ResourceID
group by CS.Manufacturer0,CS.Model0, CONVERT(date,BIOS.ReleaseDate0), BIOS.SMBIOSBIOSVersion0
order by CS.Manufacturer0,CS.Model0, CONVERT(date,BIOS.ReleaseDate0)
