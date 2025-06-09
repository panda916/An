USE [DIVA_SOLA_FY20Q4_INCREMENTAL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_SAP_REPORT_FIELD_TO_STANDARD] (@sap_table NVARCHAR(255))

AS

--STEP 1 FIRST LOOP TO RENAME 
DECLARE @field_from_sap NVARCHAR(255), @field_required NVARCHAR(255),
			@field_format NVARCHAR(255), @OUTPUTMSG NVARCHAR(255), @SQLCMD NVARCHAR(MAX),
			@sql_format_code NVARCHAR(255), @new_field_name NVARCHAR(255)

DECLARE CURSOR_SAP_FIELD CURSOR FOR SELECT DISTINCT FIELD_REQUIRED_IN_SQL, FIELD_FROM_SAP_REPORT, FIELD_FORMAT

										FROM AM_DV_FIELD_MAPPING WHERE REPORT  = @sap_table


	OPEN CURSOR_SAP_FIELD
	FETCH NEXT FROM CURSOR_SAP_FIELD INTO @field_required, @field_from_sap, @field_format

SET @OUTPUTMSG = 'START RENAME FROM MAPPING FILE'
RAISERROR (@OUTPUTMSG, 0, 1) WITH NOWAIT
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @OUTPUTMSG = 'WORKING ON ' + @field_from_sap
		RAISERROR (@OUTPUTMSG, 0, 1) WITH NOWAIT
		BEGIN TRY

			SET @SQLCMD = '[' + @sap_table + '].' + @field_from_sap
			EXEC sp_rename @SQLCMD, @field_required, 'COLUMN'

			SET @OUTPUTMSG = '		RENAME FIELD ' + @field_from_sap + ''
			RAISERROR (@OUTPUTMSG, 0, 1) WITH NOWAIT

		END TRY
		BEGIN CATCH
			RAISERROR ('		ALREADY RENAMED', 0, 1) WITH NOWAIT
		END CATCH
		SET @OUTPUTMSG = 'FINISHED ' + @field_from_sap
		RAISERROR (@OUTPUTMSG, 0, 1) WITH NOWAIT
		RAISERROR ('', 0, 1) WITH NOWAIT
		FETCH NEXT FROM CURSOR_SAP_FIELD INTO @field_required, @field_from_sap, @field_format
	END
	CLOSE CURSOR_SAP_FIELD;
	DEALLOCATE CURSOR_SAP_FIELD
SET @new_field_name = ''

--Step 2
--Second looping for the Date format


DECLARE @date_field_from_sap NVARCHAR(255), @date_field_required NVARCHAR(255)
			
DECLARE CURSOR_DATE_SAP_FIELD CURSOR FOR
 
SELECT DISTINCT 
FIELD_REQUIRED_IN_SQL, FIELD_FROM_SAP_REPORT, FIELD_FORMAT
FROM AM_DV_FIELD_MAPPING WHERE REPORT  = @sap_table AND CHARINDEX('YYYY',FIELD_FORMAT,1) > 0



OPEN CURSOR_DATE_SAP_FIELD

FETCH NEXT FROM CURSOR_DATE_SAP_FIELD INTO @date_field_required, @date_field_from_sap, @field_format

SET @OUTPUTMSG = 'START CONVERT DATE USING FORMAT FROM MAPPING FILE'
RAISERROR (@OUTPUTMSG, 0, 1) WITH NOWAIT
	
