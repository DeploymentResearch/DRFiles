SET NOCOUNT ON;
GO
USE [master];
GO
/************************************************************************************************************************
    REQUIRED VARIABLES TO UPDATE:
    Make sure to update the following variables!
************************************************************************************************************************/
DECLARE  @CMSiteCode  nchar(3) = N'PS1' -- This is the Site Code you are going to use for this CM Site.
        ,@ExecuteCmds bit = 1; -- 0 = Testing; Change this to 1 in order to actually create the database!

/************************************************************************************************************************
    OPTIONAL VARIABLES:
    These variables are optional. You can use these to customize how you want your database created. If you don't update
    these then the default values will be used in the script.
    Variable Explanations:
    @NumTotalDataFiles   : This is the total number of data files you want to create for the database. 
                           The default is to create a total of 4 data files.
    @SecondDataDrive     : Updating this to a drive letter (such as "O") will tell the script to create half of the files on the default
                           drive and the other half of the files on the drive specified. If the default data file location is
                           the same drive as what is specified then all files will be created on the same disk.
                           The default is to create all files on the same disk.
    @InitialDataFileSize : This is where you control how large to create the data files initially.
                           This is the size of each data file, therefore, the total size of the db will be: (@InitialDataFileSize * @NumTotalDataFiles)+@InitialLogFileSize
                           Example of specifying a size: N'123456MB' (can use KB, MB, or GB).
                           The default is to create each data file 2.5 GB in size. (A total data size of 10 GB if using the default file numbers)
    @InitialLogFileSize  : This is where you control how large of a log file to create initially.
                           Example of specifying a size: N'123456MB' (can use KB, MB, or GB).
                           The default is to create the log file at 5 GB in size.
    @PriDataFileGrowth   : This is where you control how to grow your data files when they need more space. The default growth size
                           in SQL Server is awful so we're going to change it to something better. I'm not allowing percentage growths!
                           Example of specifying a size: N'123456MB' (can use KB, MB, or GB).
                           The default is to grow the data files by 1 GB.
    @LogFileGrowth       : This is where you control how to grow your log file when it needs more space. The default growth size
                           in SQL Server is awful so we're going to change it to something better. I'm not allowing percentage growths!
                           Example of specifying a size: N'123456MB' (can use KB, MB, or GB).
                           The default is to grow the data files by 1 GB.
************************************************************************************************************************/
DECLARE  @NumTotalDataFiles   tinyint = 1
        ,@SecondDataDrive     nchar(1) = N''
        ,@InitialDataFileSize nvarchar(50) = N'40960MB'
        ,@InitialLogFileSize  nvarchar(50) = N'1024MB'
        ,@PriDataFileGrowth   nvarchar(50) = N'1024MB'
        ,@LogFileGrowth       nvarchar(50) = N'1024MB';


/************************************************************************************************************************
    INTERNAL VARIABLES:
    These are NOT to be changed or updated!
************************************************************************************************************************/
DECLARE  @DefLog       nvarchar(512)
        ,@DefMdf       nvarchar(512)
        ,@SecNdf       nvarchar(512)
        ,@CreateDB     nvarchar(max)
        ,@AddtlFiles   nvarchar(max) = N''
        ,@LogScript    nvarchar(max)
        ,@AddtlFileNum tinyint = 1
        ,@TwoDrives    bit = 1
        ,@Mdfi         tinyint
        ,@Ldfi         tinyint
        ,@Arg          nvarchar(10)
        ,@MdlDtaFlSze  int
        ,@MdlLogFlSze  int;

/************************************************************************************************************************
    Make sure the Site Code is correct before continuing.
************************************************************************************************************************/
IF ISNULL(@CMSiteCode, N'') = N'' OR LEN(@CMSiteCode) != 3
GOTO IncorrectInputParameters;

/************************************************************************************************************************
    Make sure the database doesn't already exist before continuing.
************************************************************************************************************************/
SET @CMSiteCode = UPPER(@CMSiteCode);
IF DATABASEPROPERTYEX(N'CM_'+@CMSiteCode, 'status') IS NOT NULL
GOTO DBExists;

