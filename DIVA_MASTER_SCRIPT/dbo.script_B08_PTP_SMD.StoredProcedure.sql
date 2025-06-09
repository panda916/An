USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--ALTER PROCEDURE dbo.B08_PTP_SMD 
CREATE     PROCEDURE [dbo].[script_B08_PTP_SMD]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START


/* Initiate the log */  
--Create database log table if it does not exist
IF OBJECT_ID('LOG_SP_EXECUTION', 'U') IS NULL BEGIN CREATE TABLE [DBO].[LOG_SP_EXECUTION] ([DATABASE] NVARCHAR(MAX) NULL,[OBJECT] NVARCHAR(MAX) NULL,[OBJECT_TYPE] NVARCHAR(MAX) NULL,[USER] NVARCHAR(MAX) NULL,[DATE] DATE NULL,[TIME] TIME NULL,[DESCRIPTION] NVARCHAR(MAX) NULL,[TABLE] NVARCHAR(MAX),[ROWS] INT) END

--Log start of procedure
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Procedure started',NULL,NULL

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

/*Change history comments*/

/*
  Title: CUBE PTP-01-SMD Supplier master data
  Description: Listing of all suppliers and associated master data attributes, at company code level

  --------------------------------------------------------------
  Update history
  --------------------------------------------------------------
  Date		    | Who	|	Description
  31-03-2016	  MW		First version for Sony
  13-04-2016	  MW		Tidy up of field names to align with other cubes
  19-04-2016	  MW		Updated intercompany logic to remove trading partner logic and make ELSE case clearer that this is an error in ETL006
  08-02-20117	  JSM		Added database log for the script and commented all the indexes
  19-03-2017	  CW        Update and standardisation for SID
  28-07-2017      NP        Naming convention
  22-03-2022	  Thuan	    Remove MANDT field in join
*/
 
/*--Step 1
-- Create a list of suppliers for which purchase orders are found on or after @date1
*/

	EXEC sp_droptable 'B08_01_TT_ACTV_SUPL1'

    SELECT EKKO_MANDT, EKKO_BUKRS, EKKO_LIFNR  
    INTO B08_01_TT_ACTV_SUPL1
    FROM A_EKKO WHERE (EKKO_BEDAT >= @date1)

/*--Step 2
-- Create a list of actvie suppliers: those for which there are purchase orders, MM invoices or Finance documents
   on or after @date1
*/

	EXEC sp_droptable 'B08_02_TT_ACTV_SUPL2'
	EXEC sp_droptable 'B08_03_TT_ACTV_SUPL3'
	EXEC sp_droptable 'B08_04_TT_ACTV_SUPL4'
	EXEC sp_droptable 'B08_05_TT_ACTV_SUPL5'
	    
 	SELECT  RBKP_MANDT AS EKKO_MANDT, RBKP_BUKRS AS EKKO_BUKRS, RBKP_LIFNR AS EKKO_LIFNR INTO B08_02_TT_ACTV_SUPL2 FROM A_RBKP	WHERE (RBKP_BUDAT >= @date1)
    SELECT  BSIK_MANDT AS EKKO_MANDT, BSIK_BUKRS AS EKKO_BUKRS, BSIK_LIFNR AS EKKO_LIFNR INTO B08_03_TT_ACTV_SUPL3 FROM A_BSIK	WHERE (BSIK_BUDAT >= @date1)
    SELECT  BSAK_MANDT AS EKKO_MANDT, BSAK_BUKRS AS EKKO_BUKRS, BSAK_LIFNR AS EKKO_LIFNR INTO B08_04_TT_ACTV_SUPL4 FROM A_BSAK	WHERE (BSAK_BUDAT >= @date1)
	SELECT EKKO_MANDT, EKKO_BUKRS, EKKO_LIFNR  
    INTO B08_05_TT_ACTV_SUPL5 FROM B08_01_TT_ACTV_SUPL1
	UNION SELECT EKKO_MANDT, EKKO_BUKRS, EKKO_LIFNR FROM B08_02_TT_ACTV_SUPL2
	UNION SELECT EKKO_MANDT, EKKO_BUKRS, EKKO_LIFNR FROM B08_03_TT_ACTV_SUPL3
	UNION SELECT EKKO_MANDT, EKKO_BUKRS, EKKO_LIFNR FROM B08_04_TT_ACTV_SUPL4
	GROUP BY EKKO_MANDT, EKKO_BUKRS, EKKO_LIFNR

