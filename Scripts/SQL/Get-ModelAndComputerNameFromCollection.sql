DECLARE @CollectionID NVARCHAR(8) = 'PS100019';  -- your CollectionID

SELECT
    rs.Name0               AS ComputerName,
    cs.Manufacturer0       AS Manufacturer,
    cs.Model0              AS Model
FROM v_FullCollectionMembership AS fcm
JOIN v_R_System             AS rs ON rs.ResourceID = fcm.ResourceID
JOIN v_GS_COMPUTER_SYSTEM   AS cs ON cs.ResourceID = fcm.ResourceID
WHERE fcm.CollectionID = @CollectionID
ORDER BY rs.Name0;
