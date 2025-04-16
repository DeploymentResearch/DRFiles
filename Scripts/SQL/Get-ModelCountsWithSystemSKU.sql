SELECT
si.SystemProductName0 AS Model,
COUNT(*) AS Count
,si.BaseBoardProduct0
,si.SystemSKU0
,si.BIOSVersion0
FROM

v_GS_MS_SYSTEMINFORMATION SI
where si.SystemProductName0 not like 'Virt%'
and si.SystemProductName0 not like 'HVM%'
GROUP BY si.SystemProductName0,si.BaseBoardProduct0, si.SystemSKU0,si.BIOSVersion0
order by Count(*) DESC;