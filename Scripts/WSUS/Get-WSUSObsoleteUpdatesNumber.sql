USE SUSDB

DECLARE @var1 INT, @curitem INT, @totaltodelete INT

CREATE TABLE #results (Col1 INT) 
INSERT INTO #results(Col1) EXEC spGetObsoleteUpdatesToCleanup

SELECT COUNT(*) FROM #results
DROP TABLE #results