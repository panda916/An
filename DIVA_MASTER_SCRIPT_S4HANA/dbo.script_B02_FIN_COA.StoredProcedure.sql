USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--ALTER PROCEDURE [dbo].B02_FIN_COA
CREATE PROC [dbo].[script_B02_FIN_COA]
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


/*Change history comments*/
/*
	Title			:	script_B02_FIN_COA
	Description		:	Cube containing all company code data + general data for GL accounts 
      
	--------------------------------------------------------------
	Update history
	--------------------------------------------------------------
	Date		  | Who |	Description
	01-02-2016		MW		First version for Sony
	09-02-2016      NC      Added Data Base Log
	19-03-2017		CW    	Update and standardisation for SID
	09-06-2017		AJ 		Updated script with new naming convention
	05-08-2019		VL		Update script with S4HANA logic and Test mode
	24-03-2022	   Thuan	Remove MANDT field in join
*/


/*Test mode*/

SET ROWCOUNT @LIMIT_RECORDS

/*--Step 1
--This step collects Active GL accounts (GL accounts which contain postings in BSEG)
-- A unique list of 'Mandant'(MANDT) , 'Company code'(BUKRS) and 'GL account info'(RACCT) is obtained
*/

EXEC SP_REMOVE_TABLES'B02_01_TT_ACTIVE_GL'


	SELECT DISTINCT
		ACDOCA_RCLNT,
		ACDOCA_RBUKRS, 
		ACDOCA_RACCT,
		ACDOCA_KTOPL,
		SKA1_KTOKS,
		SKA1_BILKT,
		SKA1_XSPEB,
		SKA1_XLOEV,
		SKA1_VBUND,
		SKA1_XBILK,
		T001_BUTXT,
		[SCOPE_BUSINESS_DMN_L1],
		[SCOPE_BUSINESS_DMN_L2],
		SKB1_MITKZ,
		SKB1_XSPEB,
		SKB1_XLOEB,
		SKB1_FSTAG
	INTO B02_01_TT_ACTIVE_GL 
	FROM B00_ACDOCA
	-- Get G/L account information from SKA1
	LEFT JOIN A_SKA1
	ON B00_ACDOCA.ACDOCA_KTOPL = A_SKA1.SKA1_KTOPL
	AND B00_ACDOCA.ACDOCA_RACCT = A_SKA1.SKA1_SAKNR
	
	--Get company information
	LEFT JOIN A_T001
	ON B00_ACDOCA.ACDOCA_RBUKRS = A_T001.T001_BUKRS

	LEFT JOIN AM_SCOPE
	ON B00_ACDOCA.ACDOCA_RBUKRS = AM_SCOPE.SCOPE_CMPNY_CODE

	LEFT JOIN A_SKB1
	ON B00_ACDOCA.ACDOCA_RBUKRS = A_SKB1.SKB1_BUKRS
	AND B00_ACDOCA.ACDOCA_RACCT = A_SKB1.SKB1_SAKNR


/*--Step 2
--This step adds the above information (active accounts and GRIR accounts) as well as other information
--to the chart of accounts table that was filtered on company code(s)
--Fields are being added from other SAP tables as mentioned in JOIN clauses below
--Fields are being calculated as mentioned in SELECT clause below*/


EXEC SP_REMOVE_TABLES'B02_02_IT_FIN_COA'

		SELECT DISTINCT
		B02_01_TT_ACTIVE_GL.ACDOCA_RCLNT,
		B02_01_TT_ACTIVE_GL.[SCOPE_BUSINESS_DMN_L1],
		B02_01_TT_ACTIVE_GL.[SCOPE_BUSINESS_DMN_L2],
		B02_01_TT_ACTIVE_GL.ACDOCA_KTOPL, 
		B02_01_TT_ACTIVE_GL.ACDOCA_RBUKRS,
		B02_01_TT_ACTIVE_GL.T001_BUTXT,
		B02_01_TT_ACTIVE_GL.ACDOCA_RACCT,
		B00_SKAT.SKAT_TXT50, 
		B02_01_TT_ACTIVE_GL.SKA1_KTOKS,
		B02_01_TT_ACTIVE_GL.SKA1_XBILK,
		B02_01_TT_ACTIVE_GL.SKA1_VBUND,
		B02_01_TT_ACTIVE_GL.SKB1_FSTAG,
		B02_01_TT_ACTIVE_GL.SKB1_MITKZ,
		
		-- Which are marked for deletion
		CASE 
			WHEN B02_01_TT_ACTIVE_GL.SKA1_XLOEV = 'X' OR B02_01_TT_ACTIVE_GL.SKB1_XLOEB = 'X' THEN 'X'
			ELSE ''
		END													AS ZF_XLOEV_XLOEB_ACCNT_DEL,
		-- Blocked for posting information
		CASE 
			WHEN B02_01_TT_ACTIVE_GL.SKA1_XSPEB = 'X' OR B02_01_TT_ACTIVE_GL.SKB1_XSPEB = 'X' THEN 'X' 
			ELSE ''
		END 		AS ZF_XSPEB_ACCNT_BLOCKED,
		-- Active accounts

		CASE 
			WHEN B02_01_TT_ACTIVE_GL.ACDOCA_RACCT IS NULL THEN ''
			ELSE 'X'
		END                                                 AS ZF_ACDOCA_HKONG_ACCNT_ACTIVE,


		B02_01_TT_ACTIVE_GL.SKA1_BILKT,

		AM_TANGO.TANGO_ACCT,
        AM_TANGO.TANGO_ACCT_TXT
	
	INTO B02_02_IT_FIN_COA
                    
	FROM B02_01_TT_ACTIVE_GL

	-- Add G/L account text
	LEFT JOIN B00_SKAT 
	ON  (B02_01_TT_ACTIVE_GL.ACDOCA_KTOPL = B00_SKAT.SKAT_KTOPL) AND 
		(B02_01_TT_ACTIVE_GL.ACDOCA_RACCT = B00_SKAT.SKAT_SAKNR)
      
    -- Add Tango account mapping
	LEFT JOIN AM_TANGO
	ON dbo.REMOVE_LEADING_ZEROES(B02_01_TT_ACTIVE_GL.ACDOCA_RACCT) = dbo.REMOVE_LEADING_ZEROES(AM_TANGO.TANGO_GL_ACCT)

/*Rename fields for Qlik*/

EXEC sp_RENAME_FIELD 'B02_', 'B02_02_IT_FIN_COA'
-- Drop all temporary table
EXEC SP_REMOVE_TABLES'%_TT_%'

/* log cube creation*/

INSERT INTO [dbo].[_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Cube completed','B02_02_IT_FIN_COA',(SELECT COUNT(*) FROM B02_02_IT_FIN_COA) 
        

/* log end of procedure*/


INSERT INTO [dbo].[_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL
GO
