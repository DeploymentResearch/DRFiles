
Select * from BGB_ResStatus

Select BGB.IPAddress, BGB.IPSubnet, R.Name0  from BGB_ResStatus as BGB
Inner Join v_R_System as R ON BGB.ResourceID = R.ResourceID
Where Name0 = 'PC0002'


Select BGB.IPAddress, BGB.IPSubnet, R.Name0  from BGB_ResStatus as BGB
Inner Join v_R_System as R ON BGB.ResourceID = R.ResourceID
Where IPAddress LIKE '192.168.%'

Select BGB.IPAddress, BGB.IPSubnet, R.Name0  from BGB_ResStatus as BGB Inner Join v_R_System as R ON BGB.ResourceID = R.ResourceID

-- Select only ipv4 addresses
SELECT CASE WHEN CHARINDEX(N',',IPAddress) = 0 THEN IPAddress
             ELSE SUBSTRING(IPAddress,1,CHARINDEX(N',',IPAddress)-1)
        END AS [FirstIpAddress],
        CASE WHEN CHARINDEX(N',',IPSubnet) = 0 THEN IPSubnet
             ELSE SUBSTRING(IPSubnet,1,CHARINDEX(N',',IPSubnet)-1)
        END AS [FirstIpSubnet]
  FROM dbo.Bgb_ResStatus;

  -- Select only ipv4 addresses
SELECT CASE WHEN CHARINDEX(N',',IPAddress) = 0 THEN IPAddress
             ELSE SUBSTRING(IPAddress,1,CHARINDEX(N',',IPAddress)-1)
        END AS [FirstIpAddress],
        CASE WHEN CHARINDEX(N',',IPSubnet) = 0 THEN IPSubnet
             ELSE SUBSTRING(IPSubnet,1,CHARINDEX(N',',IPSubnet)-1)
        END AS [FirstIpSubnet]
  FROM dbo.Bgb_ResStatus
  Where [FirstIpAddress] like '192.168.2.11'
