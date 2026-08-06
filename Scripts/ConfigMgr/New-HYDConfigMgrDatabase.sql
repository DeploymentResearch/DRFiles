USE master;
GO

DECLARE @SiteCode nchar(3)     = N'PS1',
        @NumFiles tinyint      = 1,
        @DataSize nvarchar(20) = N'20480MB',
        @LogSize  nvarchar(20) = N'4096MB',
        @Growth   nvarchar(20) = N'1024MB',
        @Compat   nvarchar(4)  = N'150';

DECLARE @DataPath nvarchar(260),
        @LogPath  nvarchar(260),
        @DbName   sysname = N'CM_' + @SiteCode,
        @sql      nvarchar(max),
        @i        tinyint = 1;

-- ConfigMgr requires this instance collation; stop before doing anything if it is wrong.
IF CONVERT(nvarchar(128), SERVERPROPERTY('Collation')) <> N'SQL_Latin1_General_CP1_CI_AS'
BEGIN
    PRINT N'ABORT: instance collation is '
        + CONVERT(nvarchar(128), SERVERPROPERTY('Collation'))
        + N'. ConfigMgr requires SQL_Latin1_General_CP1_CI_AS.';
    RETURN;
END;

IF DB_ID(@DbName) IS NOT NULL
BEGIN
    PRINT N'ABORT: ' + @DbName + N' already exists.';
    RETURN;
END;

-- Default file locations from the instance registry keys
EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
     N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @DataPath OUTPUT;
EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
     N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog',  @LogPath  OUTPUT;

IF RIGHT(@DataPath,1) = N'\' SET @DataPath = LEFT(@DataPath, LEN(@DataPath)-1);
IF RIGHT(@LogPath,1)  = N'\' SET @LogPath  = LEFT(@LogPath,  LEN(@LogPath)-1);

SET @sql = N'CREATE DATABASE [' + @DbName + N']
ON PRIMARY ( NAME = N''' + @DbName + N''', FILENAME = N''' + @DataPath + N'\' + @DbName + N'.mdf'', SIZE = ' + @DataSize + N', FILEGROWTH = ' + @Growth + N' )';

WHILE @i < @NumFiles
BEGIN
    SET @sql += N'
           ,( NAME = N''' + @DbName + N'_' + CAST(@i AS nvarchar(3)) + N''', FILENAME = N''' + @DataPath + N'\' + @DbName + N'_' + CAST(@i AS nvarchar(3)) + N'.ndf'', SIZE = ' + @DataSize + N', FILEGROWTH = ' + @Growth + N' )';
    SET @i += 1;
END;

SET @sql += N'
LOG ON ( NAME = N''' + @DbName + N'_Log'', FILENAME = N''' + @LogPath + N'\' + @DbName + N'_Log.ldf'', SIZE = ' + @LogSize + N', FILEGROWTH = ' + @Growth + N' )
COLLATE SQL_Latin1_General_CP1_CI_AS;';

PRINT @sql;

EXEC (@sql);
EXEC (N'ALTER DATABASE [' + @DbName + N'] SET COMPATIBILITY_LEVEL = ' + @Compat + N';');
EXEC (N'ALTER AUTHORIZATION ON DATABASE::[' + @DbName + N'] TO sa;');

SELECT name, collation_name, compatibility_level, SUSER_SNAME(owner_sid) AS owner
FROM sys.databases WHERE name = @DbName;