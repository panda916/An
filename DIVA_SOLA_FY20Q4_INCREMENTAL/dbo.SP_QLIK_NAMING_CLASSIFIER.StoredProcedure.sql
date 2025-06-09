USE [DIVA_SOLA_FY20Q4_INCREMENTAL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_QLIK_NAMING_CLASSIFIER]
AS

/*Change history comments*/

/*
    Title			:	Qlik naming classifier
	Important note: For any additional tables that are added from QLIK, the below
	script should be updated wherever the word 'Template' is found and 
	according to the example given.
      
    --------------------------------------------------------------
    Update history
    --------------------------------------------------------------
    Date		    | Who |	Description
	01/06/2017		  HT	First creation
	01/10/2017		  CW    Review and standardization
	08/12/2017		  CW    Review and standardization
	02/01/2018        CW    Remove renaming of SAP reports
	                        Include possibility to automatically import all AM tables  
	08/01/2018        CW    Add concatenation to enable import of multiple DIVA tables
	                  CW    Only keep the latest version of the filter
					  CW    Don't rename the fields for DV12
*/




--Step 1/ Creation of variables for running of the programme

--1.1 Variables required for running the SQL command
DECLARE @SQLCMD NVARCHAR(MAX), @MSG NVARCHAR(MAX)

--1.2 Variables required for the cursor to loop through each table and field
DECLARE @TABLE_NAME VARCHAR(100), @TABLE_NAMEo VARCHAR(100), @TABLE_ID INT, @TABLE_FIELD VARCHAR(50)

--1.3 Variable to know if we want to concatenate two tables together
DECLARE @SQL NVARCHAR(MAX)=N''
DECLARE @vCOUNTER_QLIKFILTER INT = 1
DECLARE @vCOUNTER_RTRTB_PIV1 INT = 1
DECLARE @vCOUNTER_RTRGL_DET INT = 1
DECLARE @vCOUNTER_PTP_SO INT = 1

--Step 2/ Create a log table that is to be used to provide a feedback message
--        to the user of the Java application
--        The table has three columns: old_name, new_name, and _log
--        Only the column _log is used to give the feedback message for running of DVXX scripts
--        Columns old_name and new_name are used to indicate the name modifications done by this stored procedure
--        when it renames the tables obtained from Qlik in order to recognize them for input into Qlik 
--        data validation dashboard

EXEC SP_DROPTABLE 'DV00_RT_USER_FEEDBACK_MESSAGE'
CREATE TABLE DV00_RT_USER_FEEDBACK_MESSAGE          
     (OLD_NAME NVARCHAR(MAX), NEW_NAME NVARCHAR(MAX), _LOG NVARCHAR(MAX))


-- Step 3/ Loop through all user created tables that start with the prefix AQLIK_

-- 3.1 Preparation of the loop through all user created tables that start with the prefix AQLIK_ or ASAP

DECLARE CUR_SYS_TABLES CURSOR FOR SELECT DISTINCT NAME, OBJECT_ID FROM SYS.ALL_OBJECTS
	WHERE TYPE_DESC = 'USER_TABLE'
	AND (LEFT(NAME, 6) = 'AQLIK_' OR LEFT(NAME, 4) = 'ASAP')
OPEN CUR_SYS_TABLES
FETCH NEXT FROM CUR_SYS_TABLES INTO @TABLE_NAME, @TABLE_ID

-- 3.2 Start of the loop

WHILE @@FETCH_STATUS = 0
BEGIN

-- 3.3 Create variables for the recognition of the filters table

	DECLARE @HASQLIK_DASHBOARD NVARCHAR(1) = 'N', @HASQLIK_FILTER NVARCHAR(1) = 'N', @HASSELECTED_FIELD NVARCHAR(1) = 'N'

 -- 3.4 For each table that is brought in from Qlik (other than filters), create varibales for 
 --     each column in that table
	
-- Template 

--	3.4.x DECLARE @HAS<DASHBOARDREF><OBJECTTYPE><OBJECTNUMBER><FIELDNAME1> NVARCHAR(1) = 'N', @HAS<DASHBOARDREF><OBJECTTYPE><OBJECTNUMBER><FIELDNAME2> NVARCHAR(1) = 'N', @HAS<DASHBOARDREF><OBJECTTYPE><OBJECTNUMBER><FIELDNAME3> NVARCHAR(1) = 'N',
--		@HAS<DASHBOARDREF><OBJECTTYPE><OBJECTNUMBER><FIELDNAME4> NVARCHAR(1) = 'N', @HAS<DASHBOARDREF><OBJECTTYPE><OBJECTNUMBER><FIELDNAME6> NVARCHAR(1) = 'N', @HAS<DASHBOARDREF><OBJECTTYPE><OBJECTNUMBER><FIELDNAME6> NVARCHAR(1) = 'N'