/************************************************************************************************************************
    Initialize/Check Working Variables
************************************************************************************************************************/
-- Remove any spaces from the size and growth definitions:
SET @PriDataFileGrowth = UPPER(REPLACE(@PriDataFileGrowth,N' ',N''));
SET @LogFileGrowth = UPPER(REPLACE(@LogFileGrowth,N' ',N''));
SET @InitialDataFileSize = UPPER(REPLACE(@InitialDataFileSize,N' ',N''));
SET @InitialLogFileSize = UPPER(REPLACE(@InitialLogFileSize,N' ',N''));
SET @SecondDataDrive = UPPER(@SecondDataDrive);

-- Ensure the initial file sizes aren't smaller than the model database size; if so update the size:
SELECT  @MdlDtaFlSze = size*8 FROM model.sys.database_files WHERE type = 0;
SELECT  @MdlLogFlSze = size*8 FROM model.sys.database_files WHERE type = 1;
IF CAST(LEFT(@InitialDataFileSize,LEN(@InitialDataFileSize)-2) AS int) < @MdlDtaFlSze
BEGIN
    PRINT N'The initial data file size is smaller than the model database; in order to proceed update the size to be the same as model.';
    SET @InitialDataFileSize = CAST(@MdlDtaFlSze AS nvarchar(48))+N'KB';
    PRINT N'@InitialDataFileSize has been set to: '+@InitialDataFileSize;
    PRINT N'';
END;

IF (CAST(LEFT(@InitialLogFileSize,LEN(@InitialLogFileSize)-2) AS int)) < @MdlLogFlSze
BEGIN
    PRINT N'The initial log file size is smaller than the model database; in order to proceed update the size to be the same as model.';
    SET @InitialLogFileSize = CAST(@MdlLogFlSze AS nvarchar(48))+N'KB';
    PRINT N'@InitialLogFileSize has been set to: '+@InitialLogFileSize;
    PRINT N'';
END;

-- Get the Default MDF location (from the registry):
PRINT N'Getting the default location for data files from the registry.';
EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @DefMdf OUTPUT, 'no_output';
IF @DefMdf IS NULL -- if we couldn't get the key from this location for some reason then look at the startup parameters:
BEGIN
    SET @Mdfi = 0;
    WHILE @Mdfi < 100
    BEGIN
        SELECT @Arg = N'SQLArg' + CAST(@Mdfi AS nvarchar(4));
        EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters', @Arg, @DefMdf OUTPUT, 'no_output';
        IF LOWER(LEFT(REVERSE(@DefMdf),10)) = N'fdm.retsam'
        BEGIN
            -- If we found the parameter for the master data file then set the variable and stop processing this loop:
            SELECT @DefMdf = SUBSTRING(@DefMdf,3,CHARINDEX(N'\master.mdf',@DefMdf)-3);
            BREAK;
        END;
        ELSE
        SET @DefMdf = NULL;

        SELECT @Mdfi += 1;
    END;
END;
PRINT N'Default Data File location found: '+@DefMdf;
PRINT N'';

-- Get the Default LDF location (from the registry):
PRINT N'Getting the default location for log files from the registry.';
EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @DefLog OUTPUT, 'no_output';
IF @DefLog IS NULL -- if we couldn't get the key from this location for some reason then look at the startup parameters:
BEGIN
    SET @Ldfi = 0;
    WHILE @Ldfi < 100
    BEGIN
        SELECT @Arg = N'SQLArg' + CAST(@Ldfi AS nvarchar(4));
        EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters', @Arg, @DefLog OUTPUT, 'no_output';
        IF LOWER(LEFT(REVERSE(@DefLog),11)) = N'fdl.goltsam'
        BEGIN
            -- If we found the parameter for the master log file then set the variable and stop processing this loop:
            SELECT @DefLog = SUBSTRING(@DefLog,3,CHARINDEX(N'\mastlog.ldf',@DefLog)-3);
            BREAK;
        END;
        ELSE
        SET @DefLog = NULL;

        SELECT @Ldfi += 1;
    END;
