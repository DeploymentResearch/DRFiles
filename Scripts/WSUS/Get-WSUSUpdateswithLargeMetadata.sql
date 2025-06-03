select 
  u.UpdateID, lp.Title, pr.CreationDate
  from 
  tbUpdate u 
  inner join tbRevision r on u.LocalUpdateID = r.LocalUpdateID 
  inner join tbProperty pr on pr.RevisionID = r.RevisionID 
  inner join tbLocalizedPropertyForRevision lpr on r.RevisionID = lpr.RevisionID 
  inner join tbLocalizedProperty lp on lpr.LocalizedPropertyID = lp.LocalizedPropertyID 
 where 
  lpr.LanguageID = 1033 
  and r.RevisionID in (
select
  t1.RevisionID
from
  tbBundleAll t1
  inner join tbBundleAtLeastOne t2 on t1.BundledID=t2.BundledID
where
  t2.RevisionID in(SELECT dbo.tbXml.RevisionID FROM dbo.tbXml
INNER JOIN dbo.tbProperty ON dbo.tbXml.RevisionID = dbo.tbProperty.RevisionID
where ISNULL(datalength(dbo.tbXml.RootElementXmlCompressed), 0) > 50000) and ishidden=0 and  pr.ExplicitlyDeployable=1)