-- 3.4.1 DV01: For RTR Trial Balance, Pivot table 1: (RTRTB_PIV1_)
	DECLARE @HASRTRTB_PIV1_GL NVARCHAR(1) = 'N', @HASRTRTB_PIV1_OPENING NVARCHAR(1) = 'N', @HASRTRTB_PIV1_DEBIT NVARCHAR(1) = 'N',
		@HASRTRTB_PIV1_CREDIT NVARCHAR(1) = 'N', @HASRTRTB_PIV1_BAL NVARCHAR(1) = 'N', @HASRTRTB_PIV1_TB NVARCHAR(1) = 'N'
-- 3.4.2 DV11: For RTR GL Detail
	DECLARE @HASRTRGL_BA NVARCHAR(1) = 'N', @HASRTRGL_DOC_TYPE NVARCHAR(1) = 'N', @HASRTRGL_GL NVARCHAR(1) = 'N', @HASRTRGL_DOC_NUM NVARCHAR(1) = 'N', @HASRTRGL_VAL NVARCHAR(1) = 'N'
-- 3.4.3 DV12: For PTP spend overview details:
	DECLARE @HASPTPSO_GL_ACC NVARCHAR(1) = 'N', @HASPTPSO_ACC_TYP NVARCHAR(1) = 'N',
	@HASPTPSO_DOC_NR NVARCHAR(1) = 'N', @HASPTPSO_DOC_TYP NVARCHAR(1) = 'N', @HASPTPSO_POSTING_DATE NVARCHAR(1) = 'N',@HASPTPSO_VENDOR_ACC NVARCHAR(1) = 'N'
-- 3.4.4 DV13: AR overview details:
	DECLARE @HASAR_DOC_TYPE_BUCKET NVARCHAR(1) = 'N'
-- 3.4.5 DV14: COPA transaction details:
	DECLARE @HASCOPA_DOC_NR NVARCHAR(1) = 'N'

-- 3.5 Preparation of the loop, to loop through each field of the current table

	DECLARE CUR_SYS_FIELDS CURSOR FOR SELECT LOWER(NAME) AS NAME FROM SYS.ALL_COLUMNS
			WHERE OBJECT_ID = @TABLE_ID
	OPEN CUR_SYS_FIELDS
	FETCH NEXT FROM CUR_SYS_FIELDS INTO @TABLE_FIELD

-- 3.6 Start of the loop for the fields 
	WHILE @@FETCH_STATUS = 0
	BEGIN


-- 3.7 Recognition of the fields for the filters table

		IF (CHARINDEX('qlik_application', @TABLE_FIELD) > 0) SET @HASQLIK_DASHBOARD = 'Y'
		IF (CHARINDEX('qlik_application_filter', @TABLE_FIELD) > 0) SET @HASQLIK_FILTER = 'Y'
		IF (CHARINDEX('qlik_application_filter_value', @TABLE_FIELD) > 0) SET @HASSELECTED_FIELD = 'Y'


-- 3.8 For each field, check if it has the field name that is found in a particular Qlik report 

-- Template 

-- 		IF (CHARINDEX('XXXX', @TABLE_FIELD) > 0) SET @HAS<DashboardRef><ObjectType><ObjectNumber><FieldName1> = 'Y'
-- 		IF (CHARINDEX('XXXX', @TABLE_FIELD) > 0) SET @HAS<DashboardRef><ObjectType><ObjectNumber><FieldName2> = 'Y'
-- 		IF (CHARINDEX('XXXX', @TABLE_FIELD) > 0) SET @HAS<DashboardRef><ObjectType><ObjectNumber><FieldName3> = 'Y'
-- 		IF (CHARINDEX('XXXX', @TABLE_FIELD) > 0) SET @HAS<DashboardRef><ObjectType><ObjectNumber><FieldName4> = 'Y'
-- 		IF (CHARINDEX('XXXX', @TABLE_FIELD) > 0) SET @HAS<DashboardRef><ObjectType><ObjectNumber><FieldName5> = 'Y'


-- 3.8.1 DV01:  For RTR Trial Balance, Pivot table 1: (RTRTB_PIV1_)
		
		IF (CHARINDEX('G/L account', @TABLE_FIELD) > 0) SET @HASRTRTB_PIV1_GL = 'Y'
		IF (CHARINDEX('opening', @TABLE_FIELD) > 0) SET @HASRTRTB_PIV1_OPENING = 'Y'
		IF (CHARINDEX('tb debit', @TABLE_FIELD) > 0) SET @HASRTRTB_PIV1_DEBIT = 'Y'
		IF (CHARINDEX('tb credit', @TABLE_FIELD) > 0) SET @HASRTRTB_PIV1_CREDIT = 'Y'
		IF (CHARINDEX('bal', @TABLE_FIELD) > 0) SET @HASRTRTB_PIV1_BAL = 'Y'

