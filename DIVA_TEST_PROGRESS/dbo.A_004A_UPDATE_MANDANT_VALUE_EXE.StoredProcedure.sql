USE [DIVA_TEST_PROGRESS]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[A_004A_UPDATE_MANDANT_VALUE_EXE] (@FindMandantValue nvarchar(3) = '' , @ReplaceWithMandantValue nvarchar(3) = NULL)
  WITH EXEC AS CALLER
  AS

/* Initialize parameters from globals table */

     DECLARE 	 
			 @CURRENCY NVARCHAR(MAX)			= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'currency')
			,@DATE1 NVARCHAR(MAX)				= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date1')
			,@DATE2 NVARCHAR(MAX)				= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date2')
			,@DOWNLOADDATE NVARCHAR(MAX)		= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'downloaddate')
			,@DATEFORMAT VARCHAR(3)             = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'dateformat')
			,@EXCHANGERATETYPE NVARCHAR(MAX)	= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'exchangeratetype')
			,@LANGUAGE1 NVARCHAR(MAX)			= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language1')
			,@LANGUAGE2 NVARCHAR(MAX)			= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language2')
			,@YEAR NVARCHAR(MAX)				= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'year')
			,@ID NVARCHAR(MAX)					= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'id')
			,@LIMIT_RECORDS INT		            = CAST((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS') AS INT)


/*Test mode*/

SET ROWCOUNT @LIMIT_RECORDS

  /*
  Title: A_004A_UPDATE_MANDANT_VALUE
  Description: Add mandant field and update mandant values

  Why needed: When running analyses built for multiple mandants (should be all) all
  tables should have a mandant field in place.
  Procedure:
    - Runs through tables that don't start with a '_'
    - Determines the expected mandant field name (MANDT, MANDANT, CLIENT or RCLNT)
    - Adds the mandant field to the table if it doesn't exist and fills it with @ReplaceWithMandantValue
    - If the parameter @FindMandantValue is set (not empty) it sets the mandant value 
	  to '@ReplaceWithMandantValue' when the current mandant value is '@FindMandantValue' or NULL.

  Please note: Also tables that do not have a mandant field in SAP get one. This is
  needed for a multi-system analysis.
  --------------------------------------------------------------
  Update history
  --------------------------------------------------------------
  Date		|	Author	|	Description
  2016-04-19	MW			First version for Sony */



/* Initiate the log */  
--Create database log table if it does not exist
IF OBJECT_ID('LOG_SP_EXECUTION', 'U') IS NULL BEGIN CREATE TABLE [DBO].[LOG_SP_EXECUTION] ([DATABASE] NVARCHAR(MAX) NULL,[OBJECT] NVARCHAR(MAX) NULL,[OBJECT_TYPE] NVARCHAR(MAX) NULL,[USER] NVARCHAR(MAX) NULL,[DATE] DATE NULL,[TIME] TIME NULL,[DESCRIPTION] NVARCHAR(MAX) NULL,[TABLE] NVARCHAR(MAX),[ROWS] INT) END

--Log start of procedure
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Procedure started',NULL,NULL


-- Step 1/ For each mandant field in each table, ensure that it is as expected


  DECLARE @TableName varchar(255), @MandantFieldName varchar(16)

  SET NOCOUNT ON

  DECLARE c CURSOR FOR
      SELECT so.name
      FROM sys.objects so	
      WHERE so.name NOT LIKE '[_]%' AND so.name NOT LIKE 'LOG_%' AND so.type = 'U' and so.name LIKE 'A[_]%'
      ORDER BY so.name
    OPEN c
    FETCH NEXT FROM c INTO @TableName

	PRINT 'Check the list below for errors in red.' 
	PRINT ' '

    WHILE @@Fetch_Status = 0
    BEGIN
      -- Determine the expected mandant field name
      IF @TableName IN ('A_CDHDR', 'A_CDPOS', 'A_QPGT')
        SET @MandantFieldName = RIGHT(@TableName, len(@TAbleNAme) -2) + '_' + 'MANDANT'
      
      ELSE IF @TableName IN ('A_ADCP', 'A_ADRC', 'A_ADRP')
        SET @MandantFieldName = RIGHT(@TableName, len(@TAbleNAme) -2) + '_' + 'CLIENT'
      
      ELSE IF @TableName IN ('A_GLT0', 'A_FAGLFLEXA', 'A_FAGLFLEXT')
        SET @MandantFieldName = RIGHT(@TableName, len(@TAbleNAme) -2) + '_'  + 'RCLNT'
      
      ELSE SET @MandantFieldName = RIGHT(@TableName, len(@TableName) -2) + '_' + 'MANDT'
      print 'mandant found :  ' + @MandantFieldName
      
      BEGIN TRANSACTION
		
		  IF NOT EXISTS(select * from sys.columns where Name = @MandantFieldName 
				  and Object_ID = Object_ID(@TableName))       -- Add the mandant field if it doesn't exist
		  BEGIN
			EXEC('ALTER TABLE dbo.[' + @TableName + '] ADD [' + @MandantFieldName + '] NVARCHAR(3) NULL ')
			EXEC('UPDATE dbo.[' + @TableName + '] SET [' + @MandantFieldName + '] = ''' + @ReplaceWithMandantValue + ''' ')
			PRINT @TableName + '  - Added mandant field ' + @MandantFieldName + ' and filled it with: ' + @ReplaceWithMandantValue
		  END
		  
		  ELSE IF ISNULL(@FindMandantValue,'') <> '' OR @FindMandantValue = '' -- Update values when @FindMandantValue is empty
		  BEGIN
		  -- Sets the mandant value to '@ReplaceWithMandantValue' when the current 
			  -- mandant value is '@FindMandantValue' or NULL
			EXEC('UPDATE dbo.[' + @TableName + '] SET [' + @MandantFieldName + '] = ''' + @ReplaceWithMandantValue + ''' WHERE [' + @MandantFieldName + '] = ''' + @FindMandantValue + ''' OR [' + @MandantFieldName + '] IS NULL ')
			PRINT @TableName + '  - Changed ' + @MandantFieldName + ' value ' + @FindMandantValue + ' to ' + @ReplaceWithMandantValue
		  END      
		  ELSE    -- Skip the table
		  BEGIN
			PRINT @TableName + '  - Skipped because mandant field ' + @MandantFieldName + ' already existed and parameter @FindMandantValue is empty'
		  END
	  	  
      COMMIT TRANSACTION
    FETCH NEXT FROM c INTO @TableName
    END
      CLOSE c
  DEALLOCATE c


/* log end of procedure*/


INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL




GO
