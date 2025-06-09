USE [DIVA_ASAP_TEST_DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE     PROCEDURE [dbo].[A_004E_UPDATE_DATE_EMPTY_ASAP] 
  WITH EXECUTE AS CALLER
  AS
  BEGIN

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
  Title: Update date fields
  Objective: update '1900-01-01' date fields to NULL
  --------------------------------------------------------------
  Update history
  --------------------------------------------------------------
  Date     | Author | Description
  19-04-2016  MW	  First version for Sony

  */

 /* Initiate the log */  
--Create database log table if it does not exist
IF OBJECT_ID('LOG_SP_EXECUTION', 'U') IS NULL BEGIN CREATE TABLE [DBO].[LOG_SP_EXECUTION] ([DATABASE] NVARCHAR(MAX) NULL,[OBJECT] NVARCHAR(MAX) NULL,[OBJECT_TYPE] NVARCHAR(MAX) NULL,[USER] NVARCHAR(MAX) NULL,[DATE] DATE NULL,[TIME] TIME NULL,[DESCRIPTION] NVARCHAR(MAX) NULL,[TABLE] NVARCHAR(MAX),[ROWS] INT) END

--Log start of procedure
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Procedure started',NULL,NULL


-- Step 1/ Create variables 

  DECLARE @TableName varchar(255)
  DECLARE @FieldName varchar(255)
  DECLARE @UpdateStatement varchar(max)
  DECLARE @UpdateStatement_type varchar(max)
  DECLARE @ErrorCounter int
  DECLARE @UpdateCounter int

  SET NOCOUNT ON
  
  SET @ErrorCounter = 0
  SET @UpdateCounter = 0 


-- Step 2/ For each table update the date format

  DECLARE c CURSOR FOR
		 select sys.objects.name as SAP_Table, sys.columns.name as SAP_Field from sys.objects
		LEFT JOIN sys.columns on sys.columns.object_id = sys.objects.object_id
		left join INFORMATION_SCHEMA.COLUMNS ISC ON
		ISC.TABLE_NAME = sys.objects.name AND ISC.COLUMN_NAME = sys.columns.name
		INNER JOIN A_DD03L as ECC ON
		RIGHT(sys.objects.name, len(sys.objects.name)-2) COLLATE Latin1_General_CI_AS = RTRIM(ECC.TABNAME) 
		AND sys.columns.name COLLATE Latin1_General_CI_AS = RTRIM(ECC.TABNAME) + '_' + RTRIM(ECC.FIELDNAME)
		WHERE sys.objects.type = 'U' AND ECC.INTTYPE in ('D')

		order by sys.objects.name, sys.columns.column_id
    OPEN c
    FETCH NEXT FROM c INTO @TableName, @FieldName

    WHILE @@Fetch_Status = 0
    BEGIN
        
        BEGIN TRY
          
		  PRINT '------------------- Step 1 -- Convert 00000000 to NULL value --------------------------------'

			SET @UpdateStatement = 
			'UPDATE [' + @TableName + '] 
				SET [' + @FieldName + '] = NULL 
				WHERE [' + @FieldName + '] = ''00000000'''

             EXEC(@UpdateStatement)
          PRINT 'Updated table/field done ' + @TableName + '-' + @FieldName
		  PRINT '------------------- Step 2 -- Convert the date type to date--------------------------------'

			 SET @UpdateStatement_type = 
				'
				ALTER TABLE [' + @TableName + '] 
				ALTER COLUMN [' + @FieldName + '] DATE'
             EXEC(@UpdateStatement_type)

          SET @UpdateCounter = @UpdateCounter + 1
          
        END TRY
      
        BEGIN CATCH
        
          PRINT '! Error for table/field ' + @TableName + '-' + @FieldName + '!'
          SET @ErrorCounter = @ErrorCounter + 1
          FETCH NEXT FROM c INTO @TableName, @FieldName
        
        
        END CATCH
      
    FETCH NEXT FROM c INTO @TableName, @FieldName
    END
      CLOSE c
  DEALLOCATE c 

  IF @ErrorCounter = 0  
	BEGIN
		PRINT 'Succesfully updated ' + convert(varchar, @UpdateCounter) + ' date fields 0000000 to null and update datatype'
    END
  ELSE
	BEGIN
		PRINT 'Errors occured while updating date fields L'
		PRINT 'While ' + convert(varchar, @UpdateCounter) + ' date fields were updated succesfully, ' + convert(varchar, @ErrorCounter) + ' errors occured'

	END

/* log end of procedure*/

INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL
	
  END









GO