-- 3.8.3 DV11: For RTR GL Detail		
		IF (CHARINDEX('Business area', @TABLE_FIELD) > 0) SET @HASRTRGL_BA			='Y'
		IF (CHARINDEX('Document Type', @TABLE_FIELD) > 0) SET @HASRTRGL_DOC_TYPE	='Y'
		IF (CHARINDEX('GL account', @TABLE_FIELD) > 0) SET @HASRTRGL_GL				='Y'
		IF (CHARINDEX('Document nr', @TABLE_FIELD) > 0) SET @HASRTRGL_DOC_NUM       ='Y'
		IF (CHARINDEX('Value COC', @TABLE_FIELD) > 0) SET @HASRTRGL_VAL				='Y'

-- 3.8.2 DV12: For PTP spend overview 
-- To be created based on above template
		print(@table_field)
		IF (CHARINDEX('supplier nr', @TABLE_FIELD) > 0) SET @HASPTPSO_VENDOR_ACC = 'Y'
		print(@HASPTPSO_VENDOR_ACC)
		IF (CHARINDEX('gl account', @TABLE_FIELD) > 0) SET @HASPTPSO_GL_ACC = 'Y'
		print(@HASPTPSO_GL_ACC)
		--IF (CHARINDEX('Totals', @TABLE_FIELD) > 0) SET @HASPTPSO_TOTALS = 'Y'
		IF (CHARINDEX('account type', @TABLE_FIELD) > 0) SET @HASPTPSO_ACC_TYP = 'Y'
		
		IF (CHARINDEX('document type', @TABLE_FIELD) > 0) SET @HASPTPSO_DOC_TYP = 'Y'
		IF (CHARINDEX('posting date', @TABLE_FIELD) > 0) SET @HASPTPSO_POSTING_DATE	 = 'Y'
		--IF (CHARINDEX('Invoice nr', @TABLE_FIELD) > 0) SET @HASINVOICE_NR = 'Y'
	
-- 3.8.4 DV13: For AR  overview 
-- To be created based on above template
		print(@table_field)
		--
		IF (CHARINDEX('AR document type bucket', @TABLE_FIELD) > 0) SET @HASAR_DOC_TYPE_BUCKET	 = 'Y'
		--IF (CHARINDEX('Invoice nr', @TABLE_FIELD) > 0) SET @HASINVOICE_NR = 'Y'

-- 3.8.5 DV14: For COPA transaction details
-- To be created based on above template
		print(@table_field)
		--
		IF (CHARINDEX('COPA doc nr', @TABLE_FIELD) > 0) SET @HASCOPA_DOC_NR	 = 'Y'
		--IF (CHARINDEX('Invoice nr', @TABLE_FIELD) > 0) SET @HASINVOICE_NR = 'Y'


-- 3.9 End of the loop for the fields 


		FETCH NEXT FROM CUR_SYS_FIELDS INTO @TABLE_FIELD
	END
	CLOSE CUR_SYS_FIELDS
	DEALLOCATE CUR_SYS_FIELDS


-- 3.10 Message concerning the running of the script

	RAISERROR(@TABLE_NAME, 10, -1) WITH NOWAIT

-- 3.11 Renaming of the filter table if all fields were found for the filter table

-- 3.11.1 If this is the first time that we make the filter

	IF (@TABLE_NAME <> 'AQLIK_FILTER' AND @HASQLIK_DASHBOARD = 'Y' AND @HASQLIK_FILTER = 'Y' AND @HASSELECTED_FIELD = 'Y') AND @vCOUNTER_QLIKFILTER = 1
	BEGIN
	    --SET @vCOUNTER_QLIKFILTER = @vCOUNTER_QLIKFILTER+1
		SET @TABLE_NAME = '[DBO].[' + @TABLE_NAME + ']'
		BEGIN TRY

			EXEC SP_DROPTABLE 'AQLIK_FILTER' --drop the existing table with replaced name to avoid conflicts
			--EXEC SP_RENAME @TABLE_NAME, 'AQLIK_FILTER'; --rename the table
			SET @MSG = 'Renamed ' + left(@TABLE_NAME,len(@TABLE_NAME)-5) +'...'+ ' into ' + 'AQLIK_FILTER' --print back status for users
			EXEC SP_APPEND_TABLES 'qlik_selected_filter','AQLIK_FILTER'
			  
			EXEC SP_REMOVE_TABLES '%qlik_selected_filter%'

			INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, 'AQLIK_FILTER', @MSG)
			RAISERROR(@MSG, 10, -1) WITH NOWAIT
		END TRY
		BEGIN CATCH
			RAISERROR('error with renaming', 10, -1) WITH NOWAIT
		END CATCH
	END
	ELSE IF (LEFT(@TABLE_NAME,5) = 'ASAP_')
	BEGIN
		EXEC SP_SAP_REPORT_FIELD_TO_STANDARD @TABLE_NAME
	
	END

 --3.11.2 If this is not the first time that we make the filter

	--IF (@TABLE_NAME <> 'AQLIK_FILTER' AND @HASQLIK_DASHBOARD = 'Y' AND @HASQLIK_FILTER = 'Y' AND @HASSELECTED_FIELD = 'Y') AND @vCOUNTER_QLIKFILTER > 1
	--BEGIN
	--	SET @TABLE_NAME = '[DBO].[' + @TABLE_NAME + ']'
	--	BEGIN TRY

	--		SET @SQL='SELECT *
	--		INTO AQLIK_FILTER2
	--		FROM 
	--		(SELECT * FROM '+ @TABLE_NAME  + '
	--		UNION ALL 
	--		SELECT *
	--		FROM AQLIK_FILTER) TMP'
	--		EXEC sp_executesql @SQL
	--		EXEC SP_DROPTABLE 'AQLIK_FILTER'
	--		EXEC SP_RENAME AQLIK_FILTER2, 'AQLIK_FILTER'
		
	--		SET @MSG = 'Concatenated ' + @TABLE_NAME + ' into ' + 'AQLIK_FILTER' --print back status for users
	--		INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, 'AQLIK_FILTER', @MSG)
	--		RAISERROR(@MSG, 10, -1) WITH NOWAIT  --Message concerning the running of the script 

	--        EXEC SP_RENAME @TABLE_NAME, 'TABLETODROP'
	--		EXEC SP_DROPTABLE 'TABLETODROP'

	--	END TRY
	--	BEGIN CATCH
	--		RAISERROR('error with renaming', 10, -1) WITH NOWAIT
	--	END CATCH
	--END
	--ELSE IF (LEFT(@TABLE_NAME,5) = 'ASAP_')
	--BEGIN
	--	EXEC SP_SAP_REPORT_FIELD_TO_STANDARD @TABLE_NAME
	--END