END;
PRINT N'Default Log File location found: '+@DefLog;
PRINT N'';

-- Determine whether data files will be stored on two drives or on the same drive:
IF (ISNULL(@SecondDataDrive, N'') = N'') OR (LEFT(@DefMdf,1) = @SecondDataDrive)
BEGIN
    SET @TwoDrives = 0;
    PRINT N'All data files will be stored on one drive.';
    PRINT N'If you intended for the files to be on different drives you can move them at a later time.';
    PRINT N'  -- to do so see this article: http://msdn.microsoft.com/en-us/library/ms345483.aspx';
    PRINT N'';
END;
ELSE
BEGIN
    SET @SecNdf = @SecondDataDrive + SUBSTRING(@DefMdf,2,LEN(@DefMdf)-1);
    PRINT N'Secondary Data File Location set to: '+@SecNdf;
    PRINT N'';
END;

/************************************************************************************************************************
    Ensure the Secondary data file location exists; if not create it:
************************************************************************************************************************/
IF @TwoDrives = 1
BEGIN
    DECLARE  @FileExists TABLE ( isFile       int NOT NULL
                                ,isDirectory  int NOT NULL
                                ,ParentExists int NOT NULL
                                );
    INSERT @FileExists
    EXECUTE master..xp_fileexist @SecNdf;

    IF (SELECT isDirectory FROM @FileExists) = 0
    BEGIN
        PRINT N'The directory "'+@SecNdf+N'" does not exist.';
        IF @ExecuteCmds = 1 PRINT N'We will create this directory before proceeding...';
        IF @ExecuteCmds = 1 EXECUTE master..xp_create_subdir @SecNdf;
        IF @ExecuteCmds = 1 PRINT N'...directory has been created.';
        PRINT N'';
    END
END;

/************************************************************************************************************************
    Create the statement that will create the database with all user input and defaults.
************************************************************************************************************************/
-- First, create the 'additional' data files portion of the statement:
WHILE @AddtlFileNum < @NumTotalDataFiles
BEGIN
IF @TwoDrives = 0
-- If we are storing all the files on the same drive then we only need to use this logic:
SELECT @AddtlFiles += N'              ,( NAME = N''CM_'+@CMSiteCode+N'_'+CAST(@AddtlFileNum AS nvarchar(3))+N'''
                ,FILENAME = N'''+@DefMdf+N'\CM_'+@CMSiteCode+N'_'+CAST(@AddtlFileNum AS nvarchar(3))+N'.ndf''
                ,SIZE = '+@InitialDataFileSize+N'
                ,FILEGROWTH = '+@PriDataFileGrowth+N'
                )
';
ELSE -- else, we'll be storing data files in two locations
    BEGIN
    IF @AddtlFileNum % 2 = 1
    -- The "odd" number data files will be stored on the second drive:
    SELECT @AddtlFiles += N'              ,( NAME = N''CM_'+@CMSiteCode+N'_'+CAST(@AddtlFileNum AS nvarchar(3))+N'''
                    ,FILENAME = N'''+@SecNdf+N'\CM_'+@CMSiteCode+N'_'+CAST(@AddtlFileNum AS nvarchar(3))+N'.ndf''
                    ,SIZE = '+@InitialDataFileSize+N'
                    ,FILEGROWTH = '+@PriDataFileGrowth+N'
                    )
    ';
    ELSE
    -- The even numbered files will be stored on the default drive:
    SELECT @AddtlFiles += N'              ,( NAME = N''CM_'+@CMSiteCode+N'_'+CAST(@AddtlFileNum AS nvarchar(3))+N'''
                    ,FILENAME = N'''+@DefMdf+N'\CM_'+@CMSiteCode+N'_'+CAST(@AddtlFileNum AS nvarchar(3))+N'.ndf''
                    ,SIZE = '+@InitialDataFileSize+N'
                    ,FILEGROWTH = '+@PriDataFileGrowth+N'
                    )
    ';
    END;
