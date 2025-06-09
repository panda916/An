USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[script_B01_USERS](@DATABASE AS NVARCHAR(MAX))

WITH EXECUTE AS CALLER 
AS 

--DYNAMIC_SCRIPT_START

/* Initiate the log */  

--Create database log table if it does not exist
IF OBJECT_ID('_DatabaseLogTable', 'U') IS NULL BEGIN CREATE TABLE [dbo].[_DatabaseLogTable] ([Database] nvarchar(max) NULL,[Object] nvarchar(max) NULL,[Object Type] nvarchar(max) NULL,[User] nvarchar(max) NULL,[Date] date NULL,[Time] time NULL,[Description] nvarchar(max) NULL,[Table] nvarchar(max),[Rows] int) END

--Log start of procedure
INSERT INTO [dbo].[_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure started',NULL,NULL

	/* Initialize parameters from globals table */
    DECLARE  
				@CURRENCY NVARCHAR(3)                 = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'currency')
				,@DATE1 NVARCHAR(MAX)                           = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date1')
				,@DATE2 NVARCHAR(MAX)                           = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date2')
				,@DOWNLOADDATE NVARCHAR(MAX)             = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'downloaddate')
				,@DATEFORMAT VARCHAR(3)             = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'dateformat')
				,@EXCHANGERATETYPE NVARCHAR(MAX)  = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'exchangeratetype')
				,@LANGUAGE1 NVARCHAR(3)                = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language1')
				,@LANGUAGE2 NVARCHAR(3)                = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language2')
				,@LIMIT_RECORDS INT                    = CAST((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS') AS INT)
				,@FISCAL_YEAR_FROM NVARCHAR(MAX)					= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'FISCAL_YEAR_FROM')
				,@FISCAL_YEAR_TO NVARCHAR(MAX)					= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'FISCAL_YEAR_TO')
                 SET DATEFORMAT @DATEFORMAT;
                 
/*Change history comments

	Title: [script_B01_USERS] 
	Description: This cube creates a SAP User database 
	   
	-------------------------------------------------------------- 
	Update history 
	-------------------------------------------------------------- 
	Date        | Who  |  Description 
	31-03-2016    MW      First version for Sony 
	14-04-2016    EH      Add code comments for understanding 
	02-08-2017    SK      Code Reformatting to create standard(region/system specific) version  
	19-03-2017    CW      Update and standardisation for SID
	06-06-2017 	  AJ	  Updated with new naming convention
	05-08-2019	  VL	  Update with new A_V_USERNAME
	24-03-2022	 Thuan	 Remove MANDT field in join
*/ 
      

/*Test mode*/

SET ROWCOUNT @LIMIT_RECORDS


/*-- Step 1
-- Create a list of users enriched with some additional information 
-- The following hard-coded values are found in this step
   -- definition of user type (USR02_USTYP)
   -- definition of user flag (USR02_UFLAG)
--Fields are being added from other SAP tables as mentioned in JOIN clauses below
--Fields are being calculated as mentioned in SELECT clause below*/


EXEC SP_REMOVE_TABLES'B01_01_IT_USERS'

	  SELECT A_USR02.USR02_MANDT 
		,A_USR02.USR02_BNAME 
		,V_USERNAME_NAME_TEXT
		,USR02_ERDAT
		,USR02_TRDAT
		,USR02_GLTGV
		,USR02_GLTGB
		,USR02_USTYP
             
		-- Logic to add text for user type 
		,CASE USR02_USTYP 
			WHEN 'A' THEN 'Dialog' 
			WHEN 'B' THEN 'System' 
			WHEN 'C' THEN 'Communication' 
			WHEN 'L' THEN 'Reference' 
			WHEN 'S' THEN 'Service' 
			ELSE '' 
		END							AS ZF_USR02_USTYP_SHORT_DESC
              
		-- Logic to give context to meaning of user type 
		,CASE USR02_USTYP 
			WHEN 'A' THEN 'Dialog user (regular)' 
			WHEN 'B' THEN 'System user (dialog not possible)' 
			WHEN 'C' THEN 'Communication user (dialog not possible)' 
			WHEN 'L' THEN 'Reference user (dialog not possible)' 
			WHEN 'S' THEN 'Service (dialog possible, no expiry)' 
		END							AS ZF_USR02_USTYP_LONG_DESC
		,USR02_CLASS 
		,A_USR02.USR02_ANAME 
		,USR02_LOCNT

		-- Logic to show locked and unlocked accounts 
		,CASE 
			WHEN USR02_UFLAG = 0 THEN '' 
			ELSE 'X' 
		END							AS ZF_USR02_UFLAG 
		,USR02_UFLAG 
              
		-- Logic to show reason for lock 
		,CASE USR02_UFLAG 
			WHEN 0 THEN 'Unlocked' 
			WHEN 32 THEN 'Locked globally by Admin' 
			WHEN 64 THEN 'Locked locally by Admin' 
			WHEN 96 THEN 'Locked globally & locally by Admin' 
			WHEN 128 THEN 'Locked due to incorrect logins' 
			WHEN 160 THEN 'Locked due to incorrect logins & globally by Admin' 
			WHEN 192 THEN 'Locked due to incorrect logins & locally by Admin' 
			WHEN 224 THEN 'Locked due to incorrect logins & globally & locally by Admin' 
			ELSE '' 
		END							AS ZF_USR02_UFLAG_DESC 
		,USR02_BCODE 
		,A_USR06.USR06_LIC_TYPE 
		,B00_TUTYP.TUTYP_UTYPTEXT
      
	  INTO   B01_01_IT_USERS
      
	  -- Include user master data and logon info 
      FROM  A_USR02 
      
	  -- Include users full name 
      LEFT JOIN A_V_USERNAME 
	  ON A_USR02.USR02_BNAME = A_V_USERNAME.V_USERNAME_BNAME 
      
	  -- Include licence type info 
      LEFT JOIN A_USR06 
      ON A_USR02.USR02_BNAME = A_USR06.USR06_BNAME 
      
	  -- Include licence type text 
      LEFT JOIN B00_TUTYP 
      ON A_USR06.USR06_LIC_TYPE = B00_TUTYP.TUTYP_USERTYP 


/*Rename fields for Qlik*/

EXEC sp_RENAME_FIELD 'B01_', 'B01_01_IT_USERS'
EXEC SP_REMOVE_TABLES '%_TT_%'

/* log cube creation*/
      
       
INSERT INTO [dbo].[_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Cube completed','B01_01_IT_USERS',(SELECT COUNT(*) FROM B01_01_IT_USERS) 

/* log end of procedure*/

INSERT INTO [dbo].[_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL
GO