-- 3.12 Renaming of the Qlik tables if all fields were found for that Qlik table 

-- Template:

-- 3.12.1 If this is the first time in the loop that we are making <AQLIK>_<DashboardRef><ObjectType><ObjectNumber>

-- 	IF (@TABLE_NAME <> '<AQLIK>_<DashboardRef><ObjectType><ObjectNumber>' AND @HAS<DashboardRef><ObjectType><ObjectNumber> = 'Y' AND @HAS<DashboardRef><ObjectType><ObjectNumber> = 'Y' AND @HAS<DashboardRef><ObjectType><ObjectNumber> = 'Y' AND @HAS<DashboardRef><ObjectType><ObjectNumber> = 'Y' AND @HAS<DashboardRef><ObjectType><ObjectNumber> = 'Y' AND @HAS<DashboardRef><ObjectType><ObjectNumber> = 'Y') AND @<CounterVariable> = 1
--	BEGIN
--          SET @<CounterVariable> = @<CounterVariable>+1
--			SET @TABLE_NAME = '[DBO].[' + @TABLE_NAME + ']'
--			BEGIN TRY
--				EXEC SP_DROPTABLE '<AQLIK>_<DashboardRef><ObjectType><ObjectNumber>' --drop the existing table with replaced name to avoid conflicts
--				EXEC SP_RENAME @TABLE_NAME, '<AQLIK>_<DashboardRef><ObjectType><ObjectNumber>'; --rename the table
--				SET @MSG = 'Renamed ' + @TABLE_NAME + ' into ' + '<AQLIK>_<DashboardRef><ObjectType><ObjectNumber>' --print back status for users
--				INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, '<AQLIK>_<DashboardRef><ObjectType><ObjectNumber>', @MSG)
--				RAISERROR(@MSG, 10, -1) WITH NOWAIT
--			END TRY
--			BEGIN CATCH
--				RAISERROR('error with renaming', 10, -1) WITH NOWAIT
--			END CATCH
--	END

-- 3.12.2 If this is not the first time in the loop that we are making <AQLIK>_<DashboardRef><ObjectType><ObjectNumber>

