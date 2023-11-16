SELECT DISTINCT 
       CS.Manufacturer0 'Manufacturer',
       CS.Model0 Model,
       Count(*) as 'Quantity'
FROM v_R_System  as sys
       INNER JOIN v_GS_COMPUTER_SYSTEM CS ON sys.ResourceID=CS.ResourceID
group by CS.Manufacturer0,CS.Model0
order by CS.Manufacturer0,CS.Model0 
