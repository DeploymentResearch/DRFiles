USE SUSDB
DECLARE @var1 INT, @curitem INT, @totaltodelete INT
DECLARE @msg nvarchar(200)

CREATE TABLE #results (Col1 INT) 
INSERT INTO #results(Col1) EXEC spGetObsoleteUpdatesToCleanup

SET @totaltodelete = (SELECT COUNT(*) FROM #results)
SELECT @curitem=1

DECLARE WC Cursor 
FOR 
SELECT Col1 FROM #results

OPEN WC
FETCH NEXT FROM WC INTO @var1 WHILE (@@FETCH_STATUS > -1)
BEGIN SET @msg = cast(@curitem as varchar(5)) + '/' + cast(@totaltodelete as varchar(5)) + ': Deleting ' + CONVERT(varchar(10), @var1) + ' ' + cast(getdate() as varchar(30))
RAISERROR(@msg,0,1) WITH NOWAIT
EXEC spDeleteUpdate @localUpdateID=@var1
SET @curitem = @curitem +1
-- Change the below value for batch size <101 = 100 updates
IF @curitem < 101
 FETCH NEXT FROM WC INTO @var1
END
CLOSE WC
DEALLOCATE WC
DROP TABLE #results