/*--Step 3
-- Enrich the supplier master data with above information and information from other tables
-- Rows are being removed due to the following filters (WHERE): 
   Supplier is found for the company codes in scope as specified in AM_Scope table and (LFB1_BUKRS)
-- Data is being duplicated based on
   Supplier central master data (LFA1) is duplicated if the supplier is found in more than one company code in 
   the list of suppliers per company code (LFB1)
--Fields are being added from other SAP tables as mentioned in JOIN clauses below
--Fields are being calculated as mentioned in SELECT clause below*/

 /* Delete cube if it exists already */
EXEC sp_droptable 'B08_06_IT_PTP_SMD'

	SELECT
		A_LFA1.LFA1_MANDT,						
		A_LFB1.LFB1_BUKRS,
		A_T001.T001_BUTXT, 						
		A_LFB1.LFB1_LIFNR, 						
		A_LFA1.LFA1_NAME1, 						
		A_LFA1.LFA1_LAND1, 						
		A_LFA1.LFA1_SORTL, 						
		A_LFA1.LFA1_KTOKK, 						
		B00_T077Y.T077Y_TXT30,						
		A_LFB1.LFB1_AKONT, 						
		A_LFA1.LFA1_ERDAT, 						
		-- Add the year month for the supplier creation date
		CAST(RTRIM(YEAR(A_LFA1.LFA1_ERDAT)) AS VARCHAR(4)) + '-' + RIGHT('0' + RTRIM(MONTH(A_LFA1.LFA1_ERDAT)), 2) AS ZF_LFA1_ERDAT_YEAR_MONTH,	
		A_LFA1.LFA1_ERNAM, 						
		A_LFB1.LFB1_ZWELS, 						
		A_LFB1.LFB1_ZTERM, 						
		B00_T052U.T052U_TEXT1,					
		
		-- Add the intercompany category
		CASE 
			WHEN AM_T077Y.INTERCO_TXT IS NOT NULL THEN AM_T077Y.INTERCO_TXT
			ELSE 'Supplier category not available.'														  
			END										 AS INTERCO_TXT,							
		
		A_LFA1.LFA1_VBUND,
		A_LFA1.LFA1_BRSCH,

		-- Add the supplier deleted flag
		CASE 
			WHEN (A_LFA1.LFA1_LOEVM='X' OR A_LFB1.LFB1_LOEVM='X') THEN 'X' 
			ELSE '' 
		END								AS ZF_LFA1_LFB1_LOEVM,
		-- Add the supplier blocked flag
		CASE 
			WHEN (A_LFA1.LFA1_SPERR='X' OR A_LFB1.LFB1_SPERR='X') THEN 'X' 
			ELSE '' 
		END								AS ZF_LFA1_LFB1_SPERR,
		-- Add supplier blocked or deleted flag
		CASE 
			WHEN (A_LFA1.LFA1_LOEVM='X' OR A_LFA1.LFA1_SPERR='X' OR A_LFB1.LFB1_LOEVM='X' OR A_LFB1.LFB1_SPERR='X') THEN 'X' 
			ELSE '' 
		END 							AS ZF_SEPRR_LOEVM,
		-- Logic for checking is a supplier is active. Active = PO raised during the period AND not marked as blocked/deleted
		CASE 
			WHEN (B08_05_TT_ACTV_SUPL5.EKKO_LIFNR IS NULL) THEN
				CASE WHEN (A_LFA1.LFA1_LOEVM='X' OR A_LFA1.LFA1_SPERR='X' OR A_LFB1.LFB1_LOEVM='X' OR A_LFB1.LFB1_SPERR='X') THEN 'DEL'      
				ELSE '' END
			ELSE 'X' 
		END 							AS ZF_SPERR_LOEVM_ACTIVE, 
		
		-- Add a flag to show if the vendor is found in the vendor exception list
		CASE 
			WHEN AM_VENDOR_EXCEPTION_LIST.VEL_COMPANY_CODE IS NULL THEN 'NO' 
			ELSE 'YES' 
		END								AS ZF_VENDOR_EXCEPTION_LIST

		
	INTO B08_06_IT_PTP_SMD
    
	-- Include central level supplier master data
    FROM A_LFA1
    
	-- Include company code level supplier master data
	INNER JOIN A_LFB1
    ON A_LFA1.LFA1_LIFNR = A_LFB1.LFB1_LIFNR  
    
	-- Restriction to only company codes specified in scope
	INNER JOIN AM_SCOPE
    ON A_LFB1.LFB1_BUKRS = AM_SCOPE.SCOPE_CMPNY_CODE
    
	-- Company code information
    LEFT JOIN A_T001 
    ON A_LFB1.LFB1_BUKRS = A_T001.T001_BUKRS
    
	-- Intercompany information 
	LEFT JOIN AM_T077Y 
	ON dbo.REMOVE_LEADING_ZEROES(A_LFA1.LFA1_KTOKK) = dbo.REMOVE_LEADING_ZEROES(AM_T077Y.T077Y_KTOKK)

	-- Account group text description
	LEFT JOIN B00_T077Y
    ON A_LFA1.LFA1_KTOKK = B00_T077Y.T077Y_KTOKK
    
	-- Include payment terms information
	LEFT JOIN B00_T052U
	ON A_LFB1.LFB1_ZTERM = B00_T052U.T052U_ZTERM   
    
	-- Include whether supplier is active, based on PO, invoice of FI document being raised
	LEFT JOIN B08_05_TT_ACTV_SUPL5 
	ON A_LFB1.LFB1_BUKRS = B08_05_TT_ACTV_SUPL5.EKKO_BUKRS AND 
	   A_LFB1.LFB1_LIFNR = B08_05_TT_ACTV_SUPL5.EKKO_LIFNR
	
	-- Add indicator to show if the supplier is found int he vendor exception list 
	LEFT JOIN AM_VENDOR_EXCEPTION_LIST 
	ON A_LFB1.LFB1_BUKRS=AM_VENDOR_EXCEPTION_LIST.VEL_COMPANY_CODE AND
	   A_LFB1.LFB1_LIFNR=AM_VENDOR_EXCEPTION_LIST.VEL_SUPPLIER_NUM



/*Rename fields for Qlik*/

EXEC sp_RENAME_FIELD 'B08_', 'B08_06_IT_PTP_SMD'

-- Delete TT TABLE

	EXEC sp_droptable 'B08_01_TT_ACTV_SUPL1'
	EXEC sp_droptable 'B08_02_TT_ACTV_SUPL2'
	EXEC sp_droptable 'B08_03_TT_ACTV_SUPL3'
	EXEC sp_droptable 'B08_04_TT_ACTV_SUPL4'
	EXEC sp_droptable 'B08_05_TT_ACTV_SUPL5'
	EXEC SP_REMOVE_TABLES '%_TT_%'    
/* log cube creation*/

INSERT INTO [dbo].[_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Cube completed','B08_06_IT_PTP_SMD',(SELECT COUNT(*) FROM B08_06_IT_PTP_SMD)
 
        


--Log end of procedure
INSERT INTO [dbo].[_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL
GO