-- 	IF (@TABLE_NAME <> '<AQLIK>_<DashboardRef><ObjectType><ObjectNumber>' AND @HAS<DashboardRef><ObjectType><ObjectNumber> = 'Y' AND @HAS<DashboardRef><ObjectType><ObjectNumber> = 'Y' AND @HAS<DashboardRef><ObjectType><ObjectNumber> = 'Y' AND @HAS<DashboardRef><ObjectType><ObjectNumber> = 'Y' AND @HAS<DashboardRef><ObjectType><ObjectNumber> = 'Y' AND @HAS<DashboardRef><ObjectType><ObjectNumber> = 'Y') AND @<CounterVariable> > 1
    -- BEGIN
    -- SET @TABLE_NAME = '[DBO].[' + @TABLE_NAME + ']'
	--	BEGIN TRY
			--SET @SQL='SELECT *
			--INTO <AQLIK>_<DashboardRef><ObjectType><ObjectNumber>2
			--FROM 
			--(SELECT * FROM '+ @TABLE_NAME  + '
			--UNION ALL 
			--SELECT *
			--FROM <AQLIK>_<DashboardRef><ObjectType><ObjectNumber>) TMP'
			--EXEC sp_executesql @SQL
			--EXEC SP_DROPTABLE '<AQLIK>_<DashboardRef><ObjectType><ObjectNumber>'
			--EXEC SP_RENAME <AQLIK>_<DashboardRef><ObjectType><ObjectNumber>2, '<AQLIK>_<DashboardRef><ObjectType><ObjectNumber>'
			
	--		SET @MSG = 'Concatenated ' + @TABLE_NAME + ' into ' + '<AQLIK>_<DashboardRef><ObjectType><ObjectNumber>' --print back status for users
	--		INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, '<AQLIK>_<DashboardRef><ObjectType><ObjectNumber>', @MSG)
	--		RAISERROR(@MSG, 10, -1) WITH NOWAIT  --Message concerning the running of the script 
	--     
	  --      EXEC SP_RENAME @TABLE_NAME, 'TABLETODROP'
			--EXEC SP_DROPTABLE 'TABLETODROP'    --
	--	END TRY
	--	BEGIN CATCH
	--		RAISERROR('error with renaming', 10, -1) WITH NOWAIT
	--	END CATCH
	--END

-- 3.12.1 DV01: Renaming of the table for RTRTB_PIV1

-- 3.12.1.1 If it is the first time that we are creating the table AQLIK_RTRTB_PIV1

	IF (@TABLE_NAME <> 'AQLIK_RTRTB_PIV1' AND @HASRTRTB_PIV1_GL = 'Y' AND @HASRTRTB_PIV1_OPENING = 'Y' AND @HASRTRTB_PIV1_DEBIT = 'Y' AND @HASRTRTB_PIV1_CREDIT = 'Y' AND @HASRTRTB_PIV1_BAL = 'Y') AND @vCOUNTER_RTRTB_PIV1 = 1
	BEGIN
		SET @TABLE_NAME = '[DBO].[' + @TABLE_NAME + ']'
		BEGIN TRY
			EXEC SP_DROPTABLE 'AQLIK_RTRTB_PIV1' --drop the existing table with replaced name to avoid conflicts
			EXEC SP_RENAME @TABLE_NAME, 'AQLIK_RTRTB_PIV1'; --rename the table
			SET @MSG = 'Renamed ' + @TABLE_NAME + ' as ' + 'AQLIK_RTRTB_PIV1' --print back status for users
			INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, 'AQLIK_RTRTB_PIV1', @MSG)
			RAISERROR(@MSG, 10, -1) WITH NOWAIT  --Message concerning the running of the script
			SET @vCOUNTER_RTRTB_PIV1 = @vCOUNTER_RTRTB_PIV1+1
		END TRY
		BEGIN CATCH
			RAISERROR('error with renaming', 10, -1) WITH NOWAIT
		END CATCH
	END

-- 3.12.1.2 If it is not first time that we are creating this table then we concatenate


	IF (@TABLE_NAME <> 'AQLIK_RTRTB_PIV1' AND @HASRTRTB_PIV1_GL = 'Y' AND @HASRTRTB_PIV1_OPENING = 'Y' AND @HASRTRTB_PIV1_DEBIT = 'Y' AND @HASRTRTB_PIV1_CREDIT = 'Y' AND @HASRTRTB_PIV1_BAL = 'Y' AND @HASRTRTB_PIV1_TB = 'Y') AND @vCOUNTER_RTRTB_PIV1 > 1
	BEGIN
		SET @TABLE_NAME = '[DBO].[' + @TABLE_NAME + ']'
		BEGIN TRY

			SET @SQL='SELECT *
			INTO AQLIK_RTRTB_PIV12
			FROM 
			(SELECT * FROM '+ @TABLE_NAME  + '
			UNION ALL 
			SELECT *
			FROM AQLIK_RTRTB_PIV1) TMP'
			EXEC sp_executesql @SQL
			EXEC SP_DROPTABLE 'AQLIK_RTRTB_PIV1'
			EXEC SP_RENAME AQLIK_RTRTB_PIV12, 'AQLIK_RTRTB_PIV1'

		
			SET @MSG = 'Concatenated ' + @TABLE_NAME + ' into ' + 'AQLIK_RTRTB_PIV1' --print back status for users
			INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, 'AQLIK_RTRTB_PIV1', @MSG)
			RAISERROR(@MSG, 10, -1) WITH NOWAIT  --Message concerning the running of the script 
	     
	        EXEC SP_RENAME @TABLE_NAME, 'TABLETODROP'
			EXEC SP_DROPTABLE 'TABLETODROP'
			SET @vCOUNTER_RTRTB_PIV1 = @vCOUNTER_RTRTB_PIV1+1
    
		END TRY
		BEGIN CATCH
			RAISERROR('error with renaming', 10, -1) WITH NOWAIT
		END CATCH
	END


-- 13.12.2: DV11: 	

