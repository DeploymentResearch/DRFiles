SELECT p.Name, 
	p.Description, 
	n.SourceSize as SourceInKB, 
	dp.LastRefreshTime, 
	p.Manufacturer, 
	p.Version, 
	p.Language, 
	p.SourceSite, 
	p.PackageID, 
	SUBSTRING(dp.ServerNALPath, CHARINDEX('\\', dp.ServerNALPath)+2,(CHARINDEX('"]', dp.ServerNALPath) - CHARINDEX('\\', dp.ServerNALPath))-3) AS DP,
	psd.InstallStatus
FROM v_Package p
INNER JOIN v_DistributionPoint dp ON p.PackageID = dp.PackageID
LEFT JOIN v_PackageStatusRootSummarizer n ON p.PackageID = n.PackageID
LEFT JOIN v_PackageStatusDistPointsSumm psd ON dp.ServerNALPath=psd.ServerNALPath
AND dp.PackageID=psd.PackageID LEFT JOIN v_PackageStatus ps ON dp.ServerNALPath=ps.PkgServer
AND dp.PackageID=ps.PackageID