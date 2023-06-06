Select Distinct v_R_System.Name0 as ComputerName , 
MIN(V_TaskExecutionStatus.ExecutionTime) as 'StartTime', 
MAX(v_TaskExecutionStatus.ExecutionTime) as 'EndTime', 
DATEDIFF(MINUTE, MIN(V_TaskExecutionSTatus.ExecutionTime) , 
MAX(V_TaskExecutionSTatus.ExecutionTime)) as 'DeploymentTimeInMinutes', V_Package.Name as TaskSequence
from v_TaskExecutionStatus left outer join v_R_System on v_TaskExecutionStatus.ResourceID = v_R_System.ResourceID 
left Join v_AdvertisementInfo on v_AdvertisementInfo.AdvertisementID = v_TaskExecutionStatus.AdvertisementID 
Left join v_Package on v_Package.PackageID = v_AdvertisementInfo.PackageID 
left outer join v_Advertisement on v_TaskExecutionStatus.AdvertisementID = v_Advertisement.AdvertisementID 
left outer join v_TaskSequencePackage on v_Advertisement.PackageID = v_TaskSequencePackage.PackageID 
where v_TaskSequencePackage.BootImageID is not NULL Group By v_R_System.Name0,v_Package.Name order by V_r_system.Name0