-- 3.12.2.1  If this is the first time in the loop that we are making AQLIK_RTR_GL_DETAIL

	IF (@TABLE_NAME <> 'AQLIK_RTR_GL_DETAIL' AND @HASRTRGL_BA  = 'Y' AND @HASRTRGL_DOC_TYPE  = 'Y' AND @HASRTRGL_GL  = 'Y' AND @HASRTRGL_DOC_NUM  = 'Y' AND @HASRTRGL_VAL  = 'Y') AND @vCOUNTER_RTRGL_DET = 1
	BEGIN

		SET @TABLE_NAME = '[DBO].[' + @TABLE_NAME + ']'
		BEGIN TRY
			EXEC SP_DROPTABLE 'AQLIK_RTR_GL_DETAIL' --drop the existing table with replaced name to avoid conflicts
			EXEC SP_RENAME @TABLE_NAME, 'AQLIK_RTR_GL_DETAIL'; --rename the table
			SET @MSG = 'Renamed ' + @TABLE_NAME + ' as ' + 'AQLIK_RTR_GL_DETAIL' --print back status for users
			
			INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, 'AQLIK_RTR_GL_DETAIL', @MSG)
			RAISERROR(@MSG, 10, -1) WITH NOWAIT  --Message concerning the running of the script
			SET @vCOUNTER_RTRGL_DET = @vCOUNTER_RTRGL_DET+1
		END TRY
		BEGIN CATCH
			RAISERROR('error with renaming', 10, -1) WITH NOWAIT
		END CATCH
	END


-- 3.12.2 If this is not the first time in the loop that we are making AQLIK_RTR_GL_DETAIL

 	IF (@TABLE_NAME <> 'AQLIK_RTR_GL_DETAIL' AND @HASRTRGL_BA  = 'Y' AND @HASRTRGL_DOC_TYPE  = 'Y' AND @HASRTRGL_GL  = 'Y' AND @HASRTRGL_DOC_NUM  = 'Y' AND @HASRTRGL_VAL  = 'Y') AND @vCOUNTER_RTRGL_DET > 1
     BEGIN
		SET @TABLE_NAME = '[DBO].[' + @TABLE_NAME + ']'
		BEGIN TRY
			--SET @MSG = 'Start begin try second table'
			--INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, 'AQLIK_RTR_GL_DETAIL', @MSG)

			--SET @MSG = @TABLE_NAME
			--INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, 'AQLIK_RTR_GL_DETAIL', @MSG)

			SET @SQL='SELECT *
			INTO AQLIK_RTR_GL_DETAIL2
			FROM 
			(SELECT * FROM '+ @TABLE_NAME  + '
			UNION ALL 
			SELECT *
			FROM AQLIK_RTR_GL_DETAIL) TMP'
			EXEC sp_executesql @SQL
			EXEC SP_DROPTABLE 'AQLIK_RTR_GL_DETAIL'
			EXEC SP_RENAME AQLIK_RTR_GL_DETAIL2, 'AQLIK_RTR_GL_DETAIL'

			--SET @MSG = @SQL
			--INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, 'AQLIK_RTR_GL_DETAIL', @MSG)


			SET @MSG = 'Concatenated ' + @TABLE_NAME + ' into ' + 'AQLIK_RTR_GL_DETAIL' --print back status for users
			INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, 'AQLIK_RTR_GL_DETAIL', @MSG)
			
			RAISERROR(@MSG, 10, -1) WITH NOWAIT  --Message concerning the running of the script 
			--RAISERROR(@SQL, 10, -1) WITH NOWAIT  --Message concerning the running of the script 

	     
	        EXEC SP_RENAME @TABLE_NAME, 'TABLETODROP'
			EXEC SP_DROPTABLE 'TABLETODROP'
			SET @vCOUNTER_RTRGL_DET = @vCOUNTER_RTRGL_DET+1
		END TRY
		BEGIN CATCH
			RAISERROR('error with renaming', 10, -1) WITH NOWAIT
		END CATCH
	END

	

---- 3.12.3 DV12

---- 3.12.3.1  If this is the first time in the loop that we are making AQLIK_PTP_SO_DETAILS

	IF (@TABLE_NAME <> 'AQLIK_PTP_SO_DETAILS' AND @HASPTPSO_GL_ACC = 'Y' AND @HASPTPSO_ACC_TYP = 'Y' AND @HASPTPSO_DOC_TYP = 'Y' AND @HASPTPSO_POSTING_DATE = 'Y' AND @HASPTPSO_VENDOR_ACC = 'Y') AND  @vCOUNTER_PTP_SO = 1
	BEGIN

		SET @TABLE_NAME = '[DBO].[' + @TABLE_NAME + ']'
		BEGIN TRY
			EXEC SP_DROPTABLE 'AQLIK_PTP_SO_DETAILS' --drop the existing table with replaced name to avoid conflicts
			EXEC SP_RENAME @TABLE_NAME, 'AQLIK_PTP_SO_DETAILS'; --rename the table
			SET @MSG = 'Renamed ' + @TABLE_NAME + ' as ' + 'AQLIK_PTP_SO_DETAILS' --print back status for users
			
			INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, 'AQLIK_PTP_SO_DETAILS', @MSG)
			RAISERROR(@MSG, 10, -1) WITH NOWAIT  --Message concerning the running of the script
			SET @vCOUNTER_PTP_SO = @vCOUNTER_PTP_SO + 1
		END TRY
		BEGIN CATCH
			RAISERROR('error with renaming', 10, -1) WITH NOWAIT
		END CATCH
	END


