USE [DIVA_SOLA_FY20Q4_INCREMENTAL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
  Remove any duplicates
  $$ See comments below - script to be checked 
  
  --------------------------------------------------------------
  Update history
  --------------------------------------------------------------
  Date		|	Author	|	Description
  05-02-2013   Aart-Jan Boor (AJB) Created
  12-09-2017	CW			Naming convention and update logic

 */
-- ALTER PROCEDURE [dbo].[A_002B_REMOVE_ANY_DUPLICATES]
CREATE PROCEDURE [dbo].[A_002B_REMOVE_DUPLICATES]
	@tbl nvarchar(MAX)
AS
BEGIN
		/* Initiate the log */  
		--Create database log table if it does not exist
		IF OBJECT_ID('LOG_SCRIPT_RUN_LOG', 'U') IS NULL 
		BEGIN CREATE TABLE [DBO].[LOG_SCRIPT_RUN_LOG] ([DATABASE] NVARCHAR(MAX) NULL,[OBJECT] NVARCHAR(MAX) NULL,[OBJECT_TYPE] NVARCHAR(MAX) NULL,[USER] NVARCHAR(MAX) NULL,[DATE] DATE NULL,[TIME] TIME NULL,[DESCRIPTION] NVARCHAR(MAX) NULL,[TABLE] NVARCHAR(MAX),[ROWS] INT) END

		--Log start of procedure
		INSERT INTO  [DBO].[LOG_SCRIPT_RUN_LOG] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
		SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Procedure started',NULL,NULL

		-- Step 1/ Declare variables that will be used below
		DECLARE @SQL NVARCHAR(MAX) =''
		DECLARE @SELECTSQL NVARCHAR(MAX) =''
		DECLARE @DELETESQL NVARCHAR(MAX) = ''
		DECLARE @KEY NVARCHAR(MAX) = ''
		DECLARE @KEY_BSEG NVARCHAR(MAX) = ''
		DECLARE @DELETEDROWS BIGINT
		DECLARE @DISTINCTSQL NVARCHAR(MAX) = ''
		DECLARE @TBL12 NVARCHAR(MAX) = 'A_' + @TBL
		DECLARE @TBL_NAME NVARCHAR(MAX)
		DECLARE @SQL_TBL_NAME NVARCHAR(MAX)
		SET @TBL_NAME = REPLACE(@tbl, '_INCREMENTAL_DATA', '')

		SELECT @KEY = DBO.GETTABLEKEY(@TBL_NAME)
		PRINT @KEY 

		IF LTRIM(RTRIM(@KEY)) = ''
		-- Step 2/ Obtain the key fields for the table from the DD03L



		-- Step 3/ If table could not be found in DD03L provide a message to the screen
		BEGIN
			PRINT 'Cannot find key for A_'+@TBL+'. Please check the completeness of your DD03L table.'
			RETURN
		END	


		-- Step 4/ Create a temporary table to hold duplicates results that will then be passed to the log

		IF OBJECT_ID('A002B_01_TT_DEDUPLOG','U') IS NULL BEGIN CREATE TABLE DBO.A002B_01_TT_DEDUPLOG (TBL NVARCHAR(MAX) NULL, RESULT NVARCHAR(MAX) NULL) END 

		-- Step 5/ Delete the table from the deduplicates log if it already exists 

		IF EXISTS(SELECT TBL FROM DBO.LOG_A002A_DUP_LOG WHERE TBL = @TBL12)
		BEGIN
			DELETE FROM dbo.LOG_A002A_DUP_LOG WHERE TBL = @TBL12
		END

		-- Step 6/ Add the table name and the number of rows to the duplicates log

		SELECT @SQL = 'WITH   DUPLICATES '+
				 ' AS ( SELECT COUNT(*) AS NR
					   FROM     '+@TBL12+'
					 )
		INSERT INTO LOG_A002A_DUP_LOG (TBL,TOTALROWS)
		SELECT '+''''+@TBL12+''''+',NR FROM DUPLICATES'

		EXEC(@SQL)

		---- Step 7/ Delete information about duplicates on current table 

		--SELECT @SELECTSQL = 'WITH    duplicates '+
		--         ' AS ( SELECT '+@KEY+'
		--                      , ROW_NUMBER() OVER ( PARTITION BY '+@KEY+' ORDER BY '+ @KEY+' DESC) AS NR
		--               FROM     '+@TBL12+'
		--             )
		--SELECT  '+@key+',nr
		--    FROM    duplicates
		--    WHERE   NR > 1'


		SELECT @DELETESQL = 'WITH    duplicates '+
				 ' AS ( SELECT '+@KEY+'
							  , ROW_NUMBER() OVER ( PARTITION BY '+@KEY+' ORDER BY '+ @KEY+' DESC) AS NR
					   FROM     '+@TBL12+'
					 )
		DELETE
			FROM    duplicates
			WHERE   NR > 1'

		EXEC(@DELETESQL)

		-- Step 8/ Remember how many duplicates were deleted in the temporary table

		SET @DELETEDROWS = @@ROWCOUNT

		INSERT INTO A002B_01_TT_DEDUPLOG (TBL,RESULT) VALUES (@TBL12, 'Deleted '+CAST(@DELETEDROWS AS NVARCHAR(MAX))+' rows from table '+@TBL12)

		-- Step 9/ Add the information about the duplicates that were deleted to the deduplication log 

		--SELECT * FROM A002B_01_TT_DEDUPLOG

		UPDATE DBO.LOG_A002A_DUP_LOG SET DUPLICATEROWS = @DELETEDROWS WHERE TBL = @TBL12

		-- Step 10/ Add the number of distinct rows to the deduplication log 
		-- (The number of rows should not be distinct because the duplicates have been deleted)

		SELECT @DISTINCTSQL = 'WITH    DUPLICATES '+
				 ' AS ( SELECT COUNT(*) AS NR
					   FROM     '+@TBL12+'
					 )
		UPDATE  DBO.LOG_A002A_DUP_LOG SET DISTINCTROWS = (SELECT NR FROM DUPLICATES) WHERE TBL = '+''''+@TBL12+''''

		EXEC(@DISTINCTSQL)


		/* log end of procedure*/

		INSERT INTO [DBO].[LOG_SCRIPT_RUN_LOG] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
		SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL

END






GO
