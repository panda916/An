USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--ALTER PROCEDURE [dbo].B02_FIN_COA
CREATE     PROC [dbo].[script_B02_FIN_COA]
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
			 @currency nvarchar(max)			= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'currency')
			,@date1 nvarchar(max)				= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'date1')
			,@date2 nvarchar(max)				= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'date2')
			,@downloaddate nvarchar(max)		= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'downloaddate')
			,@exchangeratetype nvarchar(max)	= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'exchangeratetype')
			,@language1 nvarchar(max)			= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'language1')
			,@language2 nvarchar(max)			= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'language2')
			,@year nvarchar(max)				= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'year')
			,@id nvarchar(max)					= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'id')
			,@LIMIT_RECORDS INT                    = CAST((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS') AS INT)


      
SET ROWCOUNT @LIMIT_RECORDS


DECLARE @dateformat varchar(3)
SET @dateformat   = (SELECT dbo.get_param('dateformat'))
SET DATEFORMAT @dateformat;


/*In case we are in test mode according to the globals table*/




/*Change history comments*/


/*
	Title			:	B02_05_IT_FIN_GLM General Ledger account master data
	Description		:	Cube containing all company code data + general data for GL accounts 
      
	--------------------------------------------------------------
	Update history
	--------------------------------------------------------------
	Date		  | Who |	Description
	01-02-2016		MW		First version for Sony
	09-02-2016      NC      Added Data Base Log
	19-03-2017		CW    	Update and standardisation for SID
	09-06-2017		AJ 		Updated script with new naming convention
	22-03-2022	   Thuan	Remove MANDT field in join
	
*/



/*--Step 1
--This step joins the chart of accounts information together and adds the business domain information from the scope table.
--This step also limits the chart of accounts information on the company codes found in the SAP company codes table
--that was filtered on the company codes in scope during the extraction from SAP.
--Rows are being removed if they are not for the company codes found in the company codes table
--Fields are being added from other SAP tables as mentioned in JOIN clauses below
--Fields are being calculated as mentioned in SELECT clause below*/


EXEC sp_droptable 	'B02_01_TT_COA'
		
Select		
		A_SKB1.SKB1_MANDT, 
		AM_SCOPE.SCOPE_BUSINESS_DMN_L1,  
		AM_SCOPE.SCOPE_BUSINESS_DMN_L2,  
		A_T001.T001_KTOPL,
		A_T001.T001_BUKRS,
		A_T001.T001_BUTXT,      
		A_SKB1.SKB1_SAKNR,                
		A_SKA1.SKA1_KTOKS,
		A_SKA1.SKA1_XBILK,
		A_SKA1.SKA1_VBUND,              
		A_SKB1.SKB1_FSTAG,                  
		A_SKB1.SKB1_XOPVW,                 
		A_SKA1.SKA1_XLOEV,                  
		A_SKB1.SKB1_XLOEB,
		A_SKA1.SKA1_XSPEB,
		A_SKB1.SKB1_XSPEB,
		A_SKB1.SKB1_XINTB,
		A_SKB1.SKB1_MITKZ,
		A_SKA1.SKA1_BILKT,
		A_T001.T001_SPRAS
		--,
		--A_SKA1.SKA1_ERNAM,--User who create the Object
		--A_SKAT.SKAT_TXT20,
		--A_SKAT.SKAT_TXT50, 
		--A_USER_ADDR.USER_ADDR_NAME_TEXTC
	INTO B02_01_TT_COA 
    
	FROM A_SKB1  

	INNER JOIN A_T001
    ON  (A_SKB1.SKB1_BUKRS = A_T001.T001_BUKRS)  

	LEFT JOIN AM_SCOPE
	ON  (A_SKB1.SKB1_BUKRS = AM_SCOPE.SCOPE_CMPNY_CODE)
    
	LEFT JOIN A_SKA1 
    ON  (A_T001.T001_KTOPL = A_SKA1.SKA1_KTOPL) AND
        (A_SKB1.SKB1_SAKNR = A_SKA1.SKA1_SAKNR)
	
	--LEFT JOIN A_SKAT
	--ON SKA1_KTOPL=SKAT_KTOPL AND SKA1_SAKNR=SKAT_SAKNR

/*	LEFT JOIN A_USER_ADDR
	ON SKA1_ERNAM=USER_ADDR_BNAME */

/*--Step 2
--This step collects Active GL accounts (GL accounts which contain postings in BSEG)
-- A unique list of 'Mandant'(MANDT) , 'Company code'(BUKRS) and 'GL account info'(HKONT) is obtained
*/

EXEC sp_droptable 	'B02_02_TT_ACTIVE_GL'


	SELECT 
 		A_BSEG.BSEG_MANDT,
		A_BSEG.BSEG_BUKRS, 
		A_BSEG.BSEG_HKONT
    
	INTO B02_02_TT_ACTIVE_GL
    
	FROM A_BSEG
	
	GROUP BY
		A_BSEG.BSEG_MANDT,
		A_BSEG.BSEG_BUKRS, 
		A_BSEG.BSEG_HKONT
		

/*--Step 3
--This step creates a list of GR/IR GL clearing accounts from the standard accounts table
--Hardcoded values:
-- -- This step assumes that the transaction event key WRX is for Goods receipts or invoices
*/

EXEC sp_droptable	'B02_03_TT_GRIR_ACCNTS'

	SELECT T030UNION.* INTO B02_03_TT_GRIR_ACCNTS
	from (SELECT T030_MANDT, T030_KTOPL, T030_KONTH,'X' as [GR/IR] FROM A_T030 WHERE T030_KTOSL = 'WRX'
	UNION
	SELECT T030_MANDT, T030_KTOPL, T030_KONTS, 'X' FROM A_T030 WHERE T030_KTOSL = 'WRX') T030UNION

/*--Step 4
--This step adds the above information (active accounts and GRIR accounts) as well as other information
--to the chart of accounts table that was filtered on company code(s)
--Fields are being added from other SAP tables as mentioned in JOIN clauses below
--Fields are being calculated as mentioned in SELECT clause below*/


EXEC sp_droptable 	'B02_04_IT_FIN_COA'

		SELECT 
		B02_01_TT_COA.SKB1_MANDT,
		B02_01_TT_COA.[SCOPE_BUSINESS_DMN_L1],
		B02_01_TT_COA.[SCOPE_BUSINESS_DMN_L2],
		B02_01_TT_COA.T001_KTOPL, 
		B02_01_TT_COA.T001_BUKRS,
		B02_01_TT_COA.T001_BUTXT,
		--AM_FSMC.FSMC_ID,
		--AM_FSMC.FSMC_NAME,
		B02_01_TT_COA.SKB1_SAKNR,
		B00_SKAT.SKAT_TXT50, 
		B02_01_TT_COA.SKA1_KTOKS,
		A_T077Z.T077Z_TXT30, 
		B02_01_TT_COA.SKA1_XBILK,
		AM_T077X.INTERCO_TXT,
		B02_01_TT_COA.SKA1_VBUND,
		B02_01_TT_COA.SKB1_FSTAG,
		B02_01_TT_COA.SKB1_MITKZ,
		ISNULL(B00_DD07T.DD07T_DDTEXT, '')							AS ZF_DD07T_DDTEXT_REC_ACCNT_TYPE,
		
		ISNULL(B02_03_TT_GRIR_ACCNTS.[GR/IR],'')         					AS ZF_GR_IR_ACCOUNT,
		-- Which are marked for deletion
		CASE 
			WHEN B02_01_TT_COA.SKA1_XLOEV = 'X' OR B02_01_TT_COA.SKB1_XLOEB = 'X' THEN 'X'
			ELSE ''
		END													AS ZF_XLOEV_XLOEB_ACCNT_DEL,
		-- Blocked for posting information
		CASE 
			WHEN B02_01_TT_COA.SKA1_XSPEB = 'X' OR B02_01_TT_COA.SKB1_XSPEB = 'X' THEN 'X' 
			ELSE ''
		END 		AS ZF_XSPEB_ACCNT_BLOCKED,
		-- Active accounts

		CASE 
			WHEN B02_02_TT_ACTIVE_GL.BSEG_HKONT IS NULL THEN ''
			ELSE 'X'
		END                                                 AS ZF_BSEG_HKONG_ACCNT_ACTIVE,


		B02_01_TT_COA.SKA1_BILKT,

		AM_TANGO.TANGO_ACCT,
        AM_TANGO.TANGO_ACCT_TXT--,
		--A_SKA1.SKA1_ERNAM,--User who create the Object
		--A_SKAT.SKAT_TXT20,
		--A_SKAT.SKAT_TXT50, 
		--A_USER_ADDR.USER_ADDR_NAME_TEXTC
	
	INTO B02_04_IT_FIN_COA
                    
	FROM B02_01_TT_COA

	-- Add G/L account text
	LEFT JOIN B00_SKAT 
	ON  (B02_01_TT_COA.T001_KTOPL = B00_SKAT.SKAT_KTOPL) AND 
		(B02_01_TT_COA.SKB1_SAKNR = B00_SKAT.SKAT_SAKNR)
 
	-- Add details of whether GL account is active in the GL
	LEFT JOIN B02_02_TT_ACTIVE_GL
	ON	(B02_02_TT_ACTIVE_GL.BSEG_BUKRS = B02_01_TT_COA.T001_BUKRS) AND 
		(B02_02_TT_ACTIVE_GL.BSEG_HKONT = B02_01_TT_COA.SKB1_SAKNR)
      
	-- Add supplier account group text
	LEFT JOIN A_T077Z
	ON  A_T077Z.T077Z_KTOPL = B02_01_TT_COA.T001_KTOPL AND
		A_T077Z.T077Z_KTOKS = B02_01_TT_COA.SKA1_KTOKS

	-- Add reconciliation account type text
	LEFT JOIN B00_DD07T
	ON  
		(B02_01_TT_COA.SKB1_MITKZ = LEFT( B00_DD07T.DD07T_DOMVALUE_L,1)) 
		AND (B00_DD07T.DD07T_DOMNAME = 'MITKZ')

	-- Add GR/IR account indicator
	LEFT JOIN B02_03_TT_GRIR_ACCNTS 
	ON 	B02_01_TT_COA.T001_KTOPL = B02_03_TT_GRIR_ACCNTS.T030_KTOPL AND
		B02_01_TT_COA.SKB1_SAKNR = B02_03_TT_GRIR_ACCNTS.T030_KONTH  
  
	-- Add intercompany flag 
	LEFT JOIN AM_T077X
	ON B02_01_TT_COA.SKA1_KTOKS = AM_T077X.T077X_KTOKD
		AND AM_T077X.T077X_SPRAS = B02_01_TT_COA.T001_SPRAS
    -- Add Tango account mapping
	LEFT JOIN AM_TANGO
	ON DBO.REMOVE_LEADING_ZEROES(B02_01_TT_COA.SKB1_SAKNR) =  DBO.REMOVE_LEADING_ZEROES(AM_TANGO.TANGO_GL_ACCT)

	--LEFT JOIN AM_FSMC
	--ON AM_FSMC.FSMC_COMPANY_CODE = B02_01_TT_COA.T001_BUKRS
	

/*Rename fields for Qlik*/

EXEC sp_RENAME_FIELD 'B02_', 'B02_04_IT_FIN_COA'
EXEC SP_REMOVE_TABLES '%_TT_%'

/* log cube creation*/

INSERT INTO [dbo].[_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Cube completed','B02_04_IT_FIN_COA',(SELECT COUNT(*) FROM B02_04_IT_FIN_COA) 
        

/* log end of procedure*/


INSERT INTO [dbo].[_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL
GO
