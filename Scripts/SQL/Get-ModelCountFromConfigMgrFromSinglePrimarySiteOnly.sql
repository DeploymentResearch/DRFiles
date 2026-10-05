DECLARE @SiteCode varchar(3) = 'PS1'

SELECT
       CS.Manufacturer0 AS 'Manufacturer',
       CS.Model0 AS 'Model',
       COUNT(*) AS 'Quantity'
FROM v_R_System AS sys
       INNER JOIN v_GS_COMPUTER_SYSTEM AS CS ON sys.ResourceID = CS.ResourceID
       INNER JOIN v_RA_System_SMSAssignedSites AS AS1 ON sys.ResourceID = AS1.ResourceID
WHERE AS1.SMS_Assigned_Sites0 = @SiteCode
GROUP BY CS.Manufacturer0, CS.Model0
ORDER BY CS.Manufacturer0, CS.Model0