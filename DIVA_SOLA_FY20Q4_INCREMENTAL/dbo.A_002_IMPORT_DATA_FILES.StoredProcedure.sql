USE [DIVA_SOLA_FY20Q4_INCREMENTAL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[A_002_IMPORT_DATA_FILES]
    @append_data varchar(1) = '',
    @filename varchar(MAX) = '',
    @DebugMsg varchar(1) = ''
AS
BEGIN
    -- =============================================
    -- Author:		<vinh.le@aufinia.com>
    -- Create date: <April 14, 2021>
    -- Description:	<Create reorganize A_002A_IMPORT_DATA_FILES script from KPMG again to make it clear and esay for understanding/fixing>
    -- =============================================
    SET NOCOUNT ON
    /*
        Step 1: Create database log table if it does not exist
    */
        IF OBJECT_ID('_DatabaseLogTable', 'U') IS NULL 
        BEGIN 
            CREATE TABLE [dbo].[_DatabaseLogTable] (
                [Database] nvarchar(max) NULL,
                [Object] nvarchar(max) NULL,
                [Object Type] nvarchar(max) NULL,
                [User] nvarchar(max) NULL,
                [Date] date NULL,
                [Time] time NULL,
                [Description] nvarchar(max) NULL,
                [Table] nvarchar(max),[Rows] int
            ) 
        END



    /*
        INITIALISE USER PARAMETERS
        ******************************************************************/

        /* USE_UNICODE 
        ** - SQL Server 2005: The bulk insert supports conversion of data to 
        **  unicode through supplying CODEPAGE = 65001 in bulk insert
        **    
        ** - SQL Server 2008: The conversion has been removed from SQL, so
        **  instead you have to convert the data to unicode before import
        ** use the tool "UTF8toUnicode.exe" for this, available in Tools & Guidance folder
    */
        --Declare variable
        DECLARE @use_unicode varchar(max)
        DECLARE @debugstatus	 varchar(max)
        DECLARE @IndexName  varchar(max)
        DECLARE @SQL_Statement	 varchar(max)
        DECLARE @startTime		 datetime -- variable at which the script was initially started
        DECLARE @currentTime	 datetime -- variable that is updated to keep track of performance of each code section in script
        DECLARE @create_indices bit
        DECLARE @clustered_indices bit
        DECLARE @ABAP_script_type nvarchar(max)
        DECLARE @fieldtermdef varchar(10)
        DECLARE @rowtermdef varchar(10)
        DECLARE @conversion_needed smallint
        DECLARE @fieldterm varchar(10)
        DECLARE @rowterm varchar(10)
        DECLARE @datafiletype varchar(100)
		DECLARE @incremental_tbl_name varchar(100)

        --Assign value to variables
        SET @use_unicode = 'CODEPAGE = 1200,'
        SET @currenttime	= CURRENT_TIMESTAMP
        SET @startTime		= CURRENT_TIMESTAMP
        SET @create_indices = 1
        SET @clustered_indices = 1
        SET @ABAP_script_type = ''
        SET @fieldtermdef = '#|#'
        SET @rowtermdef = ''
        SET @conversion_needed = 0
        SET @datafiletype = 'DATAFILETYPE = ''widechar'','
		SET @incremental_tbl_name = ''
        

    
    /*
        Step 3: Added @filename parameter to restrict staging to single table

    */
        -- validate file type entered, otherwise assume .txt
        IF LEN(@Filename) > 0
        BEGIN
            DECLARE @FilenameTmp varchar(max)
            SET @FilenameTmp = RIGHT(@FileName,4)
            IF NOT LEFT(@FilenameTmp,1) = '.'
                BEGIN
                    SET @FileName = @FileName + '.txt'
                END
        END    
    

    
    /*
        Step 4: INITIALISE OTHER PARAMETERS
    */
        DECLARE
                @errorcounter 	int 			= 0,
                @path 			varchar(255) 	= '',
                @errormsg 		varchar(max)	= '' 

        IF(@append_data = 'Y')
            SET @path = dbo.get_param('next_import_path')
        ELSE
            SET @path = dbo.get_param('first_import_path');

        SET @errormsg = 'Staging data from ' + @path
        RAISERROR (@errormsg, 0, 1) WITH NOWAIT



    /*
        Step 5: PREPARE FOR ASSEMBLY CODE
    */
        DECLARE @RowCount		as float 
	    DECLARE @ExecuteTime	as varchar(6)
	    DECLARE @RunDate		as varchar(10)
	    DECLARE @RunTime		as varchar(10)
        DECLARE @dbname varchar(255)
        SET @dbname = DB_NAME()

        -- More informative error messages
        SET @debugstatus	= 'DebugCodeSection: Alter authorizations on database ' + @dbname
        IF @DebugMsg = 'Y'
            BEGIN
                SET @RunTime		= REPLACE(CONVERT(VARCHAR(8), DATEDIFF(ss,@currenttime,CURRENT_TIMESTAMP)),':','')
                SET @currenttime	= CURRENT_TIMESTAMP
                SET @debugstatus	= @debugstatus + ' in ' + @runtime + 's'
                RAISERROR (@debugstatus, 0, 1) WITH NOWAIT
            END
        EXEC ('ALTER DATABASE [' + @dbname + '] SET TRUSTWORTHY ON')
        DECLARE @currentuser varchar(255)
        SET @currentuser = SYSTEM_USER
        EXEC ('ALTER AUTHORIZATION on DATABASE::[' + @dbname + '] to [' + @currentuser + ']')

    /*
        Step 6: CREATE ERROR FOLDER FOR BULK INSERT ERRORS
    */
        DECLARE @errpath varchar(255)
        DECLARE @CMD varchar(255)
        SET @errpath = @path + '\ERROR [' + REPLACE(CAST(GETDATE() as varchar(20)),':',' ') + ']'
        PRINT @errpath
        SET @debugstatus	= 'DebugCodeSection: Creating error folder for bulk insert errors in ' + @errpath
        IF @DebugMsg = 'Y'
            BEGIN
                SET @RunTime		= REPLACE(CONVERT(VARCHAR(8), DATEDIFF(ss,@currenttime,CURRENT_TIMESTAMP)),':','')
                SET @currenttime	= CURRENT_TIMESTAMP
                SET @debugstatus	= @debugstatus + ' in ' + @runtime + 's'
                RAISERROR (@debugstatus, 0, 1) WITH NOWAIT
            END

        SET @CMD = ' mkdir "' + @errpath + '"'
        EXEC xp_cmdshell @CMD, no_output

    /*
        Step 7: Check and create the IMPORT_LOG AND DUPLICATE_LOG if they did not exist
    */
        IF OBJECT_ID('LOG_A002A_IMPORT_LOG','U') IS NULL
        BEGIN
            CREATE TABLE LOG_A002A_IMPORT_LOG 
                (
                [TableName] varchar(255), 
                [NrRecords] bigint,
                [Timestamp] datetime default CURRENT_TIMESTAMP
                )
        END

        IF OBJECT_ID('LOG_A002A_DUP_LOG','U') IS NULL
            BEGIN
                CREATE TABLE dbo.LOG_A002A_DUP_LOG 
                    (
                        tbl nvarchar(MAX), 
                        TotalRows bigint, 
                        DuplicateRows bigint, 
                        DistinctRows Bigint
                    )
            END

    /*
        Step 8: COLLECT ALL IMPORT DATA FILES TO ALLFILES TABLE
                Contains filenames and tablenames.
    */
        SET @debugstatus	= 'DebugCodeSection: Reading files from ' + @path
        IF @DebugMsg = 'Y'
            BEGIN
                SET @RunTime		= REPLACE(CONVERT(VARCHAR(8), DATEDIFF(ss,@currenttime,CURRENT_TIMESTAMP)),':','')
                SET @currenttime	= CURRENT_TIMESTAMP
                SET @debugstatus	= @debugstatus + ' in ' + @runtime + 's'
                RAISERROR (@debugstatus, 0, 1) WITH NOWAIT
            END

        EXEC SP_REMOVE_TABLES 'ALLFILES'
        CREATE TABLE ALLFILES ([filename] VARCHAR(255),Depth INT, isfile int)
        INSERT ALLFILES EXEC xp_dirtree @path,1,1

        IF @filename <> '' 
	        DELETE FROM ALLFILES WHERE [filename] <> @filename

    /*
        Step 9: CREATE TABLE FOR STAGEDATALOG
    */
        SET @debugstatus	= 'DebugCodeSection: Loading LOG_A002A_STAGE_DATA_LOG table'
        IF @DebugMsg = 'Y'
            BEGIN
                SET @RunTime		= REPLACE(CONVERT(VARCHAR(8), DATEDIFF(ss,@currenttime,CURRENT_TIMESTAMP)),':','')
                SET @currenttime	= CURRENT_TIMESTAMP
                SET @debugstatus	= @debugstatus + ' in ' + @runtime + 's'
                RAISERROR (@debugstatus, 0, 1) WITH NOWAIT
            END

        IF OBJECT_ID('LOG_A002A_STAGE_DATA_LOG','U') IS NULL
            BEGIN
                CREATE TABLE LOG_A002A_STAGE_DATA_LOG 
                    (
                        [StageDate] varchar(8), 
                        [StageStartTime] varchar(6), 
                        [TableName] varchar(255), 
                        [NrRecords] float, 
                        [NrRecordsTotal] float,
                        [StageRunTime] varchar(10),
                        [StageParam] varchar(1),
                        [AppendData] varchar(1),
                        [Status] varchar(max),
                        [BulkInsertErrors] varchar(255)
                    )
            END

    /*
        Step 10: 
                Update starting statistics,
                Load staging preparation into stageDataLog
    */
        SET @ExecuteTime	= REPLACE(CONVERT(VARCHAR(8), CONVERT(time, CURRENT_TIMESTAMP)),':','')
        SET @RunDate		= REPLACE(CONVERT(VARCHAR(10),CONVERT(date, CURRENT_TIMESTAMP)),'-','')
        SET @RunTime		= REPLACE(CONVERT(VARCHAR(8), DATEDIFF(ss,@currenttime,CURRENT_TIMESTAMP)),':','')
        SET @currenttime	= CURRENT_TIMESTAMP

        --Load staging preparation into stageDataLog
        INSERT INTO [LOG_A002A_STAGE_DATA_LOG] ([TableName], [NrRecords], [StageDate], [StageStartTime], [StageRunTime], [StageParam], [AppendData])
        VALUES('Preparing staging', 0, @rundate, @ExecuteTime, @runtime, @ABAP_script_type, @Append_data)

        SET @debugstatus	= 'DebugCodeSection: Start import of table'
        IF @DebugMsg = 'Y'
            BEGIN
                SET @RunTime		= REPLACE(CONVERT(VARCHAR(8), DATEDIFF(ss,@currenttime,CURRENT_TIMESTAMP)),':','')
                SET @currenttime	= CURRENT_TIMESTAMP
                SET @debugstatus	= @debugstatus + ' in ' + @runtime + 's'
                RAISERROR (@debugstatus, 0, 1) WITH NOWAIT
            END

        DECLARE @tbl as varchar(max)
        DECLARE @TableIndex as Varchar(max)
        DECLARE @ID as int
        DECLARE @MaxID as int 
        ALTER TABLE allfiles Add TableNameIndex varchar(255)
	    ALTER TABLE allfiles Add RowNo Int
        

        UPDATE allfiles 
        SET TableNameIndex  = CASE  WHEN PATINDEX('%AGR_1016%',[filename]) > 0 OR PATINDEX('%AGR_1251%',[filename]) > 0 THEN left([filename], 8)
                                    ELSE left([filename],PATINDEX('%_[0-9][0-9][0-9][0-9]%.txt',[filename])-1) END
        WHERE
        (filename like '%.txt%') AND 
        (depth = 1) AND 
        (isfile = 1) AND
        Left(UPPER(Filename),4) <> 'KPMG'
        
        UPDATE ALLFILES SET Rowno = B.RowNo
        FROM ALLFILES A
        INNER JOIN (SELECT FileName,ROW_NUMBER() OVER(Partition by TableNameIndex order by [filename] ASC) RowNo FROM ALLFILES
                        WHERE (filename like '%.txt%') AND 
                        (depth = 1) AND 
                        (isfile = 1)
                    ) B
        ON A.filename = B.filename
    


    /*
        Step 11: Vinh update: Create an table only contain the last line number of each group file. We need to use this table to create index after the last file have been import.
		We need to update because the current version will be create index everytime table have been imported. it take alot of time.
        
    */
        EXEC SP_REMOVE_TABLES 'LAST_INDEX_OF_EACH_GROUP_FILE'
		SELECT TableNameIndex, MAX(Rowno) Rowno
		INTO LAST_INDEX_OF_EACH_GROUP_FILE
		FROM ALLFILES
		WHERE TableNameIndex IS NOT NULL
		GROUP BY TableNameIndex

    /*
        Step 12: Update by Vinh: March 2, 2021: Check and import the D003L table if it do exist in current database.
						With this update, we do not import DD03L manually for each refresh and move to DDIC database.
						We will import DD03L first and use it to import the other tables.
    */
        IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AM_DD03L_STRUCTURE')
            BEGIN
                PRINT 'Creating the AM_DD03L_STRUCTURE table.'
                CREATE TABLE [dbo].[AM_DD03L_STRUCTURE](
                    [TABNAME] [nvarchar](32) NULL,
                    [FIELDNAME] [nvarchar](32) NULL,
                    [AS4LOCAL] [nvarchar](3) NULL,
                    [AS4VERS] [nvarchar](6) NULL,
                    [POSITION] [nvarchar](6) NULL,
                    [KEYFLAG] [nvarchar](3) NULL,
                    [MANDATORY] [nvarchar](3) NULL,
                    [ROLLNAME] [nvarchar](32) NULL,
                    [CHECKTABLE] [nvarchar](32) NULL,
                    [ADMINFIELD] [nvarchar](3) NULL,
                    [INTTYPE] [nvarchar](3) NULL,
                    [INTLEN] [nvarchar](8) NULL,
                    [REFTABLE] [nvarchar](32) NULL,
                    [PRECFIELD] [nvarchar](32) NULL,
                    [REFFIELD] [nvarchar](32) NULL,
                    [CONROUT] [nvarchar](12) NULL,
                    [NOTNULL] [nvarchar](3) NULL,
                    [DATATYPE] [nvarchar](6) NULL,
                    [LENG] [nvarchar](8) NULL,
                    [DECIMALS] [nvarchar](8) NULL,
                    [DOMNAME] [nvarchar](32) NULL,
                    [SHLPORIGIN] [nvarchar](3) NULL,
                    [TABLETYPE] [nvarchar](3) NULL,
                    [DEPTH] [nvarchar](4) NULL,
                    [COMPTYPE] [nvarchar](3) NULL,
                    [REFTYPE] [nvarchar](3) NULL,
                    [LANGUFLAG] [nvarchar](3) NULL,
                    [DBPOSITION] [nvarchar](6) NULL,
                    [ANONYMOUS] [nvarchar](3) NULL,
                    [OUTPUTSTYLE] [nvarchar](4) NULL
                )
                INSERT [dbo].[AM_DD03L_STRUCTURE]
                VALUES (N'DD03L', N'ADMINFIELD', N'A', N'0000', N'0010', N'', N'', N'ADMINFIELD', N'', N'0', N'C', N'000002', N'', N'', N'', N'', N'', N'CHAR', N'000001', N'000000', N'AS4FLAG', N'F', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'ANONYMOUS', N'A', N'0000', N'0029', N'', N'', N'DDANONYM', N'', N'0', N'C', N'000002', N'', N'', N'', N'', N'X', N'CHAR', N'000001', N'000000', N'DDANONYM', N'F', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'AS4LOCAL', N'A', N'0000', N'0003', N'X', N'', N'AS4LOCAL', N'', N'0', N'C', N'000002', N'', N'', N'', N'', N'X', N'CHAR', N'000001', N'000000', N'AS4LOCAL', N'F', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'AS4VERS', N'A', N'0000', N'0004', N'X', N'', N'AS4VERS', N'', N'0', N'N', N'24', N'', N'', N'', N'', N'X', N'NUMC', N'12', N'000000', N'AS4VERS', N'', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'CHECKTABLE', N'A', N'0000', N'0009', N'', N'', N'CHECKTABLE', N'*', N'0', N'C', N'000060', N'', N'', N'', N'', N'', N'CHAR', N'000030', N'000000', N'AS4TAB', N'', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'COMPTYPE', N'A', N'0000', N'0025', N'', N'', N'COMPTYPE', N'', N'0', N'C', N'000002', N'', N'', N'', N'', N'', N'CHAR', N'000001', N'000000', N'COMPTYPE', N'F', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'CONROUT', N'A', N'0000', N'0016', N'', N'', N'CONROUT', N'', N'0', N'C', N'000020', N'', N'', N'', N'', N'', N'CHAR', N'000010', N'000000', N'CHAR10', N'', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'DATATYPE', N'A', N'0000', N'0018', N'', N'', N'DATATYPE_D', N'', N'0', N'C', N'000008', N'', N'', N'', N'', N'', N'CHAR', N'000004', N'000000', N'DATATYPE', N'F', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'DBPOSITION', N'A', N'0000', N'0028', N'', N'', N'TABFDPOS', N'', N'0', N'N', N'24', N'', N'', N'', N'', N'X', N'NUMC', N'12', N'000000', N'AS4POS', N'', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'DECIMALS', N'A', N'0000', N'0020', N'', N'', N'DECIMALS', N'', N'0', N'N', N'36', N'', N'', N'', N'', N'', N'NUMC', N'18', N'000000', N'DDLENG', N'', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'DEPTH', N'A', N'0000', N'0024', N'', N'', N'TYPEDEPTH', N'', N'0', N'N', N'12', N'', N'', N'', N'', N'', N'NUMC', N'6', N'000000', N'TYPEDEPTH', N'', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'DOMNAME', N'A', N'0000', N'0021', N'', N'', N'DOMNAME', N'DD01L', N'0', N'C', N'000060', N'', N'', N'', N'', N'', N'CHAR', N'000030', N'000000', N'DOMNAME', N'P', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'FIELDNAME', N'A', N'0000', N'0002', N'X', N'', N'FIELDNAME', N'', N'0', N'C', N'000060', N'', N'', N'', N'', N'X', N'CHAR', N'000030', N'000000', N'FDNAME', N'', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'INTLEN', N'A', N'0000', N'0012', N'', N'', N'INTLEN', N'', N'0', N'N', N'36', N'', N'', N'', N'', N'', N'NUMC', N'18', N'000000', N'DDLENG', N'', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'INTTYPE', N'A', N'0000', N'0011', N'', N'', N'INTTYPE', N'', N'0', N'C', N'000002', N'', N'', N'', N'', N'', N'CHAR', N'000001', N'000000', N'INTTYPE', N'F', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'KEYFLAG', N'A', N'0000', N'0006', N'', N'', N'KEYFLAG', N'', N'0', N'C', N'000002', N'', N'', N'', N'', N'', N'CHAR', N'000001', N'000000', N'KEYFLAG', N'F', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'LANGUFLAG', N'A', N'0000', N'0027', N'', N'', N'DDLANGUFLG', N'', N'0', N'C', N'000002', N'', N'', N'', N'', N'', N'CHAR', N'000001', N'000000', N'DDLANGUFLG', N'F', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'LENG', N'A', N'0000', N'0019', N'', N'', N'DDLENG', N'', N'0', N'N', N'36', N'', N'', N'', N'', N'', N'NUMC', N'18', N'000000', N'DDLENG', N'', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'MANDATORY', N'A', N'0000', N'0007', N'', N'', N'MANDATORY', N'', N'0', N'C', N'000002', N'', N'', N'', N'', N'', N'CHAR', N'000001', N'000000', N'AS4FLAG', N'F', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'NOTNULL', N'A', N'0000', N'0017', N'', N'', N'NOTNULL', N'', N'0', N'C', N'000002', N'', N'', N'', N'', N'', N'CHAR', N'000001', N'000000', N'NOTNULL', N'F', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'OUTPUTSTYLE', N'A', N'0000', N'0030', N'', N'', N'OUTPUTSTYLE', N'', N'0', N'N', N'12', N'', N'', N'', N'', N'X', N'NUMC', N'6', N'000000', N'OUTPUTSTYLE', N'F', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'POSITION', N'A', N'0000', N'0005', N'X', N'', N'TABFDPOS', N'', N'0', N'N', N'24', N'', N'', N'', N'', N'X', N'NUMC', N'12', N'000000', N'AS4POS', N'', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'PRECFIELD', N'A', N'0000', N'0014', N'', N'', N'PRECFIELD', N'*', N'0', N'C', N'000060', N'', N'', N'', N'', N'', N'CHAR', N'000030', N'000000', N'FDNAME', N'', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'REFFIELD', N'A', N'0000', N'0015', N'', N'', N'REFFIELD', N'*', N'0', N'C', N'000060', N'', N'', N'', N'', N'', N'CHAR', N'000030', N'000000', N'FDNAME', N'', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'REFTABLE', N'A', N'0000', N'0013', N'', N'', N'REFTABLE', N'*', N'0', N'C', N'000060', N'', N'', N'', N'', N'', N'CHAR', N'000030', N'000000', N'AS4TAB', N'', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'REFTYPE', N'A', N'0000', N'0026', N'', N'', N'DDREFTYPE', N'', N'0', N'C', N'000002', N'', N'', N'', N'', N'', N'CHAR', N'000001', N'000000', N'DDREFTYPE', N'F', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'ROLLNAME', N'A', N'0000', N'0008', N'', N'', N'ROLLNAME', N'DD04L', N'0', N'C', N'000060', N'', N'', N'', N'', N'', N'CHAR', N'000030', N'000000', N'ROLLNAME', N'P', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'SHLPORIGIN', N'A', N'0000', N'0022', N'', N'', N'SHLPORIGIN', N'', N'0', N'C', N'000002', N'', N'', N'', N'', N'', N'CHAR', N'000001', N'000000', N'SHLPORIGIN', N'F', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'TABLETYPE', N'A', N'0000', N'0023', N'', N'', N'DDTABTYPE', N'', N'0', N'C', N'000002', N'', N'', N'', N'', N'', N'CHAR', N'000001', N'000000', N'DDFLAG', N'F', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'TABNAME', N'A', N'0000', N'0001', N'X', N'', N'TABNAME', N'DD02L', N'0', N'C', N'000060', N'', N'', N'', N'', N'X', N'CHAR', N'000030', N'000000', N'AS4TAB', N'P', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
                ,(N'DD03L', N'SRS_ID', N'A', N'0000', N'0031', N'', N'', N'SRS_ID', N'', N'0', N'X', N'000004', N'', N'', N'', N'', N'', N'INT4', N'000010', N'000000', N'SRS_ID', N'', N'', N'00', N'E', N'', N'', N'0000', N'', N'00')
            END

		/*Import DD03L table from raw data file from path in AM_GLOBALS*/
		IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_DD03L') 
            BEGIN
                EXEC A_002A_SS01_IMPORT_DDIC
                EXEC SP_UNNAME_FIELD 'DD03L_', 'A_DD03L'

                /*
                    Update by Vinh: Increase length of some special fields to limit error during import process.
                */
                    UPDATE A_DD03L
                    SET INTLEN = INTLEN*3, LENG = LENG*3
                    WHERE DATATYPE IN ('RAW', 'LRAW', 'FLTP', 'NUMC') OR TABNAME = 'USR21'

                /*
                    Update by Vinh:
                        Update key fields for SIE INC JP for VBFA table because VBFA has flaged MANDT, RUUID as primary key instead of MANDT, VBELV, POSNV, VBELN, POSNN, VBTYP_N
                */

                    UPDATE A_DD03L
                    SET KEYFLAG = ''
                    WHERE (TABNAME = 'VBFA') OR (TABNAME IN ('T005X', 'KNVV') AND FIELDNAME = 'MANDT')

                    UPDATE A_DD03L
                    SET KEYFLAG = 'X'
                    WHERE TABNAME = 'VBFA' AND FIELDNAME IN ('MANDT' ,'VBELV' ,'POSNV' ,'VBELN' ,'POSNN' ,'VBTYP_N')
            END

    /*
        Step 13: Print alltables which contains all information about raw data files for importing
    */
        SELECT [Filename], ISNULL(TableNameIndex,0), ISNULL(RowNo,0)
        FROM allfiles
        WHERE (filename like '%.txt%' and filename not like 'DD03L%.txt%' and filename not like 'TVST%.txt%') AND 
              (depth = 1) AND (isfile = 1) 
              And Left(UPPER(Filename),4) <> 'KPMG'
    
    /*
        Step 14: Create sql cursor, then loop each table in allfiles table and import to database.
    */
        DECLARE c1 CURSOR FOR
            SELECT [Filename], ISNULL(TableNameIndex,0), ISNULL(RowNo,0)
            FROM allfiles
            WHERE (filename like '%.txt%' and filename not like 'DD03L%.txt%' and filename not like 'TVST%.txt%') AND 
                  (depth = 1) AND (isfile = 1)
                  And Left(UPPER(Filename),4) <> 'KPMG'
        OPEN c1
        FETCH NEXT FROM c1 INTO @tbl,@TableIndex,@ID
        WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @RunTime		= REPLACE(CONVERT(VARCHAR(8), DATEDIFF(ss,@currenttime,CURRENT_TIMESTAMP)),':','')
                SET @currenttime	= CURRENT_TIMESTAMP	
                SET @errormsg = char(13) + 'A_' + @tbl + ': preparing for bulk insert after ' + @Runtime + 's initializing'
                SET @errormsg = 'A_' + @tbl + ': preparing for bulk insert'
                SET @startTime	= CURRENT_TIMESTAMP
                SET @ExecuteTime	= REPLACE(CONVERT(VARCHAR(8), CONVERT(time, CURRENT_TIMESTAMP)),':','')
                SET @RunDate		= REPLACE(CONVERT(VARCHAR(10),CONVERT(date, CURRENT_TIMESTAMP)),'-','')
                SET @filename = @tbl
                INSERT INTO [LOG_A002A_STAGE_DATA_LOG] ([TableName], [StageDate], [StageStartTime], [StageParam], [AppendData])
                VALUES(REPLACE('A_' + @tbl, '-tmp',''), @rundate, @ExecuteTime, @ABAP_script_type, @Append_data)
                DECLARE @filepath varchar(255)
                RAISERROR (@errormsg, 0, 1) WITH NOWAIT

                BEGIN TRY
                    SELECT @MaxID = Max(Rowno) 
                    FROM LAST_INDEX_OF_EACH_GROUP_FILE
                    WHERE TableNameIndex= @TableIndex
                    GROUP BY TableNameIndex
                    SET @filepath = @path + '\' + @tbl
                    
                    IF @tbl not like 'KPMG_LOG_RECORDCOUNT%'
                        BEGIN
                            SET @tbl = CASE WHEN PATINDEX('%AGR_1016%',@tbl) > 0 OR PATINDEX('%AGR_1251%',@tbl) > 0 THEN left(@tbl, 8)
                                            ELSE left(@tbl,PATINDEX('%_[0-9][0-9][0-9][0-9]%.txt',@tbl)-1) END
                        END
                    DECLARE @firstrow varchar(3)
                    SET @firstrow = '2'
                    SET @fieldterm = @fieldtermdef      
                    SET @rowterm = @rowtermdef
					SET @incremental_tbl_name = @tbl +  + '_INCREMENTAL_DATA'

                    /*****************************************************************
                    Use CLR function to read the first two lines of the raw text file into tableheader
                    * The first line will be used to determine the field names
                    * The second line will be used to determine the field lengths (for temp and non-SAP tables)
                    ******************************************************************/
                    SET @debugstatus	= 'DebugCodeSection: Create table header A_' + @tbl
                    IF @DebugMsg = 'Y'
                        BEGIN
                            SET @RunTime		= REPLACE(CONVERT(VARCHAR(8), DATEDIFF(ss,@currenttime,CURRENT_TIMESTAMP)),':','')
                            SET @currenttime	= CURRENT_TIMESTAMP
                            SET @debugstatus	= @debugstatus + ' in ' + @runtime + 's'
                            RAISERROR (@debugstatus, 0, 1) WITH NOWAIT
                        END

                    EXEC SP_REMOVE_TABLES 'tableheader'
                    CREATE TABLE tableheader (ID INT IDENTITY(1,1), field varchar(max))
                  
                    INSERT tableheader EXEC dbo.ReadNLines @filepath,  1
                    /*****************************************************************
                    Transfer the first line to the @fields string (used to determine field names)
                    Transfer the second line to the @lengths string (used to determine field lengths)
                    ******************************************************************/
                    DECLARE @fields nvarchar(max)
                    
                    SELECT @fields = replace(ltrim(rtrim(field)),char(63),'') FROM tableheader WHERE ID=1
                    
                    IF @fields = '' PRINT '[ERROR] missing fields on first row of file'

                    /*****************************************************************
                    Populate fields; 1 row per table field

                    -- output: fields (id int, items varchar(max), length int)
                    ******************************************************************/
                    
                    -- HdG more informative error messages
                    SET @debugstatus	= 'DebugCodeSection: populating fields A_' + @tbl
                    IF @DebugMsg = 'Y'
                        BEGIN
                            SET @RunTime		= REPLACE(CONVERT(VARCHAR(8), DATEDIFF(ss,@currenttime,CURRENT_TIMESTAMP)),':','')
                            SET @currenttime	= CURRENT_TIMESTAMP
                            SET @debugstatus	= @debugstatus + ' in ' + @runtime + 's'
                            RAISERROR (@debugstatus, 0, 1) WITH NOWAIT
                        END

                    EXEC SP_REMOVE_TABLES 'fields'
                    SELECT t1.ID, t1.items
                    INTO fields
                    FROM dbo.split(@fields, @fieldterm) t1


                    /*****************************************************************
                    Create table logic for SAP tables and store this into a new table 
                    fielddefs to loop through

                    - fielddef:     contains field definitions for tables in SAP DDIC
                    - fielddeftmp:  contains field definitions for unconverted flat files using SAP lengths
                    - fielddefgen:  contains field definitions based on length in second line in raw text file
                    - needstmp:     will be used to determine whether a 'tmp' table and conversion is needed after bulk insert
                    - conversion:   contains conversion string for tables that need conversion
                    ******************************************************************/
                    EXEC SP_REMOVE_TABLES 'fielddefs'
                    DECLARE @curtime varchar(12)
	                SET @curtime = REPLACE(REPLACE(REPLACE(CONVERT(varchar(16), GetDate(),120),':',''),'-',''),' ','')
                    SELECT 
                        t1.ID,
                        @tbl as [tablename], 
                        t1.items as [fieldname],
                        CASE t2.INTTYPE
                            WHEN 'D' then 'date DEFAULT NULL'
                            WHEN 'I' then 'int DEFAULT 0'
                            WHEN 'P' THEN CASE WHEN t2.DATATYPE = 'CURR' THEN 'money' ELSE 'decimal(' + t2.LENG + ', ' + t2.DECIMALS + ' ) DEFAULT 0' END
                            ELSE 
                            'nvarchar(' + cast((cast(t2.LENG as int) + 2) as varchar) + ') DEFAULT (N'''')'
                        END AS [fielddef],

                        CASE t2.INTTYPE
                            WHEN 'D' then 'nvarchar(' + cast((cast(t2.LENG as int) + 2) as varchar) + ')'
                            WHEN 'I' then 'nvarchar(' + cast((cast(t2.INTLEN as int) + 2) as varchar) + ')'
                            WHEN 'P' then 'nvarchar(' + cast((cast(t2.LENG as int) * 2 + 2) as varchar) + ')'
                            ELSE 'nvarchar(' + cast((cast(t2.LENG as int) + 2) as varchar) + ') DEFAULT (N'''')'
                        END AS [fielddeftmp],
                        
                        CASE t2.INTTYPE
                            WHEN 'D' then 1
                            WHEN 'I' then 1
                            WHEN 'P' then 1
                        ELSE 0 END AS [needstmp],

                        -- DATE CONVERSION:
                        -- Output of date should be: 12-31-1999      
                        -- With old ABAP script the date is formatted as 31.12.1999
                        -- With TBD the date is formatted as 19991231
                        
                        -- FLOAT CONVERSION
                        -- Output of float should be: 490000.00 
                        -- With old ABAP script float is formatted as 490.000,00
                        -- With TBD float is formatted as 490000.00
                        
                        -- This is conversion in case of OLD ABAP script
                        CASE t2.INTTYPE
                            WHEN 'D' then 'CASE WHEN ISDATE(SUBSTRING(' + t1.items + ', 4, 2) + ''-'' + LEFT(' + t1.items + ',2) + ''-'' + RIGHT(' + t1.items + ',4))=1 THEN CONVERT(DATE, SUBSTRING(' + t1.items + ', 4, 2) + ''-'' + LEFT(' + t1.items + ',2) + ''-'' + RIGHT(' + t1.items + ',4)) ELSE NULL END as '
                            WHEN 'I' then 'CAST(' + t1.items + ' as int) as '
                            WHEN 'P' then 'CASE WHEN LEN(LTRIM(' + t1.items + '))=0 THEN null ELSE CASE WHEN RIGHT(' + t1.items + ',1)=''-'' THEN -1 ELSE 1 END * cast(REPLACE(REPLACE(REPLACE(REPLACE(' + t1.items + ',''.'',''''),'','',''.''),''-'',''''),''/'','''') as decimal(' + t2.LENG + ', ' + t2.DECIMALS + ' )) END as '
                        ELSE '' END AS [conversion],

                        -- This is conversion in case of NEW ABAP script, but T005X bug.
                        -- no conversion needed for Dates or Integers	  
                        -- For decimals this removes dots and commas from string, then stuffs a dot in the string based on nr. of decimals in field definition.
                        -- REVERSE is used twice to help the STUFF command insert the dot from the right of the string. 
                        -- Script adds a 0 so comma is also set correctly for small numbers. For instance for an amount 0,07 the text file contains only 7 and script would give a 'null' when trying to add comma outside of the string.
                        
                        CASE t2.INTTYPE        
                            WHEN 'P' then 'CAST(REVERSE(STUFF(REVERSE(REPLACE(REPLACE(REPLACE(LTRIM(' + t1.items + '),''.'',''''),'','',''''),''/'','''')) + CASE WHEN LEN(LTRIM('+ t1.items + ')) <= '+ t2.DECIMALS + ' THEN REPLICATE(''0'','+ t2.DECIMALS + ') ELSE '''' END,'+ t2.DECIMALS + '+1,0,''.'')) as decimal(' + t2.LENG + ', ' + t2.DECIMALS + ' )) as '
                        ELSE '' END AS [conversion_T005X],
                                
                        -- Note: * which is caused by RFC_READ_TABLE bug is replaced with nothing. Do not rely on these fields!!!
                        CASE t2.INTTYPE
                            WHEN 'D' then 'CASE WHEN ISDATE(SUBSTRING(' + t1.items + ',5,2) + ''-'' + RIGHT(' + t1.items + ', 2) + ''-'' + LEFT(' + t1.items + ',4))=1 THEN CONVERT(DATE, SUBSTRING(' + t1.items + ',5,2) + ''-'' + RIGHT(' + t1.items + ', 2) + ''-'' + LEFT(' + t1.items + ',4)) ELSE NULL END as '
                            WHEN 'I' then 'CAST(' + t1.items + ' as int) as '
                            WHEN 'P' then 'CASE WHEN LEN(LTRIM(' + t1.items + '))=0 THEN null ELSE CASE WHEN RIGHT(' + t1.items + ',1)=''-'' THEN -1 ELSE 1 END * cast(REPLACE(REPLACE(' + t1.items + ',''*'',''''),''-'','''') as decimal(' + t2.LENG + ', ' + t2.DECIMALS + ' )) END as '
                        ELSE '' END AS [conversion_tbd],      
                        
                        t2.KEYFLAG 
                    INTO fielddefs
                    FROM fields t1 
                    LEFT JOIN A_DD03L t2
                    ON  (@TableIndex = t2.tabname) and 
                        (t1.items = t2.fieldname)
                    WHERE ISNULL(t1.items,'') <> ''


                    /*****************************************************************
                    Enter field values manually for exceptional fields where DD03L 
                    doesn't provide correct data type: 
                    TVRO.TDVZND -> specified as 'P', but contains ':'
                    TVRO.FAHZTD -> specified as 'P', but contains ':' 
                    ******************************************************************/    
                    UPDATE fielddefs
                    SET [fielddef] = 'nvarchar(11)',
                        [conversion] = ''
                    WHERE (tablename = 'TVRO') and (fieldname = 'TDVZND' OR fieldname = 'FAHZTD')
                        
                    UPDATE fielddefs
                    SET [fielddef] = 'varchar(1)'
                    WHERE [fielddef] = 'nvarchar(1)'
                        
                    UPDATE fielddefs
                    SET [fielddef] = 'nvarchar(70)'
                    WHERE (tablename = 'TPFID') and (fieldname = 'PFINST' OR fieldname = 'PFSTART')

                    /*****************************************************************
                    Check if field definition is complete	
                    ******************************************************************/   
                    DECLARE @incompleteNum int
                    SELECT @incompleteNum = count(*) FROM fielddefs WHERE [fielddef] IS NULL
                        
                    DECLARE @MissingFields VARCHAR(MAX) 

                    SELECT @MissingFields = COALESCE(@MissingFields,'') + [fieldname] + ''  
                    FROM fielddefs WHERE [fielddef] IS NULL
                        
                    IF @incompleteNum > 0 
                        PRINT '[ERROR] A_'+@tbl + ': '+CAST(@incompleteNum AS NVARCHAR(MAX))+' fields without definition. Update SAP DDIC to proceed: '+
                            @MissingFields + ', SAPTable = '+@TableIndex

                    SELECT * FROM fielddefs
                    SELECT * FROM fields
                    SELECT * FROM tableheader
                    RAISERROR('DEBUG MESSAGE',0,1) WITH NOWAIT

                    /*****************************************************************
                    Loop through the fields and create tables
                    ******************************************************************/
                    SET @debugstatus	= 'DebugCodeSection: start create table statements ' + @tbl
                    IF @DebugMsg = 'Y'
                        BEGIN
                            SET @RunTime		= REPLACE(CONVERT(VARCHAR(8), DATEDIFF(ss,@currenttime,CURRENT_TIMESTAMP)),':','')
                            SET @currenttime	= CURRENT_TIMESTAMP
                            SET @debugstatus	= @debugstatus + ' in ' + @runtime + 's'
                            RAISERROR (@debugstatus, 0, 1) WITH NOWAIT
                        END

                    DECLARE @createtable varchar(max)
                    DECLARE @createtabletmp varchar(max)
                    DECLARE @select varchar(max)
                    DECLARE @conversion varchar(max)
                    DECLARE @conversion_tbd varchar(max) 
                    DECLARE @conversion_T005X varchar(max)        
                    DECLARE @keyfields varchar(max)
                    DECLARE @needstmp int
                    
                    IF @append_data = 'Y'
                        BEGIN
                            SET @createtable    = 'CREATE TABLE [A_' + @incremental_tbl_name + '] ('
                            SET @createtabletmp = 'CREATE TABLE [A_' + @incremental_tbl_name + '-tmp] ('
                            SET @needstmp       = 0
                            SET @select         = 'INSERT INTO [A_' + @incremental_tbl_name + '] ('
                            SET @conversion     = 'SELECT '
                            SET @conversion_tbd = 'SELECT '    
                            SET @conversion_T005X = 'SELECT ' 
                        END
                    ELSE
                        BEGIN
                            SET @createtable    = 'CREATE TABLE [A_' + @tbl + '] ('
                            SET @createtabletmp = 'CREATE TABLE [A_' + @tbl + '-tmp] ('
                            SET @needstmp       = 0
                            SET @select         = 'INSERT INTO [A_' + @tbl + '] ('
                            SET @conversion     = 'SELECT '
                            SET @conversion_tbd = 'SELECT '    
                            SET @conversion_T005X = 'SELECT ' 
                        END
                      

                    IF @append_data = 'Y'
                        SET @keyfields = 'CREATE UNIQUE CLUSTERED INDEX [INDEX_A_' + @tbl + '_' + @curtime + '] ON [A_' + @incremental_tbl_name + '] ('
                    ELSE 
                        SET @keyfields = 'CREATE UNIQUE CLUSTERED INDEX [INDEX_A_' + @tbl + '_' + @curtime + '] ON [A_' + @tbl + '] ('


                    SELECT 
                        @createtable    = @createtable + '[' + @tbl + '_' + fieldname + '] '  + fielddef + ',', 
                        @createtabletmp = @createtabletmp + '[' + @tbl + '_' + fieldname + '] ' + fielddeftmp + ',',
                        @needstmp       = @needstmp + needstmp,
                        @select         = @select + (@tbl + '_' + fieldname) + ',',
                        @conversion     = @conversion + conversion + '['+ @tbl + '_' + fieldname + '] ,',
                        @conversion_tbd = @conversion_tbd + conversion_tbd + '['+ @tbl + '_' + fieldname + '] ,', 
                        @conversion_T005X = @conversion_T005X + conversion_T005X + (@tbl + '_' + fieldname) + ',',      
                        @keyfields      = @keyfields + CASE WHEN keyflag='X' THEN (@tbl + '_' + fieldname) + ',' ELSE '' END  
                    FROM fielddefs
					WHERE EXISTS(SELECT TOP 1 1 FROM fields WHERE fielddefs.fieldname = fields.items)
                    ORDER BY ID		-- Added ORDER BY to force field order of the source txt file.

                    -- remove last ',' and append ')' in order to close 1 create table statement
                    SET @createtable    = LEFT(@createtable, LEN(@createtable)-1) + ')'
                    SET @createtabletmp = LEFT(@createtabletmp, LEN(@createtabletmp)-1) + ')'
                    SET @select         = LEFT(@select, LEN(@select)-1) + ') '
                    SET @conversion     = LEFT(@conversion, LEN(@conversion)-1) + ' FROM [A_' + @tbl + '-tmp]'
                    SET @conversion_tbd = LEFT(@conversion_tbd, LEN(@conversion_tbd)-1) + ' FROM [A_' + @tbl + '-tmp]'
                    SET @conversion_T005X = LEFT(@conversion_T005X, LEN(@conversion_T005X)-1) + ' FROM [A_' + @tbl + '-tmp]'
                    SET @keyfields      = LEFT(@keyfields, LEN(@keyfields)-1) + ')'


                    IF @append_data = 'N' OR @append_data = '0' OR @append_data = ''
                        BEGIN
                            ----- Drop the existing table if it's first ime
                            IF @ID =1 
                            BEGIN
                                IF OBJECT_ID('[A_' + @tbl + ']','U') IS NOT NULL 
                                    EXEC(N'DROP TABLE [A_' + @tbl + ']')
                            
                                -- also delete -tmp table if it exists, regardless of conversion need
                                IF OBJECT_ID('[A_' + @tbl + '-tmp]','U') IS NOT NULL 
                                    EXEC(N'DROP TABLE [A_' + @tbl + '-tmp]')
                            END
                            IF OBJECT_ID('[A_' + @tbl + ']','U') IS NULL
                                BEGIN
                                    SET @errormsg = ('A_' + @tbl) + ': creating table'  
                                    SET @SQL_statement = @createtable -- in case of errors provide user with failed statement
                                    
                                    EXEC (@createtable)
                                END
                        END
                    ELSE
                        BEGIN
                            ----- Drop the existing table if it's first ime
                            IF @ID =1 
								BEGIN
									IF OBJECT_ID('[A_' + @incremental_tbl_name + ']','U') IS NOT NULL 
										EXEC(N'DROP TABLE [A_' + @incremental_tbl_name + ']')
                            
									-- also delete -tmp table if it exists, regardless of conversion need
									IF OBJECT_ID('[A_' + @incremental_tbl_name + '-tmp]','U') IS NOT NULL 
										EXEC(N'DROP TABLE [A_' + @incremental_tbl_name + '-tmp]')
								END
                            IF OBJECT_ID('[A_' + @incremental_tbl_name + ']','U') IS NULL
                                BEGIN
                                    SET @errormsg = ('A_' + @incremental_tbl_name) + ': creating table'  
                                    SET @SQL_statement = @createtable -- in case of errors provide user with failed statement
                                    
                                    EXEC (@createtable)
                                END
                        END

                    -- bulk insert won't take variables, so make a sql and execute it instead:
                    DECLARE @sql varchar(max)

                    /*****************************************************************
                    Start of bulk insert: identify row delimiter
                    
                    Row delimiter scenarios;
                    1) Windows default | CRLF = Carriage Return (char(10)) + Line Feed (char(13)) | SQL synonym: \n 
                    2) Unix Default    | LF   = Line Feed (char(13))                              | SQL synonym: <n/a>
                    
                    To detect the row delimiter it is enough to detect a carriage return.
                    ******************************************************************/  
                    
                    SET @debugstatus	= 'DebugCodeSection: execute bulk insert A_' + @tbl
                    IF @DebugMsg = 'Y'
                        BEGIN
                            SET @RunTime		= REPLACE(CONVERT(VARCHAR(8), DATEDIFF(ss,@currenttime,CURRENT_TIMESTAMP)),':','')
                            SET @currenttime	= CURRENT_TIMESTAMP
                            SET @debugstatus	= @debugstatus + ' in ' + @runtime + 's'
                            RAISERROR (@debugstatus, 0, 1) WITH NOWAIT
                        END

                    DECLARE @rowdelim varchar(2)
                    EXEC SP_REMOVE_TABLES 'rowdelim'
                    CREATE TABLE rowdelim (ID INT IDENTITY(1,1), field nvarchar(max))

                    -- use CLR function to get first 8000 characters from file. 
                    -- should be enough to contain a row delimiter. 
                    INSERT rowdelim EXEC ReadNChars @filepath,8000
                    SELECT @rowdelim = CASE WHEN Charindex(char(13),field) = 0 THEN char(10) ELSE '\n' END FROM rowdelim
                   
                    SET @errormsg = 'A_' + @tbl + ': starting bulk insert'
                    RAISERROR(@errormsg, 0, 1) WITH NOWAIT

					IF @append_data = 'Y'
						BEGIN
							SET @sql = 'BULK INSERT [A_' + @incremental_tbl_name + '] FROM ''' + @filepath + ''' '
							+ '     WITH (
									' + @use_unicode + '
									' + @datafiletype + '
									FIELDTERMINATOR = ''' + @fieldterm + ''', 
									ROWTERMINATOR = ''' + @rowterm + @rowdelim + ''',
									MAXERRORS = 1000,
									FIRSTROW = ' + @firstrow + ',
									TABLOCK,
									ERRORFILE = ''' + @errpath + '\' + REPLACE(REPLACE(@filename, '.txt', ''), '.TXT', '') + '''
									)'
                    
							SET @SQL_statement = @sql -- in case of errors, return this statement to user
							EXEC (@sql)
						END
					ELSE
						BEGIN
							SET @sql = 'BULK INSERT [A_' + @tbl + '] FROM ''' + @filepath + ''' '
								+ '     WITH (
										' + @use_unicode + '
										' + @datafiletype + '
										FIELDTERMINATOR = ''' + @fieldterm + ''', 
										ROWTERMINATOR = ''' + @rowterm + @rowdelim + ''',
										MAXERRORS = 1000,
										FIRSTROW = ' + @firstrow + ',
										TABLOCK,
										ERRORFILE = ''' + @errpath + '\' + REPLACE(REPLACE(@filename, '.txt', ''), '.TXT', '') + '''
										)'
                    
								SET @SQL_statement = @sql -- in case of errors, return this statement to user
								EXEC (@sql)
						END


                    SET @rowcount = @@ROWCOUNT


                    INSERT INTO LOG_A002A_IMPORT_LOG
                    (
                        TableName, NrRecords
                    )
                    SELECT @filename,@RowCount

                    SET @debugstatus	= 'DebugCodeSection: storing staging statistics A_' + @tbl
                    IF @DebugMsg = 'Y'
                        BEGIN
                            SET @RunTime		= REPLACE(CONVERT(VARCHAR(8), DATEDIFF(ss,@currenttime,CURRENT_TIMESTAMP)),':','')
                            SET @currenttime	= CURRENT_TIMESTAMP
                            SET @debugstatus	= @debugstatus + ' in ' + @runtime + 's'
                            RAISERROR (@debugstatus, 0, 1) WITH NOWAIT
                        END
                        
                    --	Update staging results into stageDataLog
                    UPDATE [LOG_A002A_STAGE_DATA_LOG]
                        SET [NrRecords]		= @RowCount
                        FROM [LOG_A002A_STAGE_DATA_LOG]
                        WHERE 
                            [TableName] = REPLACE('A_' + @tbl, '-tmp','')
                            AND
                            [StageDate] = @RunDate
                            AND
                            [StageStartTime] = @ExecuteTime 

                    SET @RunTime		= REPLACE(CONVERT(VARCHAR(8), DATEDIFF(ss,@currenttime,CURRENT_TIMESTAMP)),':','')
                    SET @currenttime	= CURRENT_TIMESTAMP	
                    SET @errormsg = @tbl + ': imported' + ' in ' + @Runtime + 's'
                    RAISERROR(@errormsg, 0, 1) WITH NOWAIT 

                    /*****************************************************************
                    Add index on key fields
                    ******************************************************************/    

                    SET @debugstatus	= 'DebugCodeSection: adding indexes to fields' + @tbl
                    IF @DebugMsg = 'Y'
                        BEGIN
                            SET @RunTime		= REPLACE(CONVERT(VARCHAR(8), DATEDIFF(ss,@currenttime,CURRENT_TIMESTAMP)),':','')
                            SET @currenttime	= CURRENT_TIMESTAMP
                            SET @debugstatus	= @debugstatus + ' in ' + @runtime + 's'
                            RAISERROR (@debugstatus, 0, 1) WITH NOWAIT
                        END

                    IF @ID = @MaxID and @ID <> 0
						IF @append_data = 'Y'
							BEGIN
								PRINT @keyfields
								SET @errormsg = @incremental_tbl_name + ': start create index' 
								RAISERROR(@errormsg, 0, 1) WITH NOWAIT 
								SET @incremental_tbl_name = REPLACE(@incremental_tbl_name, '-tmp', '')
								PRINT 'Removing duplicates!.....'
								EXEC dbo.[A_002B_REMOVE_DUPLICATES] @incremental_tbl_name
								PRINT 'Duplicates removed successfully!.....'

								EXEC (@keyfields)
                        
								SET @errormsg = 'A_' + @incremental_tbl_name + ': indexed (clustered)' 
								IF @clustered_indices = 1 
									BEGIN
										SET @errormsg = @errormsg + ' (unique)'
									END


								RAISERROR(@errormsg , 0, 1) WITH NOWAIT
							END
						ELSE
							BEGIN
								PRINT @keyfields
								SET @errormsg = @tbl + ': start create index' 
								RAISERROR(@errormsg, 0, 1) WITH NOWAIT 
								SET @tbl = REPLACE(@tbl, '-tmp', '')
                    
								PRINT 'Removing duplicates!.....'
								EXEC dbo.[A_002B_REMOVE_DUPLICATES] @tbl
								PRINT 'Duplicates removed successfully!.....'

								EXEC (@keyfields)
                        
								SET @errormsg = 'A_' + @tbl + ': indexed (clustered)' 
								IF @clustered_indices = 1 
									BEGIN
										SET @errormsg = @errormsg + ' (unique)'
									END


								RAISERROR(@errormsg , 0, 1) WITH NOWAIT
							END
                    

                    -- time from initiating staging of this table
                    SET @RunTime	= CONVERT(VARCHAR(8), DATEDIFF(ss,@startTime,CURRENT_TIMESTAMP))
                    -- count total nr of rows in table
                    SELECT @RowCount = Row_Count
                    FROM sys.dm_db_partition_stats
                    WHERE Object_Name(Object_Id) = 'A_' + @tbl

                    UPDATE [LOG_A002A_STAGE_DATA_LOG]
                    SET     [NrRecordsTotal]	= @RowCount,
                            [StageRunTime]		= @RunTime,
                            [Status]			= 'Staged successfully'
                        FROM [LOG_A002A_STAGE_DATA_LOG]
                        WHERE [TableName] = 'A_' + @tbl AND
                            [StageDate] = @RunDate AND
                            [StageStartTime] = @ExecuteTime 


                END TRY
                BEGIN CATCH
                    IF error_number() = 1505 -- if the error is related to a clustered unique index that cannot be created because the index is not unique, create a clustered non unique index
                    BEGIN
                        SET @keyfields = REPLACE(@keyfields,'CREATE UNIQUE CLUSTERED INDEX', 'CREATE CLUSTERED INDEX')
                        PRINT @keyfields
                        EXEC (@keyfields)
                        SET @errormsg = 'A_' + @tbl + ': indexed (clustered)' 
                        
                        RAISERROR(@errormsg , 0, 1) WITH NOWAIT
                    
                        -- time from initiating staging of this table
                        SET @RunTime	= CONVERT(VARCHAR(8), DATEDIFF(ss,@startTime,CURRENT_TIMESTAMP))

                        -- count total nr of rows in table
                        SELECT @RowCount = Row_Count
                        FROM sys.dm_db_partition_stats
                        WHERE Object_Name(Object_Id) = 'A_' + @tbl
                        
                        UPDATE [LOG_A002A_STAGE_DATA_LOG]
                            SET 
                            [NrRecordsTotal]	= @RowCount,
                            [StageRunTime]		= @RunTime,
                            [Status]			= 'Staged successfully'
                        FROM [LOG_A002A_STAGE_DATA_LOG]
                        WHERE 
                            [TableName] = 'A_' + @tbl
                            AND
                            [StageDate] = @RunDate
                            AND
                            [StageStartTime] = @ExecuteTime 

                    END 
                ELSE
                    BEGIN
                    SET @errormsg = '[ERROR] A_' + @tbl + ' (error nr: ' + ltrim(str(error_number())) + ') MSG: ' + error_message()
                    
                    -- old message
                    --SET @errormsg = @errormsg + char(13) + char(10) + 'Bulk insert statement provided to assist in debugging: ' + char(13) + char(10) + @sql
                    --RAISERROR(@errormsg, 0, 1) WITH NOWAIT  

                    SET @errormsg = 'Failed at ' + @debugstatus + char(13) + char(13) + 'Last statement before failing: ' + char(13) + char(10) + @SQL_statement
                    RAISERROR(@errormsg, 0, 1) WITH NOWAIT  
                    
                    SET @errorcounter = @errorcounter + 1

                    -- log error with failed statement
                    UPDATE [LOG_A002A_STAGE_DATA_LOG]
                        SET 
                        [Status]			= @SQL_Statement 
                    FROM [LOG_A002A_STAGE_DATA_LOG]
                    WHERE 
                        [TableName] = 'A_' + @tbl
                        AND
                        [StageDate] = @RunDate
                        AND
                        [StageStartTime] = @ExecuteTime 

                    END
                END CATCH
                FETCH NEXT FROM c1 INTO @tbl,@TableIndex,@ID
            END
            CLOSE c1
            DEALLOCATE c1

        /*
            Step 15: Summary the process' log
        */
        IF @errorcounter = 0 
            BEGIN
                SET @errormsg = char(13) + 'Data staged succesfully without errors in Stage_data script!' 
            END
        ELSE  
            BEGIN
                SET @errormsg = char(13) + 'ERRORS during data staging: ' + RTRIM(Convert(char(10),@errorcounter)) + ' tables did not stage successfully'
                SET @errormsg = @errormsg + char(13) + char(10) + 'Don''t forget to check for possible additional errors in the error folder!' 
                -- display failed tables
                SELECT * FROM LOG_A002A_STAGE_DATA_LOG	WHERE ISNULL([Status],'') NOT LIKE 'Staged successfully' ORDER BY [StageDate] ASC, [StageStartTime] ASC
                RAISERROR(@errormsg, 0, 1) WITH NOWAIT
            END

        -- check for errors during bulk insert

        IF @DebugMsg = 'Y'
            BEGIN
            RAISERROR('Loading bulk insert error files', 0, 1) WITH NOWAIT
            END
		EXEC SP_REMOVE_TABLES 'ErrorFILES'
        CREATE TABLE ErrorFILES ([filename] VARCHAR(255),Depth INT, isfile int)
        INSERT ErrorFILES EXEC xp_dirtree @errpath,1,1

        -- solve error 'Cannot resolve the collation conflict between "SQL_Latin1_General_CP1_CI_AS" and "Latin1_General_CI_AS" in the equal to operation.'
        ALTER TABLE ErrorFILES
        ALTER COLUMN [Filename]
        VARCHAR(100) COLLATE Latin1_General_CI_AS NOT NULL

        -- mark tables with bulk insert errors
        IF @DebugMsg = 'Y'
            BEGIN
            RAISERROR('Updating staging log for bulk insert errors', 0, 1) WITH NOWAIT
            END

        SELECT @RowCount = COUNT(*) FROM ErrorFILES
        IF @RowCount > 0
            BEGIN
                UPDATE [LOG_A002A_STAGE_DATA_LOG]
                    SET 
                    [Status] = 'Errors during BulkInsert',
                    [BulkInsertErrors]	= 'Check error folder ' + @errpath
                FROM [LOG_A002A_STAGE_DATA_LOG]
                INNER JOIN (
                    SELECT DISTINCT REPLACE(REPLACE([Filename],'-tmp',''),'.Error.Txt','') AS [TableName] FROM ErrorFILES
                    ) AS [TablesWithErrors] ON [LOG_A002A_STAGE_DATA_LOG].[TableName] = [TablesWithErrors].[TableName]
                WHERE 
                    [StageDate] = @RunDate
                    AND
                    [StageStartTime] = @ExecuteTime 
            
                -- return bulk insert errors specifically
                SELECT 
                    @RunDate AS [StageDate],
                    @ExecuteTime AS [StageStartTime],
                    'BULK INSERT ERRORS FOUND' AS [TableName],
                    '' AS [Status],
                    '' AS [BulkInsertErrors]
                FROM [LOG_A002A_STAGE_DATA_LOG]
                UNION
                SELECT 
                    [StageDate],
                    [StageStartTime],
                    [TableName],
                    [Status],
                    [BulkInsertErrors]
                FROM LOG_A002A_STAGE_DATA_LOG 
                WHERE 
                    [Status] = 'Errors during BulkInsert'
                    AND
                    [StageDate] = @RunDate
                    AND
                    [StageStartTime] = @ExecuteTime
                ORDER BY [StageDate] ASC, [StageStartTime] ASC
            END

        IF @DebugMsg = 'Y'
            BEGIN
            RAISERROR('Updating staging log for tables without bulk insert errors', 0, 1) WITH NOWAIT
            END
        -- update remaining tables without bulk insert errors
        UPDATE [LOG_A002A_STAGE_DATA_LOG]
            SET 
            [BulkInsertErrors]	= 'No errors during BulkInsert'
        FROM [LOG_A002A_STAGE_DATA_LOG]
        WHERE 
            [BulkInsertErrors] IS NULL
            AND
            [StageDate] = @RunDate
            AND
            [StageStartTime] = @ExecuteTime 


    IF @DebugMsg = 'Y'
        BEGIN
            RAISERROR('Return staging history log to user', 0, 1) WITH NOWAIT
        END
    -- display staging statistics
    SELECT '0' AS [StageDate]
        ,'0' AS [StageStartTime]
        ,'STAGING HISTORY LOG:' AS [TableName]
        ,'' AS [NrRecords]
        ,'' AS [NrRecordsTotal]
        ,'' AS [StageRunTime]
        ,'' AS [StageParam]
        ,'' AS [AppendData]
        ,'' AS [Status]
        ,'' AS [BulkInsertErrors]
    FROM LOG_A002A_STAGE_DATA_LOG
    UNION
    SELECT [StageDate]
        ,[StageStartTime]
        ,[TableName]
        ,[NrRecords]
        ,[NrRecordsTotal]
        ,[StageRunTime]
        ,[StageParam]
        ,[AppendData]
        ,[Status]
        ,[BulkInsertErrors] 
    FROM LOG_A002A_STAGE_DATA_LOG ORDER BY [StageDate] ASC, [StageStartTime] ASC
END
GO