SELECT @AddtlFileNum += 1;
END;

-- Second, create the log file portion of the statement:
SET @LogScript = N'LOG ON ( NAME = N''CM_'+@CMSiteCode+N'_Log''
        ,FILENAME = N'''+@DefLog+N'\CM_'+@CMSiteCode+N'_Log.LDF''
        ,SIZE = '+@InitialLogFileSize+N'
        ,FILEGROWTH = '+@LogFileGrowth+N'
        );';

-- Third, create the beginning portion of the statement:
SET @CreateDB = N'CREATE DATABASE [CM_'+@CMSiteCode+N']
    ON PRIMARY ( NAME = N''CM_'+@CMSiteCode+N'''
                ,FILENAME = N'''+@DefMdf+N'\CM_'+@CMSiteCode+N'.mdf''
                ,SIZE = '+@InitialDataFileSize+N'
                ,FILEGROWTH = '+@PriDataFileGrowth+N'
                )
';

-- Finally, put all the statements together in one final statement:
SELECT @CreateDB += @AddtlFiles;
SELECT @CreateDB += @LogScript;

/************************************************************************************************************************
    Create the database using the statement built:
************************************************************************************************************************/
IF @ExecuteCmds = 1
BEGIN
    BEGIN TRY
        PRINT N'Attempting to create the database specified. This is the command we are running:';
        PRINT N'';
        PRINT @CreateDB;
        PRINT N'';
        EXECUTE sp_executesql @CreateDB;
        EXECUTE (N'ALTER AUTHORIZATION ON DATABASE::[CM_'+@CMSiteCode+N'] TO sa;');
		EXECUTE (N'ALTER DATABASE [CM_'+@CMSiteCode+N'] SET COMPATIBILITY_LEVEL = 150;');
        PRINT N'Database creation successful!';
        PRINT N'Check the database properties to see what files were created and where they were created.';
        PRINT N'If you want to move them to another location you can do so now.';
        PRINT N'';
        GOTO EndScript;
    END TRY
    BEGIN CATCH
        PRINT N'Error Creating Database';
        PRINT GETDATE();
        PRINT N'Error Message: '+ERROR_MESSAGE();
        PRINT N'Error Severity: '+CONVERT(nvarchar(25),ERROR_SEVERITY());
        PRINT N'Error State: '+CONVERT(nvarchar(25),ERROR_STATE());
        PRINT N'';
        GOTO ExitError;
    END CATCH;
END;
ELSE
BEGIN
    PRINT N'The variable "@ExecuteCmds" is not set to 1, therefore, we didn''t execute any actual commands.';
    PRINT N'The code below is what would''ve been run, or you can copy/paste it into a new window and execute it to create your database:';
    PRINT N'';
    PRINT @CreateDB;
    PRINT N'';
    PRINT N'';
    GOTO EndScript;
END;

/************************************************************************************************************************
    Exits and End of Script:
************************************************************************************************************************/
IncorrectInputParameters:
IF ISNULL(@CMSiteCode,N'') = N''
BEGIN
    PRINT N'The required input variable "@CMSiteCode" was not updated.';
    PRINT N'Update the variable to the three character Site Code you will use for your ConfigMgr site.';
    PRINT N'';
END;
ELSE
BEGIN
    PRINT N'The required input variable "@CMSiteCode" is not accurate.';
    PRINT N'Update the variable to the three character Site Code you will use for your ConfigMgr site.';
    PRINT N'';
END;
GOTO EndScript;

DBExists:
PRINT N'Database '+QUOTENAME(N'CM_'+@CMSiteCode)+N' already exists! Cannot create a database of the same name on the same instance!!';
GOTO EndScript;

ExitError:
PRINT N'Error returned; see previous messages for details. Ending script.';
GOTO EndScript;

EndScript:
PRINT N'End of Script.';
GO