-- 3.12.3.2  If this is not the first time in the loop that we are making AQLIK_PTP_SO

	IF (@TABLE_NAME <> 'AQLIK_PTP_SO_DETAILS'  AND @HASPTPSO_GL_ACC = 'Y' AND @HASPTPSO_ACC_TYP = 'Y' AND @HASPTPSO_DOC_NR = 'Y' AND @HASPTPSO_DOC_TYP = 'Y' AND @HASPTPSO_POSTING_DATE = 'Y') AND @vCOUNTER_PTP_SO > 1
	BEGIN
		SET @TABLE_NAME = '[DBO].[' + @TABLE_NAME + ']'
		BEGIN TRY

			SET @SQL='SELECT *
			INTO AQLIK_PTP_SO_DETAILS_2
			FROM 
			(SELECT * FROM '+ @TABLE_NAME  + '
			UNION ALL 
			SELECT *
			FROM AQLIK_PTP_SO_DETAILS) TMP'
			EXEC sp_executesql @SQL
			EXEC SP_DROPTABLE 'AQLIK_PTP_SO_DETAILS'
			EXEC SP_RENAME AQLIK_PTP_SO_DETAILS_2, 'AQLIK_PTP_SO_DETAILS'
		
			SET @MSG = 'Concatenated ' + @TABLE_NAME + ' into ' + 'AQLIK_PTP_SO_DETAILS' --print back status for users
			INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, 'AQLIK_PTP_SO_DETAILS', @MSG)
			RAISERROR(@MSG, 10, -1) WITH NOWAIT  --Message concerning the running of the script 
    
	        EXEC SP_RENAME @TABLE_NAME, 'TABLETODROP'
			EXEC SP_DROPTABLE 'TABLETODROP'
			SET @vCOUNTER_PTP_SO = @vCOUNTER_PTP_SO + 1
		END TRY
		BEGIN CATCH
			RAISERROR('error with renaming', 10, -1) WITH NOWAIT
		END CATCH
	END

--
--@HASAR_DOC_TYPE_BUCKET 

---- 3.12.4.1  If this is the first time in the loop that we are making AQLIK_AR_DETAILS

	IF (@TABLE_NAME <> 'AQLIK_AR_DETAILS' AND @HASAR_DOC_TYPE_BUCKET = 'Y') AND  @vCOUNTER_PTP_SO = 1
	BEGIN

		SET @TABLE_NAME = '[DBO].[' + @TABLE_NAME + ']'
		BEGIN TRY
			EXEC SP_DROPTABLE 'AQLIK_AR_DETAILS' --drop the existing table with replaced name to avoid conflicts
			EXEC SP_RENAME @TABLE_NAME, 'AQLIK_AR_DETAILS'; --rename the table
			SET @MSG = 'Renamed ' + @TABLE_NAME + ' as ' + 'AQLIK_AR_DETAILS' --print back status for users
			
			INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, 'AQLIK_AR_DETAILS', @MSG)
			RAISERROR(@MSG, 10, -1) WITH NOWAIT  --Message concerning the running of the script
			SET @vCOUNTER_PTP_SO = @vCOUNTER_PTP_SO + 1
		END TRY
		BEGIN CATCH
			RAISERROR('error with renaming', 10, -1) WITH NOWAIT
		END CATCH
	END


-- 3.12.4.2  If this is not the first time in the loop that we are making AQLIK_AR_DETAILS

	IF (@TABLE_NAME <> 'AQLIK_AR_DETAILS'  AND @HASAR_DOC_TYPE_BUCKET = 'Y') AND @vCOUNTER_PTP_SO > 1
	BEGIN
		SET @TABLE_NAME = '[DBO].[' + @TABLE_NAME + ']'
		BEGIN TRY

			SET @SQL='SELECT *
			INTO AQLIK_AR_DETAILS_2
			FROM 
			(SELECT * FROM '+ @TABLE_NAME  + '
			UNION ALL 
			SELECT *
			FROM AQLIK_AR_DETAILS) TMP'
			EXEC sp_executesql @SQL
			EXEC SP_DROPTABLE 'AQLIK_AR_DETAILS'
			EXEC SP_RENAME AQLIK_AR_DETAILS_2, 'AQLIK_AR_DETAILS'
		
			SET @MSG = 'Concatenated ' + @TABLE_NAME + ' into ' + 'AQLIK_AR_DETAILS' --print back status for users
			INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, 'AQLIK_AR_DETAILS', @MSG)
			RAISERROR(@MSG, 10, -1) WITH NOWAIT  --Message concerning the running of the script 
    
	        EXEC SP_RENAME @TABLE_NAME, 'TABLETODROP'
			EXEC SP_DROPTABLE 'TABLETODROP'
			SET @vCOUNTER_PTP_SO = @vCOUNTER_PTP_SO + 1
		END TRY
		BEGIN CATCH
			RAISERROR('error with renaming', 10, -1) WITH NOWAIT
		END CATCH
	END