WHILE @@FETCH_STATUS = 0
	BEGIN
	
	SET @OUTPUTMSG = 'WORKING ON ' + @date_field_from_sap
	RAISERROR (@OUTPUTMSG, 0, 1) WITH NOWAIT
	BEGIN TRY
			
		PRINT 	@date_field_required + ' ' +  @date_field_from_sap + '  '+ @sap_table
		SET @new_field_name = @date_field_required + '_CONVERTED'

		SET @SQLCMD = 'ALTER TABLE [' + @sap_table + '] ADD ' + @new_field_name + ' DATETIME'
		
		EXEC SP_EXECUTESQL @SQLCMD

		SET @SQLCMD = 'UPDATE [' + @sap_table + '] SET ' + @new_field_name + ' = dbo.DV_FORMAT_DATE(''' + @sap_table + ''','  +''''+  @date_field_from_sap  + ''',[' + @date_field_required + '])'
	
		PRINT @SQLCMD
		EXEC SP_EXECUTESQL @SQLCMD
		PRINT @SQLCMD
		
	END TRY

	BEGIN CATCH

		RAISERROR ('		ALREADY CONVERTED', 0, 1) WITH NOWAIT
	END CATCH
		
	SET @OUTPUTMSG = 'FINISHED ' + @date_field_from_sap + ' INTO ' + @new_field_name
	RAISERROR (@OUTPUTMSG, 0, 1) WITH NOWAIT
	RAISERROR ('', 0, 1) WITH NOWAIT

	
		
	FETCH NEXT FROM CURSOR_DATE_SAP_FIELD INTO @date_field_required, @date_field_from_sap, @field_format
END 	
		
CLOSE CURSOR_DATE_SAP_FIELD;
DEALLOCATE CURSOR_DATE_SAP_FIELD

SET @new_field_name = ''

--STEP 3 THIRD LOOPING for number format

DECLARE @number_field_from_sap NVARCHAR(255), @number_field_required NVARCHAR(255)
		
DECLARE CURSOR_NUMBER_SAP_FIELD CURSOR FOR 
SELECT DISTINCT FIELD_REQUIRED_IN_SQL, FIELD_FROM_SAP_REPORT, FIELD_FORMAT
FROM AM_DV_FIELD_MAPPING WHERE REPORT  = @sap_table AND (CHARINDEX(',',LEFT(FIELD_FORMAT,1),1) > 0 or CHARINDEX('.',LEFT(FIELD_FORMAT,1),1) >0)


OPEN CURSOR_NUMBER_SAP_FIELD

FETCH NEXT FROM CURSOR_NUMBER_SAP_FIELD INTO @number_field_required, @number_field_from_sap, @field_format

SET @OUTPUTMSG = 'START CONVERT NUMBER USING FORMAT  FROM MAPPING FILE'
RAISERROR (@OUTPUTMSG, 0, 1) WITH NOWAIT
	
WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @OUTPUTMSG = 'WORKING ON ' + @number_field_from_sap
		RAISERROR (@OUTPUTMSG, 0, 1) WITH NOWAIT
		BEGIN TRY

			print @number_field_required
			SET @new_field_name = @number_field_required + '_CONVERTED'
		
			SET @SQLCMD = 'ALTER TABLE [' + @sap_table + '] ADD ' + @new_field_name + ' MONEY'
			PRINT @SQLCMD
			EXEC SP_EXECUTESQL @SQLCMD
																					--dbo.DV_FORMAT_DATE(''' + @sap_table + ''','  +''''+  @date_field_from_sap  + ''',[' + @date_field_required + '])'	
			SET @SQLCMD = 'UPDATE [' + @sap_table + '] SET ' + @new_field_name + ' = dbo.STRING_TO_NUMBER(' + @number_field_required + ')'
			PRINT @SQLCMD
			EXEC SP_EXECUTESQL @SQLCMD


		END TRY

		BEGIN CATCH
			
			RAISERROR ('		ALREADY CONVERTED', 0, 1) WITH NOWAIT

		END CATCH
	
		SET @OUTPUTMSG = '		REFORMATED NUMBERIC FIELD ' + @number_field_from_sap + ' INTO ' + @new_field_name
		
		RAISERROR (@OUTPUTMSG, 0, 1) WITH NOWAIT
		RAISERROR ('', 0, 1) WITH NOWAIT

		
	FETCH NEXT FROM CURSOR_NUMBER_SAP_FIELD INTO @number_field_required, @number_field_from_sap, @field_format

	END 	
		
CLOSE CURSOR_NUMBER_SAP_FIELD;
DEALLOCATE CURSOR_NUMBER_SAP_FIELD



GO
