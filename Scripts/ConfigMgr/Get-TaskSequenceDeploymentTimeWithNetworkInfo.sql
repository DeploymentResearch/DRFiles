USE CM_PS1

Select Distinct v_R_System.Name0 as ComputerName , 
v_RA_System_IPSubnets.IP_Subnets0,
v_Network_DATA_Serialized.DefaultIPGateway0,
MIN(V_TaskExecutionStatus.ExecutionTime) as 'StartTime', 
MAX(v_TaskExecutionStatus.ExecutionTime) as 'EndTime', 
DATEDIFF(MINUTE, MIN(V_TaskExecutionSTatus.ExecutionTime) , 
MAX(V_TaskExecutionSTatus.ExecutionTime)) as 'DeploymentTimeInMinutes', V_Package.Name as TaskSequence

from v_TaskExecutionStatus left outer join v_R_System on v_TaskExecutionStatus.ResourceID = v_R_System.ResourceID 
left Join v_AdvertisementInfo on v_AdvertisementInfo.AdvertisementID = v_TaskExecutionStatus.AdvertisementID 
Left join v_Package on v_Package.PackageID = v_AdvertisementInfo.PackageID 
left outer join v_Advertisement on v_TaskExecutionStatus.AdvertisementID = v_Advertisement.AdvertisementID 
left outer join v_TaskSequencePackage on v_Advertisement.PackageID = v_TaskSequencePackage.PackageID 
left outer join v_RA_System_IPSubnets on v_R_System.ResourceID = v_RA_System_IPSubnets.ResourceID 
left outer join v_Network_DATA_Serialized on v_R_System.ResourceID = v_Network_DATA_Serialized.ResourceID 
Where v_Network_DATA_Serialized.DefaultIPGateway0 IS NOT NULL 
--where v_TaskSequencePackage.BootImageID is not NULL 
-- and v_TaskSequencePackage.Name = 'Windows 11 Enterprise x64 24H2'
and V_TaskExecutionStatus.ExecutionTime > '2025-01-01'

Group By v_R_System.Name0,v_Package.Name,v_RA_System_IPSubnets.IP_Subnets0,v_Network_DATA_Serialized.DefaultIPGateway0 order by V_r_system.Name0