--@HASCOPA_DOC_NR

---- 3.12.4.1  If this is the first time in the loop that we are making AQLIK_AR_DETAILS


	IF (@TABLE_NAME <> 'AQLIK_COPA_TRANS_DETAILS' AND @HASCOPA_DOC_NR = 'Y') AND  @vCOUNTER_PTP_SO = 1
	BEGIN

		SET @TABLE_NAME = '[DBO].[' + @TABLE_NAME + ']'
		BEGIN TRY
			EXEC SP_DROPTABLE 'AQLIK_COPA_TRANS_DETAILS' --drop the existing table with replaced name to avoid conflicts
			EXEC SP_RENAME @TABLE_NAME, 'AQLIK_COPA_TRANS_DETAILS'; --rename the table
			SET @MSG = 'Renamed ' + @TABLE_NAME + ' as ' + 'AQLIK_COPA_TRANS_DETAILS' --print back status for users
			
			INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, 'AQLIK_COPA_TRANS_DETAILS', @MSG)
			RAISERROR(@MSG, 10, -1) WITH NOWAIT  --Message concerning the running of the script
			SET @vCOUNTER_PTP_SO = @vCOUNTER_PTP_SO + 1
		END TRY
		BEGIN CATCH
			RAISERROR('error with renaming', 10, -1) WITH NOWAIT
		END CATCH
	END


-- 3.12.3.2  If this is not the first time in the loop that we are making AQLIK_AR_DETAILS

	IF (@TABLE_NAME <> 'AQLIK_COPA_TRANS_DETAILS'  AND @HASCOPA_DOC_NR = 'Y') AND @vCOUNTER_PTP_SO > 1
	BEGIN
		SET @TABLE_NAME = '[DBO].[' + @TABLE_NAME + ']'
		BEGIN TRY

			SET @SQL='SELECT *
			INTO AQLIK_COPA_TRANS_DETAILS_2
			FROM 
			(SELECT * FROM '+ @TABLE_NAME  + '
			UNION ALL 
			SELECT *
			FROM AQLIK_COPA_TRANS_DETAILS) TMP'
			EXEC sp_executesql @SQL
			EXEC SP_DROPTABLE 'AQLIK_COPA_TRANS_DETAILS'
			EXEC SP_RENAME AQLIK_AR_DETAILS_2, 'AQLIK_COPA_TRANS_DETAILS'
		
			SET @MSG = 'Concatenated ' + @TABLE_NAME + ' into ' + 'AQLIK_COPA_TRANS_DETAILS' --print back status for users
			INSERT INTO DV00_RT_USER_FEEDBACK_MESSAGE VALUES(@TABLE_NAME, 'AQLIK_COPA_TRANS_DETAILS', @MSG)
			RAISERROR(@MSG, 10, -1) WITH NOWAIT  --Message concerning the running of the script 
    
	        EXEC SP_RENAME @TABLE_NAME, 'TABLETODROP'
			EXEC SP_DROPTABLE 'TABLETODROP'
			SET @vCOUNTER_PTP_SO = @vCOUNTER_PTP_SO + 1
		END TRY
		BEGIN CATCH
			RAISERROR('error with renaming', 10, -1) WITH NOWAIT
		END CATCH
	END



-- 3.13 For tables that are AQLIK_AM (meaning import of AM_tables), remove the AQLIK_ prefix


   IF SUBSTRING(@TABLE_NAME,7,3) = 'AM_'
   BEGIN
	DECLARE @NEW_TABLE_NAME NVARCHAR(MAX) = SUBSTRING(@TABLE_NAME, 7, LEN(@TABLE_NAME) - 6)
    EXEC SP_DROPTABLE @NEW_TABLE_NAME
	EXEC SP_RENAME @TABLE_NAME, @NEW_TABLE_NAME
   END



-- 3.14 End of the loop for tables 


	FETCH NEXT FROM CUR_SYS_TABLES INTO @TABLE_NAME, @TABLE_ID
END
CLOSE CUR_SYS_TABLES
DEALLOCATE CUR_SYS_TABLES

-- 3.15 For AM tables, remove any empty lines in order to ensure that the joins with these
-- tables in the cubes do not cause duplication


  EXEC A_005Z_REMOVE_EMPTY_LINES_AM






GO
