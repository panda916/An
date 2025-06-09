USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--ALTER PROCEDURE [dbo].[B09_PTP_POS] 
CREATE     PROCEDURE [dbo].[script_B09_PTP_POS_old]
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
    Title		:  _Cube PTP-03 purchase orders
    Description	: Creates the cube with all purchase order details at line item level
	--------------------------------------------------------------
    Update history
    --------------------------------------------------------------
    Date		| 	Who |	Description
    31-03-2016		MW		First version for Sony
	13-04-2016		MW		Tidy up of field names to align with other cubes
	22-04-2016      FT      Add company code currency factor
	11-05-2016		MW		Added company code to AM_AM_FSMC_SCOPE_FSMC joIN. Had to move joIN to main SELECT statement AS BUKRS not IN EKKN
	08-02-2017		JSM		Added databASe log
	19-03-2017	    CW      Update and standardisation for SID
    28-07-2017	    NP      Naming convention
	30-07-2017      CW      Add many-to-many mapping tables
	05-08-2019		VL		Update script with HANA logic
	22-03-2022	   Thuan	Remove MANDT field in join
*/


/*--Step 1
-- First goods receipt per PO:
-- This step identifies the user (EKBE_ERNAM), input date (EKBE_CPUDT) and document date (EKBE_BEDAT)
   for the first GR (EKBE_VGABE = 1) per PO line item (EKPO_EBELN and EKPO_EBELP)
-- Rows are being removed due to the following filters (WHERE): 
					Only event types for goods receipts (EKBE_VGABE) = 1 
					Only the first GR per PO line item is kept
*/


	EXEC SP_DROPTABLE 'B09_01_TT_SORT_USR_GR'
	EXEC SP_DROPTABLE 'B09_02_TT_1ST_GR_USR_DT_PER_PO'

   -- Create a field that shows the line number (ZF_ROW_NUMBER)
   -- for each line withIN a PO line that is for a goods receipt (EKBE_VGABE = 1)
   -- (there may be more than one goods receipt for a purchase order)
   -- the line number (ZF_ROW_NUMBER) is order by input date (EKBE_CPUDT) and time-stamp (EKBE_CPUTM)

   ;WITH B09_01_TT_SORT_USR_GR AS (
   SELECT 
      A_EKBE.EKBE_MANDT,
      A_EKBE.EKBE_EBELN,	
      A_EKBE.EKBE_EBELP,
      A_EKBE.EKBE_ERNAM	AS ZF_EKBE_ERNAM_1ST_GR_USER,
	  A_EKBE.EKBE_CPUDT	AS ZF_EKBE_CPUDT_1ST_GR_DATE,
	  A_EKBE.EKBE_BUDAT	AS ZF_EKBE_BUDAT_1ST_GR_DATE,
	  A_EKBE.EKBE_BLDAT	AS ZF_EKBE_BLDAT_1ST_GR_DATE,								
      ROW_NUMBER() OVER (
			PARTITION BY A_EKBE.EKBE_MANDT,
						 A_EKBE.EKBE_EBELN,
						 A_EKBE.EKBE_EBELP

			ORDER BY     A_EKBE.EKBE_MANDT,
						 A_EKBE.EKBE_EBELN,
						 A_EKBE.EKBE_EBELP,
						 A_EKBE.EKBE_CPUDT,
						 A_EKBE.EKBE_CPUTM) AS ZF_ROW_NUMBER
      FROM A_EKBE
	  WHERE EKBE_VGABE='1'  
	)

   -- Keep the first goods receipt (ZF_ROW_NUMBER) for each purchase order line item

   SELECT
		EKBE_MANDT,
		EKBE_EBELN,
		EKBE_EBELP,
        ZF_EKBE_ERNAM_1ST_GR_USER,
	    ZF_EKBE_CPUDT_1ST_GR_DATE,
	    ZF_EKBE_BUDAT_1ST_GR_DATE,
	    ZF_EKBE_BLDAT_1ST_GR_DATE							
   INTO B09_02_TT_1ST_GR_USR_DT_PER_PO
   FROM B09_01_TT_SORT_USR_GR
   WHERE ZF_ROW_NUMBER=1

   -- CREATE PRODUCT CATEGORY TABLE
   EXEC A_005D_CREATE_PROCUREMENT_CATEGORY_STRUCTURE_EXE
/*--Step 2 
    All goods receipts per PO:
    Rather than keeping information only on the first GR per PO, create a mapping table that will give 
	all goods receipt users and dates per PO line item.
	This mapping table can be integrated into Qlik using APPLYMAP() function
  --Only records relating to goods receipts are kept
		EKBE_VGABE = '1'

*/	

	EXEC SP_DROPTABLE 'B09_03_TT_MAPP_POS_GRS'

	SELECT 
		CONCAT(EKBE_EBELN, '|', EKBE_EBELP) AS ZF_MAPP_PO_GR
		,EKBE_GJAHR+'|'+EKBE_BELNR+'|'+EKBE_BUZEI AS ZF_EKBE_INV_REF
		,EKBE_ERNAM
		,EKBE_CPUDT
	    ,EKBE_BLDAT
		,EKBE_BUDAT
		,EKBE_BELNR
		,A_V_USERNAME.V_USERNAME_PERSNUMBER
        ,A_V_USERNAME.V_USERNAME_NAME_LAST
        ,A_V_USERNAME.V_USERNAME_NAME_TEXT
        ,A_V_USERNAME.V_USERNAME_MC_NAMEFIR
        ,A_V_USERNAME.V_USERNAME_MC_NAMELAS
		,B00_USR02.USR02_USTYP
		,CASE 
		 WHEN B00_USR02.USR02_USTYP = 'A' THEN 'Dialog' 
		 WHEN B00_USR02.USR02_USTYP = 'B' THEN 'System' 
		 WHEN B00_USR02.USR02_USTYP = 'C' THEN 'Communication (external RFC)' 
		 WHEN B00_USR02.USR02_USTYP = 'L' THEN 'Reference' 
		 WHEN B00_USR02.USR02_USTYP = 'S' THEN 'Service' 
		 ELSE 'Other' 
		END AS ZF_USR02_USTYP_DESC
		,SUM(CASE WHEN EKBE_VGABE IN ('1')  THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) * COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1)) END) AS ZF_EKBE_DMBTR_GR_S_CUC
	    ,SUM(CASE WHEN EKBE_VGABE IN ('1')  THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) ) END)	AS ZF_EKBE_DMBTR_GR_S

	INTO B09_03_TT_MAPP_POS_GRS
	FROM A_EKBE

	LEFT JOIN A_V_USERNAME
	   ON EKBE_ERNAM = A_V_USERNAME.V_USERNAME_BNAME
    LEFT JOIN B00_USR02
	   ON EKBE_ERNAM = B00_USR02.USR02_BNAME

	--Add the company code (so that we can add the house currency)
	LEFT JOIN A_EKKO 
	ON A_EKBE.EKBE_EBELN = A_EKKO.EKKO_EBELN

	--Add the house currency
	LEFT JOIN A_T001 
	ON A_EKKO.EKKO_BUKRS = A_T001.T001_BUKRS 

	-- Add currency conversion factors for company code currency
	LEFT JOIN B00_TCURX TCURX_CC 
	on
	   A_T001.T001_WAERS = TCURX_CC.TCURX_CURRKEY   

	-- Add currency factor from company currency to USD

	LEFT JOIN B00_IT_TCURF
	ON A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR
	AND B00_IT_TCURF.TCURF_TCURR  = @currency  
	AND B00_IT_TCURF.TCURF_GDATU = (
		SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
		FROM B00_IT_TCURF
		WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
				B00_IT_TCURF.TCURF_TCURR  = @currency  AND
				B00_IT_TCURF.TCURF_GDATU <= EKBE_BUDAT
		ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
		)
	-- Add exchange rate from company currency to USD
	LEFT JOIN B00_IT_TCURR
		ON A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR
		AND B00_IT_TCURR.TCURR_TCURR  = @currency  
		AND B00_IT_TCURR.TCURR_GDATU = (
			SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
			FROM B00_IT_TCURR
			WHERE A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
					B00_IT_TCURR.TCURR_TCURR  = @currency  AND
					B00_IT_TCURR.TCURR_GDATU <= EKBE_BUDAT
			ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
			) 

	WHERE EKBE_VGABE = '1'
	GROUP BY 
	
			  EKBE_GJAHR
		     ,EKBE_BELNR
		     ,EKBE_BUZEI
			 ,EKBE_EBELN
			 ,EKBE_EBELP
			 ,EKBE_ERNAM
		     ,EKBE_CPUDT
			 ,EKBE_BLDAT
			 ,EKBE_BUDAT
			 ,A_V_USERNAME.V_USERNAME_PERSNUMBER
			 ,A_V_USERNAME.V_USERNAME_NAME_LAST
             ,A_V_USERNAME.V_USERNAME_NAME_TEXT
             ,A_V_USERNAME.V_USERNAME_MC_NAMEFIR
             ,A_V_USERNAME.V_USERNAME_MC_NAMELAS
		     ,B00_USR02.USR02_USTYP   

 /*--Step 3
-- POs with immediate GRs:
  This step creates a unique list of purchase order line items, for which there is a goods receipt (EKBE_VGABE = 1)
  that is entered (EKBE_CPUDT) on or before the PO document date (EKKO_BEDAT)
--Rows are being removed due to the following filters (WHERE): 
		- Only keep rows for which there is a GR (EKBE_VGABE = 1)
		--with an input date (EKBE_CPUDT) <= PO document date (EKKO_BEDAT)
--Fields are being added from other SAP tables as mentioned IN JOIN clauses below
--Fields are being calculated as mentioned in SELECT clause below*/


EXEC SP_DROPTABLE 'B09_04_TT_IMM_GR'

	SELECT
		 A_EKKO.EKKO_MANDT				
		,A_EKKO.EKKO_EBELN
		,A_EKPO.EKPO_EBELP
		
		,COUNT(DISTINCT EKBE_BELNR)	AS ZF_NUM_IMM_GRS 
		,COUNT(*)					AS ZF_NUM_POS_WITH_IMM_GRS 
		,SUM(CASE WHEN EKBE_VGABE = '1' THEN (CASE WHEN (EKBE_SHKZG = 'S') THEN A_EKBE.EKBE_MENGE ELSE A_EKBE.EKBE_MENGE * -1 END) END) AS ZF_EKBE_MENGE_IMM_GR_S
		,SUM(CASE WHEN EKBE_VGABE = '1' THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) END) AS ZF_EKBE_DMBTR_IMM_GR_S_CUC
		,SUM(CASE WHEN EKBE_VGABE = '1' THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) ) END)  AS ZF_EKBE_DMBTR_IMM_GR_S
		,SUM(CASE WHEN EKBE_VGABE = '1' THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) END) AS ZF_EKBE_WRBTR_IMM_GR_S_CUC
		,SUM(CASE WHEN EKBE_VGABE = '1' THEN CONVERT(money,EKBE_WRBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_DOC.TCURX_FACTOR,1) ) END) AS ZF_EKBE_WRBTR_IMM_GR_S

	INTO B09_04_TT_IMM_GR

	-- Select from PO header
	FROM A_EKKO

	-- Add PO line item number
	INNER JOIN A_EKPO
	on A_EKKO.EKKO_EBELN = A_EKPO.EKPO_EBELN 

	-- Add goods receipt information from PO history
	LEFT JOIN A_EKBE
	on 	A_EKKO.EKKO_EBELN = A_EKBE.EKBE_EBELN AND
		A_EKPO.EKPO_EBELP = A_EKBE.EKBE_EBELP

	--Add house currency
	LEFT JOIN A_T001
	on A_EKKO.EKKO_BUKRS=A_T001.T001_BUKRS

	-- Add currency conversion factors for company code currency
	LEFT JOIN B00_TCURX TCURX_CC 
	on
	   A_T001.T001_WAERS = TCURX_CC.TCURX_CURRKEY   

	-- Add currency conversion factors for document currency
	LEFT JOIN B00_TCURX TCURX_DOC 
	on
	   A_EKBE.EKBE_WAERS = TCURX_DOC.TCURX_CURRKEY   

	-- Add currency factor from company currency to USD

	LEFT JOIN B00_IT_TCURF TCURF_CUC
	ON A_T001.T001_WAERS = TCURF_CUC.TCURF_FCURR
	AND TCURF_CUC.TCURF_TCURR  = @currency  
	AND TCURF_CUC.TCURF_GDATU = (
		SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
		FROM B00_IT_TCURF
		WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
				B00_IT_TCURF.TCURF_TCURR  = @currency  AND
				B00_IT_TCURF.TCURF_GDATU <= EKBE_BUDAT
		ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
		)
	-- Add exchange rate from company currency to USD
	LEFT JOIN B00_IT_TCURR TCURR_CUC
		ON A_T001.T001_WAERS = TCURR_CUC.TCURR_FCURR
		AND TCURR_CUC.TCURR_TCURR  = @currency  
		AND TCURR_CUC.TCURR_GDATU = (
			SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
			FROM B00_IT_TCURR
			WHERE A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
					B00_IT_TCURR.TCURR_TCURR  = @currency  AND
					B00_IT_TCURR.TCURR_GDATU <= EKBE_BUDAT
			ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
			) 

	-- Select only for GRs where GR entry date < = PO entry date
	WHERE
		A_EKBE.EKBE_vgabe = '1' AND
		CAST(datediff(d,A_EKKO.EKKO_BEDAT,A_EKBE.EKBE_CPUDT) AS INTEGER) <= 0

	-- Unique list per PO item
	GROUP BY
		 A_EKKO.EKKO_MANDT
		,A_EKKO.EKKO_EBELN
		,A_EKPO.EKPO_EBELP


--/*--Step 4
---- First invoice per PO:
---- This step identifies the user (EKBE_ERNAM), input date (EKBE_CPUDT) and document date (EKBE_BEDAT)
--   for the first invoice (EKBE_VGABE = 2, 3 or 4) per PO line item (EKPO_EBELN and EKPO_EBELP)
---- Rows are being removed due to the following filters (WHERE): 
--					Only event types for invoices are kept (EKBE_VGABE) = 2, 3 or 4
--					Only the first invoice per PO line item is kept
--*/


EXEC SP_DROPTABLE 'B09_05_TT_1ST_USR_INV'
EXEC SP_DROPTABLE 'B09_06_TT_1ST_INV_USR_DT_PER_PO'

   ;WITH B09_05_TT_SORT_USR_INV AS(
   SELECT 
      A_EKBE.EKBE_MANDT,
      A_EKBE.EKBE_EBELN,
      A_EKBE.EKBE_EBELP,
      A_EKBE.EKBE_ERNAM	AS ZF_EKBE_ERNAM_1ST_INV_USER,
	  A_EKBE.EKBE_CPUDT	AS ZF_EKBE_CPUDT_1ST_INV_DATE,
	  A_EKBE.EKBE_BUDAT	AS ZF_EKBE_BUDAT_1ST_INV_DATE,
	  A_EKBE.EKBE_BLDAT	AS ZF_EKBE_BLDAT_1ST_INV_DATE,   
      ROW_NUMBER() OVER (
			PARTITION BY A_EKBE.EKBE_MANDT,
						 A_EKBE.EKBE_EBELN,
						 A_EKBE.EKBE_EBELP

			ORDER BY     A_EKBE.EKBE_MANDT,
						 A_EKBE.EKBE_EBELN,
						 A_EKBE.EKBE_EBELP,
						 A_EKBE.EKBE_BLDAT,
						 A_EKBE.EKBE_CPUDT,
						 A_EKBE.EKBE_CPUTM) AS ZF_DUPE_COUNT
      FROM A_EKBE
	  WHERE EKBE_VGABE IN ('2', '3', '4')  )
   
   SELECT
		EKBE_MANDT,
		EKBE_EBELN,
		EKBE_EBELP,
        ZF_EKBE_ERNAM_1ST_INV_USER,
	    ZF_EKBE_CPUDT_1ST_INV_DATE,
	    ZF_EKBE_BUDAT_1ST_INV_DATE,
	    ZF_EKBE_BLDAT_1ST_INV_DATE   
   INTO B09_06_TT_1ST_INV_USR_DT_PER_PO
   FROM B09_05_TT_SORT_USR_INV
   WHERE ZF_DUPE_COUNT=1


/*--Step 5 
--  All invoices per PO:
    Rather than keeping information only on the first invoice per PO, create a mapping table that will give 
	all invoice users and dates per PO line item.
	This mapping table can be integrated into Qlik using APPLYMAP() function
  --Only records relating to invoices are kept
		EKBE_VGABE = '2', '3' or '4'
*/	

	EXEC SP_DROPTABLE 'B09_07_TT_MAPP_POS_INVS'

	SELECT 
		CONCAT(EKBE_EBELN, '|', EKBE_EBELP) AS ZF_MAPP_PO_INV
		,EKBE_EBELN
		,EKBE_EBELP
		,EKBE_GJAHR
		,EKBE_BELNR
		,EKBE_BUZEI
		,EKBE_GJAHR+'|'+EKBE_BELNR+'|'+EKBE_BUZEI AS ZF_EKBE_INV_REF
		,EKBE_ERNAM
		,EKBE_CPUDT
	    ,EKBE_BLDAT
		,EKBE_BUDAT
		
		,A_V_USERNAME.V_USERNAME_PERSNUMBER
        ,A_V_USERNAME.V_USERNAME_NAME_LAST
        ,A_V_USERNAME.V_USERNAME_NAME_TEXT
        ,A_V_USERNAME.V_USERNAME_MC_NAMEFIR
        ,A_V_USERNAME.V_USERNAME_MC_NAMELAS
		,B00_USR02.USR02_USTYP
		,CASE 
		 WHEN B00_USR02.USR02_USTYP = 'A' THEN 'Dialog' 
		 WHEN B00_USR02.USR02_USTYP = 'B' THEN 'System' 
		 WHEN B00_USR02.USR02_USTYP = 'C' THEN 'Communication (external RFC)' 
		 WHEN B00_USR02.USR02_USTYP = 'L' THEN 'Reference' 
		 WHEN B00_USR02.USR02_USTYP = 'S' THEN 'Service' 
		 ELSE 'Other' 
		END AS ZF_USR02_USTYP_DESC
		,SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4')  THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) END) AS ZF_EKBE_DMBTR_INV_S_CUC
	    ,SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4')  THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) ) END)	AS ZF_EKBE_DMBTR_INV_S

	INTO B09_07_TT_MAPP_POS_INVS
	FROM A_EKBE

	LEFT JOIN A_V_USERNAME
	   ON EKBE_ERNAM = A_V_USERNAME.V_USERNAME_BNAME
	   
	-- Add user information USR02 table
    LEFT JOIN B00_USR02
	   ON EKBE_ERNAM = B00_USR02.USR02_BNAME

	--Add the company code (so that we can add the house currency)
	LEFT JOIN A_EKKO 
	ON A_EKBE.EKBE_EBELN = A_EKKO.EKKO_EBELN

	--Add the house currency
	LEFT JOIN A_T001 
	ON A_EKKO.EKKO_BUKRS = A_T001.T001_BUKRS 

	-- Add currency conversion factors
	LEFT JOIN B00_TCURX TCURX_DOC 
	ON 
	   A_EKBE.EKBE_WAERS = TCURX_DOC.TCURX_CURRKEY   

	-- Add currency conversion factors for company code currency
	LEFT JOIN B00_TCURX TCURX_CC 
	ON
	   A_T001.T001_WAERS = TCURX_CC.TCURX_CURRKEY   

		-- Add currency factor from company currency to USD

	LEFT JOIN B00_IT_TCURF TCURF_CUC
	ON A_T001.T001_WAERS = TCURF_CUC.TCURF_FCURR
	AND TCURF_CUC.TCURF_TCURR  = @currency  
	AND TCURF_CUC.TCURF_GDATU = (
		SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
		FROM B00_IT_TCURF
		WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
				B00_IT_TCURF.TCURF_TCURR  = @currency  AND
				B00_IT_TCURF.TCURF_GDATU <= EKBE_BUDAT
		ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
		)
	-- Add exchange rate from company currency to USD
	LEFT JOIN B00_IT_TCURR TCURR_CUC
		ON A_T001.T001_WAERS = TCURR_CUC.TCURR_FCURR
		AND TCURR_CUC.TCURR_TCURR  = @currency  
		AND TCURR_CUC.TCURR_GDATU = (
			SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
			FROM B00_IT_TCURR
			WHERE A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
					B00_IT_TCURR.TCURR_TCURR  = @currency  AND
					B00_IT_TCURR.TCURR_GDATU <= EKBE_BUDAT
			ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
			) 



	WHERE
		A_EKBE.EKBE_vgabe IN ('2', '3', '4')

	GROUP BY EKBE_GJAHR
		     ,EKBE_BELNR
		     ,EKBE_BUZEI
			 ,EKBE_EBELN
			 ,EKBE_EBELP
			 ,EKBE_ERNAM
		     ,EKBE_CPUDT
			 ,EKBE_BLDAT
			 ,EKBE_BUDAT 
		     ,A_V_USERNAME.V_USERNAME_PERSNUMBER
             ,A_V_USERNAME.V_USERNAME_NAME_LAST
             ,A_V_USERNAME.V_USERNAME_NAME_TEXT
             ,A_V_USERNAME.V_USERNAME_MC_NAMEFIR
             ,A_V_USERNAME.V_USERNAME_MC_NAMELAS
		     ,B00_USR02.USR02_USTYP

/*--Step 6
--POs with immediate invoices:
  This step creates a unique list of purchase order line items, for which there is an inovice (EKBE_VGABE = 2,3,4)
  that is entered (EKBE_CPUDT) on or before the PO document date (EKKO_BEDAT)
--Rows are being removed due to the following filters (WHERE): 
		- Only keep rows for which there is an invoice (EKBE_VGABE = 2,3,4)
		--with an input date (EKBE_CPUDT) <= PO document date (EKKO_BEDAT)
--Fields are being added from other SAP tables as mentioned IN JOIN clauses below
--Fields are being calculated as mentioned in SELECT clause below*/


   EXEC SP_DROPTABLE 'B09_08_TT_IMM_INV'

	SELECT
		 A_EKKO.EKKO_MANDT
		,A_EKKO.EKKO_EBELN
		,A_EKPO.EKPO_EBELP
		
		,COUNT(DISTINCT EKBE_BELNR)	AS ZF_NUM_IMM_INVS
		,COUNT(*)				    AS ZF_NUM_POS_WITH_IMM_INVS
		,SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4')  THEN (CASE WHEN (EKBE_SHKZG = 'S') THEN A_EKBE.EKBE_MENGE ELSE A_EKBE.EKBE_MENGE * -1 END) END) AS ZF_EKBE_MENGE_IMM_INV_S
		,SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4')  THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) END) AS ZF_EKBE_DMBTR_IMM_INV_S_CUC
	    ,SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4')  THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) ) END)	AS ZF_EKBE_DMBTR_IMM_INV_S
		,SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4')  THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) END) AS ZF_EKBE_WRBTR_IMM_INV_S_CUC
		,SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4')  THEN CONVERT(money,EKBE_WRBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_DOC.TCURX_FACTOR,1) ) END)	AS ZF_EKBE_WRBTR_IMM_INV_S
	INTO B09_08_TT_IMM_INV

	
	FROM A_EKKO

	-- Add PO line item details
	INNER JOIN A_EKPO
	ON A_EKKO.EKKO_EBELN = A_EKPO.EKPO_EBELN 
	
	-- Add information concerning the invoice
	LEFT JOIN A_EKBE
	ON A_EKKO.EKKO_EBELN = A_EKBE.EKBE_EBELN AND
	   A_EKPO.EKPO_EBELP = A_EKBE.EKBE_EBELP 

	--Add company house currency in order to get currency conversion factor
	LEFT JOIN A_T001
	ON A_EKKO.EKKO_BUKRS=A_T001.T001_BUKRS

	-- Add currency conversion factors for company code currency
	LEFT JOIN B00_TCURX TCURX_CC 
	ON 
	   A_T001.T001_WAERS = TCURX_CC.TCURX_CURRKEY   

	-- Add currency conversion factors
	LEFT JOIN B00_TCURX TCURX_DOC 
	ON 
	   A_EKBE.EKBE_WAERS = TCURX_DOC.TCURX_CURRKEY   

	-- Add currency factor from company currency to USD

	LEFT JOIN B00_IT_TCURF TCURF_CUC
	ON A_T001.T001_WAERS = TCURF_CUC.TCURF_FCURR
	AND TCURF_CUC.TCURF_TCURR  = @currency  
	AND TCURF_CUC.TCURF_GDATU = (
		SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
		FROM B00_IT_TCURF
		WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
				B00_IT_TCURF.TCURF_TCURR  = @currency  AND
				B00_IT_TCURF.TCURF_GDATU <= EKBE_BUDAT
		ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
		)
	-- Add exchange rate from company currency to USD
	LEFT JOIN B00_IT_TCURR TCURR_CUC
		ON A_T001.T001_WAERS = TCURR_CUC.TCURR_FCURR
		AND TCURR_CUC.TCURR_TCURR  = @currency  
		AND TCURR_CUC.TCURR_GDATU = (
			SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
			FROM B00_IT_TCURR
			WHERE A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
					B00_IT_TCURR.TCURR_TCURR  = @currency  AND
					B00_IT_TCURR.TCURR_GDATU <= EKBE_BUDAT
			ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
			) 

	-- Select only invoices for which the input date < = PO document date
	WHERE
		A_EKBE.EKBE_vgabe IN ('2', '3', '4') AND
		datediff(d,A_EKKO.EKKO_BEDAT,A_EKBE.EKBE_BLDAT) <= 0

	GROUP BY 
		 A_EKKO.EKKO_MANDT
		,A_EKKO.EKKO_EBELN
		,A_EKPO.EKPO_EBELP

/*--Step 7
--Total value of GRs and invoices per PO:
--Create a unique list of purchase order numbers with the total values for invoices and goods receipts
--Fields are being calculated as mentioned in SELECT clause below*/

   EXEC SP_DROPTABLE 'B09_09_TT_PO_HIST_TOTALS'
	SELECT  
		A_EKBE.EKBE_MANDT,
		A_EKBE.EKBE_EBELN,
		A_EKBE.EKBE_EBELP,
		MAX(IIF(EKBE_VGABE IN ('2', '3', '4'), EKBE_WAERS, NULL)) ZF_INV_EKBE_WAERS,
		COUNT(CASE WHEN EKBE_VGABE IN ('2', '3', '4') THEN A_EKBE.EKBE_BELNR END)																																			AS ZF_EKBE_BELNR_NUM_INVS,
		MAX(CASE WHEN EKBE_VGABE IN ('2', '3', '4') THEN 'X' ELSE '' END)																																					AS ZF_EKBE_VGABE_IS_AN_INV,
		SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4') THEN (CASE WHEN (EKBE_SHKZG = 'S') THEN A_EKBE.EKBE_MENGE ELSE A_EKBE.EKBE_MENGE * -1 END) END)																			AS ZF_EKBE_MENGE_INV_S,
		SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4') THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) ) END)	                                    	AS ZF_EKBE_DMBTR_INV_S,
		SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4') THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) END)	AS ZF_EKBE_DMBTR_INV_S_CUC, --check here
		SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4') THEN CONVERT(money,EKBE_WRBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_DOC.TCURX_FACTOR,1) ) END) AS ZF_EKBE_WRBTR_INV_S,
		SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4') THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) END)	AS ZF_EKBE_WRBTR_INV_S_CUC,
		COUNT(CASE WHEN EKBE_VGABE = '1' THEN A_EKBE.EKBE_BELNR END)																																					AS ZF_EKBE_BELNR_NUM_GRS,
		MAX(IIF(EKBE_VGABE IN ('1'), EKBE_WAERS, NULL)) ZF_GR_EKBE_WAERS,
		MAX(CASE WHEN EKBE_VGABE = '1' THEN 'X' ELSE '' END)																																								AS ZF_EKBE_VGABE_IS_A_GR,
		SUM(CASE WHEN EKBE_VGABE = '1' THEN (CASE WHEN (EKBE_SHKZG = 'S') THEN A_EKBE.EKBE_MENGE ELSE A_EKBE.EKBE_MENGE * -1 END) END)																						AS ZF_EKBE_MENGE_GR_S,
		SUM(CASE WHEN EKBE_VGABE = '1' THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) ) END)				                                        	AS ZF_EKBE_DMBTR_GR_S,
		SUM(CASE WHEN EKBE_VGABE = '1' THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) END) AS ZF_EKBE_DMBTR_GR_S_CUC, -- to change
		SUM(CASE WHEN EKBE_VGABE = '1' THEN CONVERT(money,EKBE_WRBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_DOC.TCURX_FACTOR,1) ) END)														AS ZF_EKBE_WRBTR_GR_S,
		SUM(CASE WHEN EKBE_VGABE = '1' THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) END)	AS ZF_EKBE_WRBTR_GR_S_CUC -- to change
	INTO B09_09_TT_PO_HIST_TOTALS
	FROM A_EKBE 

	-- Add the company code
	LEFT JOIN A_EKPO
	ON A_EKPO.EKPO_EBELN = a_EKBE.EKBE_EBELN AND
	   A_EKPO.EKPO_EBELP = a_EKBE.EKBE_EBELP 

	--Add the house currency
	LEFT JOIN A_T001
	ON A_EKPO.EKPO_BUKRS=A_T001.T001_BUKRS

	-- Add currency factor for house currency
	LEFT JOIN B00_TCURX TCURX_CC 
	ON 
	   A_T001.T001_WAERS = TCURX_CC.TCURX_CURRKEY   

	-- Add currency factor for document currency
	LEFT JOIN B00_TCURX TCURX_DOC 
	ON 
	   A_EKBE.EKBE_WAERS = TCURX_DOC.TCURX_CURRKEY   
	
	-- Add currency factor from company currency to USD

	LEFT JOIN B00_IT_TCURF TCURF_CUC
	ON A_T001.T001_WAERS = TCURF_CUC.TCURF_FCURR
	AND TCURF_CUC.TCURF_TCURR  = @currency  
	AND TCURF_CUC.TCURF_GDATU = (
		SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
		FROM B00_IT_TCURF
		WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
				B00_IT_TCURF.TCURF_TCURR  = @currency  AND
				B00_IT_TCURF.TCURF_GDATU <= EKBE_BUDAT
		ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
		)
	-- Add exchange rate from company currency to USD
	LEFT JOIN B00_IT_TCURR TCURR_CUC
		ON A_T001.T001_WAERS = TCURR_CUC.TCURR_FCURR
		AND TCURR_CUC.TCURR_TCURR  = @currency  
		AND TCURR_CUC.TCURR_GDATU = (
			SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
			FROM B00_IT_TCURR
			WHERE A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
					B00_IT_TCURR.TCURR_TCURR  = @currency  AND
					B00_IT_TCURR.TCURR_GDATU <= EKBE_BUDAT
			ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
			) 

	GROUP BY
		A_EKBE.EKBE_MANDT,
		A_EKBE.EKBE_EBELN,
		A_EKBE.EKBE_EBELP,
		A_EKBE.EKBE_WAERS


/*--Step 8
-- First account assignment per PO:
-- Obtain the list of cost center and profit center account assignments per PO line item
--    Only the first account asssignment is kept 
--    For example, if the cost for a PO line item is split between two cost centers, only 
--    the information for the first cost center is kep here, because of the inner join on EKKN where EKKN_ZEKKN = 01
--Fields are being added from other SAP tables as mentioned IN JOIN clauses below
--Fields are being calculated as mentioned in SELECT clause below*/

   EXEC SP_DROPTABLE 'B09_10_TT_1ST_ACC_ASS_PER_PO'

	SELECT
		A_EKKN.EKKN_MANDT,
		A_EKKN.EKKN_EBELN,
		A_EKKN.EKKN_EBELP,
		COUNT (A_EKKN.EKKN_ZEKKN) AS ZF_EKKN_ZEKKN_NUM_ACCNT_ASSGS,
		EKKN_01.EKKN_AUFNR AS ZF_EKKN_AUFNR_1ST_ASSET_ORDER,
		EKKN_01.EKKN_VBELN AS ZF_EKKN_VBELN_1ST_SALES_ORDER,
		EKKN_01.EKKN_VBELP AS ZF_EKKN_VBELP_1ST_SALES_ORDER_LINE,
		EKKN_01.EKKN_KOKRS AS ZF_EKKN_KOKRS_1ST_CONTR_AREA,
		CASE 
			WHEN EKKN_01.EKKN_KOSTL ='' OR  EKKN_01.EKKN_KOSTL IS NULL THEN 'Not assigned'
			ELSE EKKN_01.EKKN_KOSTL 
		END  							AS ZF_EKKN_KOSTL_1ST_COST_CENT,
		CASE 
			WHEN B00_CSKT.CSKT_LTEXT ='' OR  B00_CSKT.CSKT_LTEXT IS NULL THEN 'Not assigned'
			ELSE B00_CSKT.CSKT_LTEXT 
		END								AS ZF_CSKT_LTEXT_1ST_COST_CENT_DESC,
		CASE 
			WHEN EKKN_01.EKKN_PRCTR ='' OR  EKKN_01.EKKN_PRCTR IS NULL THEN 'Not assigned'
			ELSE EKKN_01.EKKN_PRCTR 
		END  							AS ZF_EKKN_PRCTR_1ST_PROF_CENT,
		CASE 
			WHEN B00_CEPCT.CEPCT_MCTXT ='' OR  B00_CEPCT.CEPCT_MCTXT IS NULL THEN 'Not assigned'
			ELSE B00_CEPCT.CEPCT_MCTXT 
		END								AS ZF_CEPCT_MCTXT_1ST_PROF_CENTER_DESC,
		EKKN_01.EKKN_SAKTO AS ZF_EKKN_SAKTO_1ST_GL_ACC_NUM
	
	INTO B09_10_TT_1ST_ACC_ASS_PER_PO
   
	FROM A_EKKN

	-- Limit to the first account assignment per PO line item    
	INNER JOIN A_EKKN AS EKKN_01
	ON	A_EKKN.EKKN_EBELN = EKKN_01.EKKN_EBELN AND
	    A_EKKN.EKKN_EBELP = EKKN_01.EKKN_EBELP AND
	    EKKN_01.EKKN_ZEKKN = '01'

	-- Add the cost center descriptions	
	-- Use of row over partition to select the latest cost center descriptions that are valid. 
	-- This ensures there are no duplicate records in the cube as a result of multiple descriptions with a validity date greater than download date.
	LEFT JOIN (select CSKT_MANDT, CSKT_KOKRS, CSKT_KOSTL, CSKT_LTEXT, ROW_NUMBER() OVER (PARTITION BY CSKT_MANDT, CSKT_KOKRS, CSKT_KOSTL ORDER BY CSKT_DATBI DESC) AS RECORD FROM B00_CSKT) B00_CSKT 
	ON EKKN_01.EKKN_KOKRS = B00_CSKT.CSKT_KOKRS AND
	   EKKN_01.EKKN_KOSTL = B00_CSKT.CSKT_KOSTL AND
	   B00_CSKT.RECORD = 1

   	-- Add the profit center descriptions	
	-- Use of row over partition to select the latest profit center descriptions that are valid. 
	-- This ensures there are no duplicate records in the cube as a result of multiple descriptions with a validity date greater than download date.	
	LEFT JOIN (select CEPCT_MANDT, CEPCT_KOKRS, CEPCT_PRCTR, CEPCT_MCTXT, ROW_NUMBER() OVER (PARTITION BY CEPCT_MANDT, CEPCT_KOKRS, CEPCT_PRCTR ORDER BY CEPCT_DATBI DESC) AS RECORD FROM B00_CEPCT) B00_CEPCT 
	ON EKKN_01.EKKN_KOKRS = B00_CEPCT.CEPCT_KOKRS AND
	   EKKN_01.EKKN_PRCTR = B00_CEPCT.CEPCT_PRCTR AND
	   B00_CEPCT.RECORD = 1
    
	GROUP BY
		A_EKKN.EKKN_MANDT,
		A_EKKN.EKKN_EBELN,
		A_EKKN.EKKN_EBELP,
		EKKN_01.EKKN_AUFNR,
		EKKN_01.EKKN_VBELN,
		EKKN_01.EKKN_VBELP,
		EKKN_01.EKKN_KOKRS,
		EKKN_01.EKKN_KOSTL,
		B00_CSKT.CSKT_LTEXT,
		EKKN_01.EKKN_PRCTR,
		B00_CEPCT.CEPCT_MCTXT,
		EKKN_01.EKKN_PRCTR, 
		B00_CEPCT.CEPCT_MCTXT, 
	    EKKN_01.EKKN_SAKTO


/*--Step 9 
--  All account assignments per PO:
    Rather than keeping information only on the first account assignment per PO, create a mapping table that will give 
	all account assignments per PO line item.
	This mapping table can be integrated into Qlik using APPLYMAP() function
*/	


	EXEC SP_DROPTABLE 'B09_11_IT_MAP_PO_ACC_ASS'

	SELECT
		CONCAT(EKKN_EBELN, '|', EKKN_EBELP) AS ZF_MAPP_PO_INV,
		EKKN_AUFNR,
		EKKN_VBELN,
		EKKN_VBELP,
		EKKN_KOKRS,
		CASE 
			WHEN EKKN_KOSTL ='' OR  EKKN_KOSTL IS NULL THEN 'Not assigned'
			ELSE EKKN_KOSTL 
		END  							AS ZF_EKKN_KOSTL,
		CASE 
			WHEN B00_CSKT.CSKT_LTEXT ='' OR  B00_CSKT.CSKT_LTEXT IS NULL THEN 'Not assigned'
			ELSE B00_CSKT.CSKT_LTEXT 
		END								AS ZF_CSKT_LTEXT,
		CASE 
			WHEN EKKN_PRCTR ='' OR  EKKN_PRCTR IS NULL THEN 'Not assigned'
			ELSE EKKN_PRCTR 
		END  							AS ZF_EKKN_PRCTR,
		CASE 
			WHEN B00_CEPCT.CEPCT_MCTXT ='' OR  B00_CEPCT.CEPCT_MCTXT IS NULL THEN 'Not assigned'
			ELSE B00_CEPCT.CEPCT_MCTXT 
		END								AS ZF_CEPCT_MCTXT,
		EKKN_SAKTO
	
	INTO B09_11_IT_MAP_PO_ACC_ASS
   
	FROM A_EKKN

	-- Add the cost center descriptions	
	-- Use of row over partition to select the latest cost center descriptions that are valid. 
	-- This ensures there are no duplicate records in the cube as a result of multiple descriptions with a validity date greater than download date.
	LEFT JOIN (select CSKT_MANDT, CSKT_KOKRS, CSKT_KOSTL, CSKT_LTEXT, ROW_NUMBER() OVER (PARTITION BY CSKT_MANDT, CSKT_KOKRS, CSKT_KOSTL ORDER BY CSKT_DATBI DESC) AS RECORD FROM B00_CSKT) B00_CSKT 
	ON EKKN_KOKRS = B00_CSKT.CSKT_KOKRS AND
	   EKKN_KOSTL = B00_CSKT.CSKT_KOSTL AND
	   B00_CSKT.RECORD = 1

   	-- Add the profit center descriptions	
	-- Use of row over partition to select the latest profit center descriptions that are valid. 
	-- This ensures there are no duplicate records in the cube as a result of multiple descriptions with a validity date greater than download date.	
	LEFT JOIN (select CEPCT_MANDT, CEPCT_KOKRS, CEPCT_PRCTR, CEPCT_MCTXT, ROW_NUMBER() OVER (PARTITION BY CEPCT_MANDT, CEPCT_KOKRS, CEPCT_PRCTR ORDER BY CEPCT_DATBI DESC) AS RECORD FROM B00_CEPCT) B00_CEPCT 
	ON EKKN_KOKRS = B00_CEPCT.CEPCT_KOKRS AND
	   EKKN_PRCTR = B00_CEPCT.CEPCT_PRCTR AND
	   B00_CEPCT.RECORD = 1
    
	GROUP BY
		EKKN_MANDT,
		EKKN_EBELN,
		EKKN_EBELP,
		EKKN_AUFNR,
		EKKN_VBELN,
		EKKN_VBELP,
		EKKN_KOKRS,
		EKKN_KOSTL,
		B00_CSKT.CSKT_LTEXT,
		EKKN_PRCTR,
		B00_CEPCT.CEPCT_MCTXT,
		EKKN_PRCTR, 
		B00_CEPCT.CEPCT_MCTXT, 
	    EKKN_SAKTO

	
/*--Step 10
--  Unique list of exchange rate conversion factors:
	-- During the conversion from document currency to house currency, the following formula will be applied:
	     PO amount in document currency (EKPO_NETWR) * (PO exchange rate (EKKO_WKURS)* (exchange rate factor (TCURX_FACTOR)/Exchange rate conversion factor (TCURR_FFACT)))
-- Only the exchange rate conversion factors 'M' (average) and those that are effective (GDATU) are used
-- Only the exchange rates to (TCURR_TCURR) house currency (T001_WAERS) for company codes in scope are kept
-- $$ to be checked: why is the exchange rate table used for purchase orders but not for BSAK_WRBTR?
*/	

------check with Thuan whether below should be commented 
 --  EXEC SP_DROPTABLE 'B09_12_TT_TCURR_TO_HSE_CURR'

 --  SELECT 
	--	DISTINCT A_TCURR.TCURR_MANDT
	--	,A_T001.T001_WAERS
	--	,A_TCURR.TCURR_TCURR
	--	,A_TCURR.TCURR_FCURR
	--	,CASE WHEN TCURR_FFACT=0 THEN 1 ELSE TCURR_FFACT END AS ZF_TCURR_FFACT_TO_HSE_CURR 
	
	--INTO B09_12_TT_TCURR_TO_HSE_CURR
	
	--FROM A_TCURR 
	
	---- Add the house currency
	--INNER JOIN A_T001 
	--ON A_TCURR.TCURR_TCURR=A_T001.T001_WAERS 

	---- Limit to company codes in scope
	--INNER JOIN AM_SCOPE
	--ON A_T001.T001_BUKRS = SCOPE_CMPNY_CODE
	
	---- Exchange rate type M is average exchange rate type
	--WHERE 
	--	A_TCURR.TCURR_KURST='M' AND
	--	CONVERT(DATE, LEFT(99999999-A_TCURR.TCURR_GDATU,4) + Substring(Cast((99999999-A_TCURR.TCURR_GDATU) as NVARCHAR(8)),5,2) + RIGHT( 99999999-A_TCURR.TCURR_GDATU,2)) >= '1999-01-01' 
	 ------check with Thuan whether  should be commented 
	 	
/*--Step 11
-- Create a list of purchase orders, enriched with information from the above tables
--  The following hard-coded mapping is used:
--     B00_P163Y_PTEXT is taken to be the "spend type"
--     B00_T161T_BATXT is taken to be the "Po category"
--     Definition of spend categories is based on material number and procurement category levels
--       this might be different for other entities
-- Only include the following:
	-- Filter on POs that are updated in the period
	-- Filter on POs that are POs and not contracts, purchase requests, etc.
	-- Filter on flag for the purchase order returns an item
	-- Filter on flag for item category is 7
--Fields are being added from other SAP tables as mentioned IN JOIN clauses below
--Fields are being calculated as mentioned in SELECT clause below*/

-- Remove duplication on a_tcurf for currency that has multiple currency factors being applied
-- Using the exchange rate type m (the average) and tcurf_ffact 1 when multiple currency factor occurs
------check with Thuan whether below should be commented 
	--EXEC SP_DROPTABLE 'B09_12_TT_A_TCURF'
	--SELECT 
 --       TCURF_MANDT,
	--	TCURF_FCURR,
	--	TCURF_TCURR,
	--	CONVERT(DATE,CAST(99999999-TCURF_GDATU AS NVARCHAR), 112) TCURF_GDATU,
	--	TCURF_FFACT,
	--	TCURF_TFACT			
	--INTO B09_12_TT_A_TCURF
	--FROM A_TCURF
 --   WHERE TCURF_KURST = 'M' AND TCURF_GDATU < 90000000
	------check with Thuan whether  should be commented 
   EXEC SP_DROPTABLE 'B09_13_IT_PTP_POS'

	SELECT
		A_EKKO.EKKO_MANDT,
		A_EKPO.EKPO_BUKRS,
		A_EKKO.EKKO_BSART,
		AM_SCOPE.SCOPE_BUSINESS_DMN_L1,
		AM_SCOPE.SCOPE_BUSINESS_DMN_L2,
		--AM_FSMC.FSMC_ID,
  --      AM_FSMC.FSMC_NAME,
  --      AM_FSMC.FSMC_CNTRY_CODE,
  --      AM_FSMC.FSMC_REGION,
  --      AM_FSMC.FSMC_CONTROLLING_AREA,
  --      AM_FSMC.FSMC_COMPANY_CODE,
		A_T001.T001_BUTXT,
		A_EKKO.EKKO_BSTYP,
		CASE 
			WHEN A_EKKO.EKKO_BSTYP = 'A' THEN 'Request for Quotation'
			WHEN A_EKKO.EKKO_BSTYP = 'F' THEN 'Purchase Order'
			WHEN A_EKKO.EKKO_BSTYP = 'K' THEN 'Contract'
			WHEN A_EKKO.EKKO_BSTYP = 'L' THEN 'Scheduling Agreement'
			ELSE '' 
		END										AS ZF_EKKO_BSTYP_DESC,
		A_EKPO.EKPO_LOEKZ,
		A_EKKO.EKKO_LOEKZ,
		A_EKKO.EKKO_EBELN,
		A_EKPO.EKPO_EBELP,
		A_EKPO.EKPO_TXZ01,
		YEAR(A_EKKO.EKKO_AEDAT) ZF_EKKO_AEDAT_YEAR,
		
		-- Logic to create a fiscal year field in POs
		CAST(YEAR(A_EKKO.EKKO_AEDAT) + T009B_RELJR AS VARCHAR(4)) ZF_EKKO_AEDAT_FY,
		CAST(YEAR(A_EKKO.EKKO_AEDAT) AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(   MONTH(A_EKKO.EKKO_AEDAT) AS VARCHAR(2)) ,2)	AS ZF_EKKO_AEDAT_YEAR_MONTH,
		COALESCE (B08_06_IT_PTP_SMD.B08_LFA1_KTOKK,'')	AS LFA1_KTOKK,
		COALESCE (B08_06_IT_PTP_SMD.B08_T077Y_TXT30,'')	AS T077Y_TXT30,
		A_EKKO.EKKO_LIFNR,
		COALESCE (B08_06_IT_PTP_SMD.B08_LFA1_ERNAM,'')	AS LFA1_ERNAM,--User who create the supplier
		COALESCE (B08_06_IT_PTP_SMD.B08_LFA1_NAME1,'')	AS LFA1_NAME1,
		COALESCE (B08_06_IT_PTP_SMD.B08_LFA1_LAND1,'')	AS LFA1_LAND1,
		-- Country code in three digit ISO format, required for QlikSense maps
		COALESCE (AM_COUNTRY_MAPPING.COUNTRY_MAPPING_DESC,'')		AS COUNTRY_MAPPING_DESC,
		A_EKPO.EKPO_WERKS,
		A_T001W.T001W_NAME1,
		A_EKKO.EKKO_EKORG,
		A_T024E.T024E_EKOTX,
		A_EKKO.EKKO_RESWK,
		A_EKKO.EKKO_EKGRP,
		A_T024.T024_EKNAM,
		A_EKKO.EKKO_BEDAT,
		A_EKKO.EKKO_AEDAT,
		A_EKPO.EKPO_EBELN,
		A_EKPO.EKPO_MENGE,
		-- Posting date field created to have a common date field across cubes to filter on IN dAShboards. Uses PO creation date.
		A_EKKO.EKKO_AEDAT AS ZF_EKKO_AEDAT_Posting_DT, -- use the AEDAT date AS Posting date otherwise there is duplicated column. EKKO_AEDAT is used twice,
		-- Logic to create 3 character Posting month names.
		CONVERT(VARCHAR(3), DATENAME(mm, A_EKKO.EKKO_AEDAT)) AS ZF_EKKO_AEDAT_CY_MONTH,

		-- Logic to create quarters based on calendar year
		CAST(YEAR(A_EKKO.EKKO_AEDAT) + T009B_RELJR AS VARCHAR(4)) + '-' +
		 CASE 
			WHEN T009B_POPER IN (4,5,6) THEN 'Q2'
			WHEN T009B_POPER IN (7,8,9) THEN 'Q3'
			WHEN T009B_POPER IN (10,11,12) THEN 'Q4'
			ELSE 'Q1' 
		END ZF_EKKO_AEDAT_FQ, 

		-- Logic to create quarters based on fiscal year. Hard-coded to align with Sony fiscal year of March y/e
		CAST(YEAR(A_EKKO.EKKO_AEDAT) + T009B_RELJR AS VARCHAR(4)) + '-' +
		 CASE 
			WHEN T009B_POPER IN (4,5,6) THEN 'Q2'
			WHEN T009B_POPER IN (7,8,9) THEN 'Q3'
			WHEN T009B_POPER IN (10,11,12) THEN 'Q4'
			ELSE 'Q1' 
		END ZF_EKKO_AEDAT_FY_FQ,
		
		-- Logic to create Posting period. Hard-coded to align with Sony fiscal year of March y/e
		T009B_POPER ZF_EKKO_AEDAT_FY_PER, 
	
		A_EKKO.EKKO_ERNAM,
		COALESCE(A_V_USERNAME.V_Username_NAME_TEXT,'SRM user only') AS ZF_V_USERNAME_NAME_TEXT, 

		CASE 
		 WHEN B00_USR02.USR02_USTYP = 'A' THEN 'Dialog' 
		 WHEN B00_USR02.USR02_USTYP = 'B' THEN 'System' 
		 WHEN B00_USR02.USR02_USTYP = 'C' THEN 'Communication (external RFC)' 
		 WHEN B00_USR02.USR02_USTYP = 'L' THEN 'Reference' 
		 WHEN B00_USR02.USR02_USTYP = 'S' THEN 'Service' 
		 ELSE 'Other' 
		END AS ZF_USR02_USTYP_DESC,

		COALESCE (B00_USR02.USR02_USTYP,'')			AS USR02_USTYP,
			
		
		COALESCE(B09_02_TT_1ST_GR_USR_DT_PER_PO.ZF_EKBE_ERNAM_1ST_GR_USER,'')	AS ZF_EKBE_ERNAM_1ST_GR_USER,
		COALESCE(A_V_USERNAME_1ST_GR.V_USERNAME_NAME_TEXT,'')		AS ZF_V_USERNAME_NAME_TEXT_1ST_GR, 
		COALESCE (B00_USR02_1ST_GR.USR02_USTYP,'')			AS ZF_USR02_USTYP_1ST_GR,

		CASE 
		 WHEN B00_USR02_1ST_GR.USR02_USTYP = 'A' THEN 'Dialog' 
		 WHEN B00_USR02_1ST_GR.USR02_USTYP = 'B' THEN 'System' 
		 WHEN B00_USR02_1ST_GR.USR02_USTYP = 'C' THEN 'Communication (external RFC)' 
		 WHEN B00_USR02_1ST_GR.USR02_USTYP = 'L' THEN 'Reference' 
		 WHEN B00_USR02_1ST_GR.USR02_USTYP = 'S' THEN 'Service' 
		 ELSE 'Other' 
		END AS ZF_USR02_USTYP_DESC_GR,
	
		COALESCE(B09_06_TT_1ST_INV_USR_DT_PER_PO.ZF_EKBE_ERNAM_1ST_INV_USER,'') AS ZF_EKBE_ERNAM_1ST_INV_USER,
		COALESCE(A_V_USERNAME_1ST_INV.V_USERNAME_NAME_TEXT,'')		AS ZF_V_USERNAME_NAME_TEXT_1ST_INV, 
		COALESCE (B00_USR02_1ST_INV.USR02_USTYP,'')			AS ZF_USR02_USTYP_1ST_INV,

		CASE 
		 WHEN B00_USR02_1ST_INV.USR02_USTYP = 'A' THEN 'Dialog' 
		 WHEN B00_USR02_1ST_INV.USR02_USTYP = 'B' THEN 'System' 
		 WHEN B00_USR02_1ST_INV.USR02_USTYP = 'C' THEN 'Communication (external RFC)' 
		 WHEN B00_USR02_1ST_INV.USR02_USTYP = 'L' THEN 'Reference' 
		 WHEN B00_USR02_1ST_INV.USR02_USTYP = 'S' THEN 'Service' 
		 ELSE 'Other' 
		END AS ZF_USR02_USTYP_DESC_INV,
		
		COALESCE(A_EKPO.EKPO_MATNR,'')		AS EKPO_MATNR,
		COALESCE (B00_MAKT.MAKT_MAKTX,'')		AS MAKT_MAKTX,
		COALESCE(A_MARA.MARA_MTART,'')		AS MARA_MTART,  
		COALESCE(B00_T134T.T134T_MTBEZ,'')	AS T134T_MTBEZ,    
		COALESCE(A_EKPO.EKPO_MATKL, '')		AS EKPO_MATKL,
		COALESCE(B00_T023T.T023T_WGBEZ, '')	AS T023T_WGBEZ,
		--Add the DIVISION
		COALESCE(A_MARA.MARA_SPART,'') AS MARA_SPART,

		--hard-coded definition of spend type
		COALESCE (B00_T163Y.T163Y_PTEXT,'')		AS ZF_SPEND_TYPE,
		--hard-coded definition of PO category
		COALESCE (B00_T161T.T161T_BATXT,'')		AS ZF_PO_CATEGORY
		-- Logic for Sony spend categorisation. based on lINkINg material group to global procurement category structure
		,COALESCE(A_EKPO.EKPO_MATNR, '')	AS ZF_EKPO_MATNR_SPEND_CATEGORY
		,CASE 
			WHEN ( A_EKPO.EKPO_MATNR is null or A_EKPO.EKPO_MATNR='')  THEN 'Material details not available' 
		    WHEN  A_EKPO.EKPO_MATNR=AM_PROC_CAT.PROC_CAT_ID  THEN AM_PROC_CAT.PROC_CAT_L1
			ELSE 'Spend type not categorised IN AM_PROC_CAT'
		 END								AS ZF_EKPO_MATNR_SPEND_CATEGORY_LEVEL1

		 ,CASE 
			WHEN ( A_EKPO.EKPO_MATNR is null or A_EKPO.EKPO_MATNR='')  THEN 'Material details not available' 
			WHEN  A_EKPO.EKPO_MATNR=AM_PROC_CAT.PROC_CAT_ID  THEN AM_PROC_CAT.PROC_CAT_L2
			ELSE 'Spend type not categorised IN AM_PROC_CAT'
		 END								AS ZF_EKPO_MATNR_SPEND_CATEGORY_LEVEL2
		,CASE 
			WHEN ( A_EKPO.EKPO_MATNR is null or A_EKPO.EKPO_MATNR='')  THEN 'Material details not available' 
			WHEN  A_EKPO.EKPO_MATNR=AM_PROC_CAT.PROC_CAT_ID  THEN AM_PROC_CAT.PROC_CAT_L3
			ELSE 'Spend type not categorised IN AM_PROC_CAT'
		 END								AS ZF_EKPO_MATNR_SPEND_CATEGORY_LEVEL3,
	 
		-- PO values IN doc, cc and custom currency
		-- Doc value = SAP stored value
		-- CC value = converted with average exchange rate for period
		-- Custom value = converted with average exchange rate for period
		-- SAP does not carry the CC value for POs, so this hAS to be converted
		A_EKKO.EKKO_WAERS,
		CONVERT(money,A_EKPO.EKPO_NETPR * COALESCE(TCURX_DOC.TCURX_FACTOR,1))												AS ZF_EKPO_NETPR_TCURFA,
		A_EKPO.EKPO_NETPR,
		-- Blanket PO update logic from Jesper (27/04/2021).
		-- Case 1 : EKPO_MENGE = EKPO_NETWR * TCURX_FACTOR and EKPO_NETWR <> 0
		-- Case 2 : EKPO_NETPR * TCURX_FACTOR = 1  and EKPO_NETWR <> 0
		
		IIF(
		-- Case 1		
			(
				CONVERT(money,A_EKPO.EKPO_NETWR * COALESCE(TCURX_DOC.TCURX_FACTOR,1)) =  A_EKPO.EKPO_MENGE and A_EKPO.EKPO_NETWR <> 0
			)
			
        OR   
        -- Case 2  
			(
				CONVERT(money,A_EKPO.EKPO_NETPR * COALESCE(TCURX_DOC.TCURX_FACTOR,1)) = 1 and A_EKPO.EKPO_NETWR <> 0
			)		
		, 'Yes', 'No')    AS ZF_BLANKET_PO,	
		
		A_EKPO.EKPO_PEINH,
		A_EKPO.EKPO_NETWR,
		A_EKPO.EKPO_BRTWR,
		CONVERT(money,A_EKPO.EKPO_NETWR * COALESCE(TCURX_DOC.TCURX_FACTOR,1))												AS ZF_EKPO_NETWR_TCURFA,
	
		A_T001.T001_WAERS,																									
        -- For consistency, the conversion is done with the exchange rates table, as this is how it is done in the rest of the SQL scripts
	
		CONVERT(money,(A_EKPO.EKPO_NETWR * COALESCE(TCURX_DOC.TCURX_FACTOR,1) * A_EKKO.EKKO_WKURS * COALESCE(TCURF_COC.TCURF_TFACT,1))/COALESCE(TCURF_COC.TCURF_FFACT,1))	AS ZF_EKPO_NETWR_COC,  
		
		@currency																										AS AM_GLOBALS_CURRENCY, 

		CONVERT(money,(A_EKPO.EKPO_NETWR * COALESCE(TCURX_DOC.TCURX_FACTOR,1) * A_EKKO.EKKO_WKURS * COALESCE(TCURF_COC.TCURF_TFACT,1))/COALESCE(TCURF_COC.TCURF_FFACT,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1))	AS ZF_EKPO_NETWR_CUC,
		
		
		A_EKPO.EKPO_PSTYP,
		A_EKKO.EKKO_WKURS,
		COALESCE(A_EKPO.EKPO_RETPO,'')			AS EKPO_RETPO,
		
		-- account assignment info
		A_EKPO.EKPO_KNTTP,
		COALESCE (A_T163I.T163I_KNTTX,'')									 AS T163I_KNTTX,
		COALESCE(B09_10_TT_1ST_ACC_ASS_PER_PO.ZF_EKKN_AUFNR_1ST_ASSET_ORDER,'')	 AS ZF_EKKN_AUFNR_1ST_ASSET_ORDER,
		COALESCE(B09_10_TT_1ST_ACC_ASS_PER_PO.ZF_EKKN_KOKRS_1ST_CONTR_AREA,'')	 AS ZF_EKKN_KOKRS_1ST_CONTR_AREA,
		COALESCE(B09_10_TT_1ST_ACC_ASS_PER_PO.ZF_EKKN_KOSTL_1ST_COST_CENT,'')	 AS ZF_EKKN_KOKRS_1ST_COST_CENT,
		COALESCE(B09_10_TT_1ST_ACC_ASS_PER_PO.ZF_CSKT_LTEXT_1ST_COST_CENT_DESC,'')	 AS ZF_CSKT_LTEXT_1ST_COST_CENT_DESC,
		COALESCE(B09_10_TT_1ST_ACC_ASS_PER_PO.ZF_EKKN_PRCTR_1ST_PROF_CENT, 'Not assigned') AS ZF_EKKN_PRCTR_1ST_PROF_CENT,
		COALESCE(B09_10_TT_1ST_ACC_ASS_PER_PO.ZF_CEPCT_MCTXT_1ST_PROF_CENTER_DESC,'Not assigned') AS ZF_CEPCT_MCTXT_1ST_PROF_CENTER_DESC,
		COALESCE(B09_10_TT_1ST_ACC_ASS_PER_PO.ZF_EKKN_SAKTO_1ST_GL_ACC_NUM,'Not assigned')	 AS ZF_EKKN_SAKTO_1ST_GL_ACC_NUM,		
		COALESCE(B00_SKAT.SKAT_TXT50,'')										 AS SKAT_TXT50,
		
		-- Logic for checking if PO was raised on same date or after first invoice
		COALESCE(B09_06_TT_1ST_INV_USR_DT_PER_PO.ZF_EKBE_BLDAT_1ST_INV_DATE,'')															AS ZF_EKBE_BLDAT_1ST_INV_DATE,
		COALESCE(DATEDIFF(d,A_EKKO.EKKO_AEDAT,B09_06_TT_1ST_INV_USR_DT_PER_PO.ZF_EKBE_BLDAT_1ST_INV_DATE),'')								AS ZF_EKKO_AEDAT_MINUS_1ST_INV_DATE,    
		CASE WHEN DateDiff(d,A_EKKO.EKKO_AEDAT,B09_06_TT_1ST_INV_USR_DT_PER_PO.ZF_EKBE_BLDAT_1ST_INV_DATE) <= 0 THEN 'YES' ELSE 'NO' END    AS ZF_EKKO_AEDAT_PRIOR_1ST_INV_DATE,

		-- Logic for checking if PO was raised on same date or after first GR entry date
		COALESCE(B09_02_TT_1ST_GR_USR_DT_PER_PO.ZF_EKBE_CPUDT_1ST_GR_DATE,'')																		AS ZF_EKBE_CPUDT_1ST_GR_DATE,
		COALESCE(DATEDIFF(d,A_EKKO.EKKO_AEDAT,B09_02_TT_1ST_GR_USR_DT_PER_PO.ZF_EKBE_CPUDT_1ST_GR_DATE),'')										AS ZF_EKKO_AEDAT_MINUS_1ST_GR_DATE,    
		CASE WHEN DateDiff(d,A_EKKO.EKKO_AEDAT,B09_02_TT_1ST_GR_USR_DT_PER_PO.ZF_EKBE_CPUDT_1ST_GR_DATE) <= 0 THEN 'YES' ELSE 'NO' END				AS ZF_EKKO_AEDAT_PRIOR_1ST_GR_DATE,
		
		-- Total receipt indicator
	    A_EKPO.EKPO_WEPOS,
		-- Total GR values per PO
		COALESCE(B09_09_TT_PO_HIST_TOTALS_GR.ZF_EKBE_VGABE_IS_A_GR,'')		AS ZF_EKBE_VGABE_IS_A_GR,
		--COALESCE(B09_09_TT_PO_HIST_TOTALS.ZF_EKBE_MENGE_GR_S,0)			AS ZF_EKBE_MENGE_GR_S,
		--COALESCE(B09_09_TT_PO_HIST_TOTALS.ZF_EKBE_DMBTR_GR_S,0)			AS ZF_EKBE_DMBTR_GR_S,
		--COALESCE(B09_09_TT_PO_HIST_TOTALS.ZF_EKBE_DMBTR_GR_S_CUC,0)		AS ZF_EKBE_DMBTR_GR_S_CUC,
		--COALESCE(B09_09_TT_PO_HIST_TOTALS.ZF_EKBE_WRBTR_GR_S,0)			AS ZF_EKBE_WRBTR_GR_S,
		--COALESCE(B09_09_TT_PO_HIST_TOTALS.ZF_EKBE_WRBTR_GR_S_CUC,0)		AS ZF_EKBE_WRBTR_GR_S_CUC,
		--COALESCE(B09_09_TT_PO_HIST_TOTALS.ZF_EKBE_BELNR_NUM_GRS,0)		AS ZF_EKBE_BELNR_NUM_GRS,
		-- Immediate GR values per PO
		COALESCE(B09_04_TT_IMM_GR.ZF_EKBE_DMBTR_IMM_GR_S_CUC,0)			AS ZF_EKBE_DMBTR_IMM_GR_S_CUC,
		COALESCE(B09_04_TT_IMM_GR.ZF_EKBE_DMBTR_IMM_GR_S,0)				AS ZF_EKBE_DMBTR_IMM_GR_S,
		COALESCE(B09_04_TT_IMM_GR.ZF_EKBE_WRBTR_IMM_GR_S_CUC,0)			AS ZF_EKBE_WRBTR_IMM_GR_S_CUC,
		COALESCE(B09_04_TT_IMM_GR.ZF_EKBE_WRBTR_IMM_GR_S,0)				AS ZF_EKBE_WRBTR_IMM_GR_S,
		COALESCE(B09_04_TT_IMM_GR.ZF_EKBE_MENGE_IMM_GR_S,0)				AS ZF_EKBE_MENGE_IMM_GR_S,
		COALESCE(B09_04_TT_IMM_GR.ZF_NUM_IMM_GRS,0) 			        AS ZF_NUM_IMM_GRS,
		COALESCE(B09_04_TT_IMM_GR.ZF_NUM_POS_WITH_IMM_GRS,0)			AS ZF_NUM_POS_WITH_IMM_GRS,

		-- Partial invoice indicator
		A_EKPO.EKPO_REPOS,				
		-- Total invoice per PO
		--COALESCE(B09_09_TT_PO_HIST_TOTALS.ZF_EKBE_VGABE_IS_AN_INV,'')	AS ZF_EKBE_VGABE_IS_AN_INV,
		--COALESCE(B09_09_TT_PO_HIST_TOTALS.ZF_EKBE_MENGE_INV_S,0)		AS ZF_EKBE_MENGE_INV_S,
		--COALESCE(B09_09_TT_PO_HIST_TOTALS.ZF_EKBE_DMBTR_INV_S,0)		AS ZF_EKBE_DMBTR_INV_S,
		--COALESCE(B09_09_TT_PO_HIST_TOTALS.ZF_EKBE_DMBTR_INV_S_CUC,0)	AS ZF_EKBE_DMBTR_INV_S_CUC,
		--COALESCE(B09_09_TT_PO_HIST_TOTALS.ZF_EKBE_WRBTR_INV_S,0)		AS ZF_EKBE_WRBTR_INV_S,
		--COALESCE(B09_09_TT_PO_HIST_TOTALS.ZF_EKBE_WRBTR_INV_S_CUC,0)	AS ZF_EKBE_WRBTR_INV_S_CUC,
		--COALESCE(B09_09_TT_PO_HIST_TOTALS.ZF_EKBE_BELNR_NUM_INVS,0)		AS ZF_EKBE_BELNR_NUM_INVS,

		-- Immediate invoice values per PO
		COALESCE(B09_08_TT_IMM_INV.ZF_EKBE_DMBTR_IMM_INV_S,0)			AS ZF_EKBE_DMBTR_IMM_INV_S,
		COALESCE(B09_08_TT_IMM_INV.ZF_EKBE_DMBTR_IMM_INV_S_CUC,0)		AS ZF_EKBE_DMBTR_IMM_INV_S_CUC,
		COALESCE(B09_08_TT_IMM_INV.ZF_EKBE_WRBTR_IMM_INV_S,0)			AS ZF_EKBE_WRBTR_IMM_INV_S,
		COALESCE(B09_08_TT_IMM_INV.ZF_EKBE_WRBTR_IMM_INV_S_CUC,0)		AS ZF_EKBE_WRBTR_IMM_INV_S_CUC,
		COALESCE(B09_08_TT_IMM_INV.ZF_EKBE_MENGE_IMM_INV_S,0)			AS ZF_EKBE_MENGE_IMM_INV_S,
		COALESCE(B09_08_TT_IMM_INV.ZF_NUM_IMM_INVS,0)					AS ZF_NUM_IMM_INVS,
		COALESCE(B09_08_TT_IMM_INV.ZF_NUM_POS_WITH_IMM_INVS,0)			AS ZF_NUM_POS_WITH_IMM_INVS,
		
		-- Logic for checking if PO is deleted
		CASE 
			WHEN A_EKKO.EKKO_LOEKZ<>'' OR A_EKPO.EKPO_LOEKZ<>'' THEN 'X' ELSE ''
		END																 AS ZF_EKPO_LOEKZ_DEL,
		-- Logic for checking if a contract is valid
		CASE 
			WHEN A_EKKO.EKKO_BSTYP='K' AND (A_EKKO.EKKO_KDATB >= @date2 OR A_EKKO.EKKO_KDATE <= @date1) THEN 'X' ELSE '' 
		END																 AS ZF_EKPO_KDAT_CONT_INVALID,

		-- Description of document type
		CASE 
			WHEN A_EKKO.EKKO_LOEKZ <>'' OR A_EKPO.EKPO_LOEKZ<>'' THEN 'Deleted' 
			WHEN A_EKKO.EKKO_BSTYP='F' THEN 'Regular' 
			WHEN A_EKKO.EKKO_BSTYP='K' AND (A_EKKO.EKKO_KDATB >= @date2 OR A_EKKO.EKKO_KDATE <= @date1) THEN 'Contract invalid'
			WHEN A_EKKO.EKKO_BSTYP='K' THEN 'Contract' 
			WHEN A_EKKO.EKKO_BSTYP='A' THEN 'Quotation'
			ELSE 'Other' 
		END																 AS ZF_EKKO_BSTYP_LOEKZ_DESC,

		COALESCE(B08_06_IT_PTP_SMD.B08_INTERCO_TXT,'Unknown ? supplier record not available')		 AS INTERCO_TXT,   
		-- Indicator to show if the PO was created in the period
		CASE 
			WHEN A_EKKO.EKKO_AEDAT >= @date1 AND  A_EKKO.EKKO_AEDAT <= @date2 THEN 'X'
			ELSE '' 
		END																			 AS ZF_EKKO_AEDAT_CREATED_IN_PER,
		-- Indicator to show if the document date was in the period
		CASE 
			WHEN A_EKKO.EKKO_BEDAT >= @date1 AND A_EKKO.EKKO_BEDAT <= @date2	THEN 'X'
			ELSE '' 
		END																			 AS ZF_EKKO_BEDAT_DOC_DATE_IN_PER,
		-- Indicator to show if the PO has a goods receipt or an invoice
		CASE 
			WHEN   NOT(  A_EKKO.EKKO_LOEKZ='' AND A_EKPO.EKPO_LOEKZ='') THEN 'Deleted'  
			WHEN   A_EKKO.EKKO_BSTYP='K' THEN 'Contract' 
			WHEN   A_EKKO.EKKO_BSTYP='A' THEN 'Quotation'
			WHEN   A_EKKO.EKKO_BSTYP='F' THEN 
				CASE 
					WHEN B09_09_TT_PO_HIST_TOTALS_INV.ZF_EKBE_VGABE_IS_AN_INV='X' THEN
						CASE 
							WHEN B09_09_TT_PO_HIST_TOTALS_GR.ZF_EKBE_VGABE_IS_A_GR = 'X' 
							THEN 'Invoiced order with receipt' 
							ELSE 'Invoiced order without receipt'
						END
					ELSE 'Non-invoiced order'   
				END
			ELSE 'Other' 
		END																			 AS ZF_EKKO_EKBE_PO_WITH_GR_INV,

		-- Add flag to show if PO is equal to immediate GR value
  		CASE 
			WHEN ABS(CONVERT(money,A_EKPO.EKPO_NETWR * COALESCE(TCURX_DOC.TCURX_FACTOR,1)) - B09_04_TT_IMM_GR.ZF_EKBE_WRBTR_IMM_GR_S)<1 THEN 'YES' 
			ELSE 'NO' 
		END	AS ZF_EKPO_NETWR_EQ_IMM_GR_VAL,
		-- Add flag to show if invoice amount is under or over PO amount
		CASE  
			WHEN (CONVERT(money,A_EKPO.EKPO_NETWR * COALESCE(TCURX_DOC.TCURX_FACTOR,1)) - B09_09_TT_PO_HIST_TOTALS_INV.ZF_EKBE_WRBTR_INV_S) <= -1	THEN 'invoice value over PO value'
			WHEN ABS(CONVERT(money,A_EKPO.EKPO_NETWR * COALESCE(TCURX_DOC.TCURX_FACTOR,1)) - B09_09_TT_PO_HIST_TOTALS_INV.ZF_EKBE_WRBTR_INV_S) < 1	THEN 'invoice value equal PO value'
			WHEN (CONVERT(money,A_EKPO.EKPO_NETWR * COALESCE(TCURX_DOC.TCURX_FACTOR,1)) - B09_09_TT_PO_HIST_TOTALS_INV.ZF_EKBE_WRBTR_INV_S) >= 1		THEN 'invoice value under PO value'
			ELSE 'Not invoiced' 
		END	AS ZF_EKBE_WRBTR_UNDER_OVER_INV,
		---- Add flag to show if the immediate invoice is fully reversed
		--CASE 
		--	WHEN B09_08_TT_IMM_INV.ZF_NUM_IMM_INVS>0 AND B09_09_TT_PO_HIST_TOTALS.ZF_EKBE_WRBTR_INV_S = 0 THEN 'YES'
		--	ELSE 'NO'
		--END AS ZF_IMM_INV_FULLY_REV,
     COALESCE (B00_T163Y.T163Y_PTEXT,'')		AS T163Y_PTEXT,
	 COALESCE (B00_T161T.T161T_BATXT,'')		AS T161T_BATXT, 
	 -- Add the description of the asset order
	CASE
		WHEN COALESCE(B09_10_TT_1ST_ACC_ASS_PER_PO.ZF_EKKN_AUFNR_1ST_ASSET_ORDER,'') = '' 
			OR COALESCE(B09_10_TT_1ST_ACC_ASS_PER_PO.ZF_EKKN_AUFNR_1ST_ASSET_ORDER,'') = ' '
			THEN 'No internal order nr assigned'
		ELSE B09_10_TT_1ST_ACC_ASS_PER_PO.ZF_EKKN_AUFNR_1ST_ASSET_ORDER
	END AS ZF_EKKN_AUFNR_1ST_ASSET_ORDER_DESC,
	-- Add the username description
	CASE
		WHEN COALESCE(A_V_USERNAME_1ST_GR.V_USERNAME_NAME_TEXT,'') = '' 
			THEN 'No user description'
		ELSE A_V_USERNAME_1ST_GR.V_USERNAME_NAME_TEXT
	END AS ZF_V_USERNAME_NAME_DESC,

	CONCAT(A_EKPO.EKPO_EBELN, '|', A_EKPO.EKPO_EBELP) AS ZF_MAP_PO_GR_INV,
	TCURF_COC.*
	 
	INTO B09_13_IT_PTP_POS
    
	FROM A_EKKO

	-- Select from PO header/line items
	INNER JOIN A_EKPO
	ON A_EKKO.EKKO_EBELN = A_EKPO.EKPO_EBELN

    -- Limit to purchase orders found in the company codes in scope
	INNER JOIN AM_SCOPE
	ON A_EKKO.EKKO_BUKRS = AM_SCOPE.SCOPE_CMPNY_CODE
		
	-- Add supplier master data information
	LEFT JOIN B08_06_IT_PTP_SMD
		ON  A_EKKO.EKKO_LIFNR = B08_06_IT_PTP_SMD.B08_LFB1_LIFNR 
		AND A_EKPO.EKPO_BUKRS = B08_06_IT_PTP_SMD.B08_LFB1_BUKRS

    -- Add the house currency code
	LEFT JOIN A_T001
		ON  A_EKPO.EKPO_BUKRS = A_T001.T001_BUKRS

	-- Add the custom calendar date calculation
	/*Logic update by Vinh: 05-01-2021*/
	LEFT JOIN A_T009B
		ON T001_PERIV = T009B_PERIV AND
		   (CAST(YEAR(EKKO_AEDAT) AS INT) = CAST(T009B_BDATJ AS INT) OR T009B_BDATJ = '') AND
		   CAST(T009B_BUMON AS INT) = CAST(MONTH(EKKO_AEDAT) AS INT) AND
		   CAST(T009B_BUTAG AS INT) = (
				SELECT TOP 1 T009B_BUTAG
				FROM A_T009B
				WHERE T001_PERIV = T009B_PERIV AND
					  (CAST(YEAR(EKKO_AEDAT) AS INT) = CAST(T009B_BDATJ AS INT) OR T009B_BDATJ = '') AND
					  CAST(T009B_BUMON AS INT) = CAST(MONTH(EKKO_AEDAT) AS INT) AND
					  CAST(T009B_BUTAG AS INT) >= CAST(DAY(EKKO_AEDAT) AS INT)
				ORDER BY T009B_BUTAG ASC
		   )


	-- Add user account names
	LEFT JOIN A_V_USERNAME 
		ON  A_EKKO.EKKO_ERNAM = A_V_USERNAME.V_USERNAME_BNAME
	
	-- Add user account types
	LEFT JOIN B00_USR02
		ON  A_EKKO.EKKO_ERNAM = B00_USR02.USR02_BNAME
	
	-- Add descriptions of plant codes
	LEFT JOIN A_T001W
		ON A_EKPO.EKPO_WERKS = A_T001W.T001W_WERKS  
	
	-- Add descriptions of purchasing groups
	LEFT JOIN A_T024
		ON A_EKKO.EKKO_EKGRP = A_T024.T024_EKGRP  
	
	-- Add descriptions of purchasing organisations
	LEFT JOIN A_T024E
		ON A_EKKO.EKKO_EKORG = A_T024E.T024E_EKORG
	
	-- Add descriptions of purchasing types
	LEFT JOIN B00_T161T
		ON  A_EKKO.EKKO_BSART = B00_T161T.T161T_BSART 
		AND A_EKKO.EKKO_BSTYP = B00_T161T.T161T_BSTYP
	
	-- Add descriptions of item category texts
	LEFT JOIN B00_T163Y
		ON  A_EKPO.EKPO_PSTYP = B00_T163Y.T163Y_PSTYP
		
	-- Add the material master data for the division business segment
	LEFT JOIN A_MARA
		ON A_EKPO.EKPO_MATNR = A_MARA.MARA_MATNR 
	
	-- Add the material type descriptions
	LEFT JOIN B00_T134T
		ON A_MARA.MARA_MTART = B00_T134T.T134T_MTART
		
	-- Add the material descriptions
	LEFT JOIN B00_MAKT
		ON A_EKPO.EKPO_MATNR = B00_MAKT.MAKT_MATNR
	
	-- Add the material group descriptions
	LEFT JOIN B00_T023T
		ON A_EKPO.EKPO_MATKL = B00_T023T.T023T_MATKL
		
-- Add the currency conversion factor: for document currency
	LEFT JOIN B00_TCURX TCURX_DOC
		ON 
		 A_EKKO.EKKO_WAERS = TCURX_DOC.TCURX_CURRKEY

	-- Add currency factor from company currency to USD

	LEFT JOIN B00_IT_TCURF TCURF_CUC
	ON A_T001.T001_WAERS = TCURF_CUC.TCURF_FCURR
	AND TCURF_CUC.TCURF_TCURR  = @currency  
	AND TCURF_CUC.TCURF_GDATU = (
		SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
		FROM B00_IT_TCURF
		WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
				B00_IT_TCURF.TCURF_TCURR  = @currency  AND
				B00_IT_TCURF.TCURF_GDATU <= EKKO_BEDAT
		ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
		)
	-- Add exchange rate from company currency to USD
	LEFT JOIN B00_IT_TCURR TCURR_CUC
		ON A_T001.T001_WAERS = TCURR_CUC.TCURR_FCURR
		AND TCURR_CUC.TCURR_TCURR  = @currency  
		AND TCURR_CUC.TCURR_GDATU = (
			SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
			FROM B00_IT_TCURR
			WHERE A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
					B00_IT_TCURR.TCURR_TCURR  = @currency  AND
					B00_IT_TCURR.TCURR_GDATU <= EKKO_BEDAT
			ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
			) 

	-- Add currency factor from document currency to local currency

	LEFT JOIN B00_IT_TCURF TCURF_COC
	ON EKKO_WAERS = TCURF_COC.TCURF_FCURR
	AND TCURF_COC.TCURF_TCURR  = T001_WAERS  
	AND TCURF_COC.TCURF_GDATU = (
		SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
		FROM B00_IT_TCURF
		WHERE EKKO_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
				B00_IT_TCURF.TCURF_TCURR  = T001_WAERS  AND
				B00_IT_TCURF.TCURF_GDATU <= EKKO_BEDAT
		ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
		)
		------check with Thuan whether below should be commented 
	-- Add the currency conversion factor: for document currency
	--LEFT JOIN B00_TCURX TCURX_DOC
	--	ON 
	--	 A_EKKO.EKKO_WAERS = TCURX_DOC.TCURX_CURRKEY

	---- Add currency factor from Document currency to Local currency
	--LEFT JOIN B09_12_TT_A_TCURF A_TCURF_DOC_TO_LOCAL
	--	ON A_EKKO.EKKO_WAERS = A_TCURF_DOC_TO_LOCAL.TCURF_FCURR
	--	AND A_T001.T001_WAERS = A_TCURF_DOC_TO_LOCAL.TCURF_TCURR
 --       AND A_TCURF_DOC_TO_LOCAL.TCURF_GDATU = (
 --           SELECT TOP 1 B09_12_TT_A_TCURF.TCURF_GDATU
 --           FROM B09_12_TT_A_TCURF
 --           WHERE B09_12_TT_A_TCURF.TCURF_FCURR = EKKO_WAERS AND 
 --                 B09_12_TT_A_TCURF.TCURF_TCURR = T001_WAERS AND
 --                 B09_12_TT_A_TCURF.TCURF_GDATU <= EKKO_BEDAT
 --           ORDER BY B09_12_TT_A_TCURF.TCURF_GDATU DESC
 --       )
------check with Thuan whether above should be commented 
	-- Add the PO history totals
	--OUTER APPLY(SELECT TOP 1 * FROM B09_09_TT_PO_HIST_TOTALS WHERE
	--	A_EKKO.EKKO_EBELN = B09_09_TT_PO_HIST_TOTALS.EKBE_EBELN 
	--	AND	A_EKPO.EKPO_EBELP = B09_09_TT_PO_HIST_TOTALS.EKBE_EBELP) B09_09_TT_PO_HIST_TOTALS


	LEFT JOIN (
		SELECT A.EKBE_MANDT ,A.EKBE_EBELN, A.EKBE_EBELP, A.ZF_EKBE_VGABE_IS_AN_INV, SUM(A.ZF_EKBE_BELNR_NUM_INVS) ZF_EKBE_BELNR_NUM_INVS, SUM(A.ZF_EKBE_WRBTR_INV_S) ZF_EKBE_WRBTR_INV_S
		FROM B09_09_TT_PO_HIST_TOTALS AS A
		WHERE A.ZF_EKBE_VGABE_IS_AN_INV LIKE 'X'
		GROUP BY A.EKBE_MANDT, A.EKBE_EBELN, A.EKBE_EBELP, A.ZF_EKBE_VGABE_IS_AN_INV
	) AS B09_09_TT_PO_HIST_TOTALS_INV
	ON EKPO_EBELN = B09_09_TT_PO_HIST_TOTALS_INV.EKBE_EBELN
	AND EKPO_EBELP = B09_09_TT_PO_HIST_TOTALS_INV.EKBE_EBELP


	LEFT JOIN (
		SELECT A.EKBE_MANDT ,A.EKBE_EBELN, A.EKBE_EBELP, A.ZF_EKBE_VGABE_IS_A_GR, SUM(A.ZF_EKBE_BELNR_NUM_GRS) ZF_EKBE_BELNR_NUM_GRS, SUM(A.ZF_EKBE_WRBTR_GR_S) ZF_EKBE_WRBTR_GR_S
		FROM B09_09_TT_PO_HIST_TOTALS AS A
		WHERE A.ZF_EKBE_VGABE_IS_A_GR LIKE 'X'
		GROUP BY A.EKBE_MANDT, A.EKBE_EBELN, A.EKBE_EBELP, A.ZF_EKBE_VGABE_IS_A_GR
	) B09_09_TT_PO_HIST_TOTALS_GR
	ON EKPO_EBELN = B09_09_TT_PO_HIST_TOTALS_GR.EKBE_EBELN
	AND EKPO_EBELP = B09_09_TT_PO_HIST_TOTALS_GR.EKBE_EBELP

	-- Add the immediate GRs
	LEFT JOIN B09_04_TT_IMM_GR
		ON A_EKKO.EKKO_EBELN = B09_04_TT_IMM_GR.EKKO_EBELN
		AND A_EKPO.EKPO_EBELP = B09_04_TT_IMM_GR.EKPO_EBELP

	-- Add the immediate invoices
	LEFT JOIN B09_08_TT_IMM_INV
		ON A_EKKO.EKKO_EBELN = B09_08_TT_IMM_INV.EKKO_EBELN
		AND A_EKPO.EKPO_EBELP = B09_08_TT_IMM_INV.EKPO_EBELP
		
	--$$ To be replaced with mapping table First GR entry user
	LEFT JOIN B09_02_TT_1ST_GR_USR_DT_PER_PO 
		ON  A_EKKO.EKKO_EBELN = B09_02_TT_1ST_GR_USR_DT_PER_PO.EKBE_EBELN 
		AND	A_EKPO.EKPO_EBELP = B09_02_TT_1ST_GR_USR_DT_PER_PO.EKBE_EBELP

	--$$ To be replaced with mapping GR entry user name
	LEFT JOIN A_V_USERNAME A_V_USERNAME_1ST_GR
		ON  B09_02_TT_1ST_GR_USR_DT_PER_PO.ZF_EKBE_ERNAM_1ST_GR_USER= A_V_USERNAME_1ST_GR.V_USERNAME_BNAME
		
	--$$ To be replaced with mapping GR entry user details
	LEFT JOIN B00_USR02 B00_USR02_1ST_GR
		ON B09_02_TT_1ST_GR_USR_DT_PER_PO.ZF_EKBE_ERNAM_1ST_GR_USER= B00_USR02_1ST_GR.USR02_BNAME

	--$$ To be replaced with mapping table First IR entry user
	LEFT JOIN B09_06_TT_1ST_INV_USR_DT_PER_PO 
		ON  A_EKKO.EKKO_EBELN = B09_06_TT_1ST_INV_USR_DT_PER_PO.EKBE_EBELN 
		AND	A_EKPO.EKPO_EBELP = B09_06_TT_1ST_INV_USR_DT_PER_PO.EKBE_EBELP

	--$$ To be replaced with mapping IR entry user name
	LEFT JOIN A_V_USERNAME A_V_USERNAME_1ST_INV
		ON  B09_06_TT_1ST_INV_USR_DT_PER_PO.ZF_EKBE_ERNAM_1ST_INV_USER= A_V_USERNAME_1ST_INV.V_USERNAME_BNAME
		
	--$$ To be replaced with mapping IR entry user details
	LEFT JOIN B00_USR02 B00_USR02_1ST_INV 
		ON B09_06_TT_1ST_INV_USR_DT_PER_PO.ZF_EKBE_ERNAM_1ST_INV_USER= B00_USR02_1ST_INV.USR02_BNAME
		
	--$$ To be replaced with mapping table PO account assignment
	LEFT JOIN B09_10_TT_1ST_ACC_ASS_PER_PO
		  ON  A_EKKO.EKKO_EBELN = B09_10_TT_1ST_ACC_ASS_PER_PO.EKKN_EBELN 
		  AND A_EKPO.EKPO_EBELP = B09_10_TT_1ST_ACC_ASS_PER_PO.EKKN_EBELP      
		  
	--$$ To be replaced with mapping GL account description
	LEFT JOIN B00_SKAT
		ON B09_10_TT_1ST_ACC_ASS_PER_PO.ZF_EKKN_SAKTO_1ST_GL_ACC_NUM = B00_SKAT.SKAT_SAKNR 
		AND A_T001.T001_KTOPL = B00_SKAT.SKAT_KTOPL
	
	-- Add the procurement category structure
	LEFT JOIN AM_PROC_CAT
		ON A_EKPO.EKPO_MATNR = AM_PROC_CAT.PROC_CAT_ID
		AND A_EKPO.EKPO_MATKL = AM_PROC_CAT.PROC_CAT_MTRL_GRP_CODE 
			
	-- Add the ISO 3 letter Country code
	LEFT JOIN  AM_Country_MAPPING
		ON AM_Country_MAPPING.Country_MAPPING_CODE = B08_06_IT_PTP_SMD.B08_LFA1_LAND1
		
	--$$ To be added to mapping table Add account assignment category text description
	LEFT JOIN A_T163I 
		ON COALESCE(@language1,@language2) = A_T163I.T163I_SPRAS
		AND A_EKPO.EKPO_KNTTP=A_T163I.T163I_KNTTP
------check with Thuan whether below should be commented 
	---- Add the exchange rate factor for converting from document currency to house currency
	--LEFT JOIN B09_12_TT_TCURR_TO_HSE_CURR 
	--	ON A_EKKO.EKKO_WAERS = B09_12_TT_TCURR_TO_HSE_CURR.TCURR_FCURR
	--	AND A_T001.T001_WAERS = B09_12_TT_TCURR_TO_HSE_CURR.TCURR_TCURR
   
   -- Add the FSMC information
  --      LEFT JOIN AM_FSMC 
		--ON A_T001.T001_BUKRS = AM_FSMC.FSMC_COMPANY_CODE

	-- The following filters are not done until Qlik because the total population of POs is necessary for calculation 
	-- of type of invoice in B11:
			-- Filter on POs that are POs and not contracts, purchase requests, etc.
			-- Filter on flag for t	he purchase order returns an item
			-- Filter on flag for item category is 7
			--		WHERE	A_EKKO.EKKO_AEDAT	>= @date1 AND	A_EKKO.EKKO_AEDAT	<= @date2 
		    --   AND 	A_EKPO.EKPO_LOEKZ = ''
			--	AND     A_EKKO.EKKO_LOEKZ = ''
			--	AND		A_EKKO.EKKO_BSTYP	= 'F' 
			--    AND		COALESCE(A_EKPO.EKPO_RETPO,'') <> 'X'
			--	AND		A_EKPO.EKPO_PSTYP <> '7'             



	--Add immediate GR
	EXEC SP_REMOVE_TABLES 'B09_03_IT_MAPP_POS_GRS'
	SELECT B09_03_TT_MAPP_POS_GRS.*,
		CASE
			WHEN DATEDIFF(DAY,B09_13_IT_PTP_POS.EKKO_BEDAT,B09_03_TT_MAPP_POS_GRS.EKBE_CPUDT) <= 0 THEN 'YES'
			ELSE 'NO'
		END AS ZF_IMM_GR_TYPE
	INTO B09_03_IT_MAPP_POS_GRS
	FROM B09_03_TT_MAPP_POS_GRS
	LEFT JOIN 
	(
		SELECT *
		FROM B09_13_IT_PTP_POS
		WHERE	ZF_EKKO_BEDAT_DOC_DATE_IN_PER = 'X'
		AND 	ZF_EKPO_LOEKZ_DEL=''
		AND		EKKO_BSTYP	= 'F' 
		AND		EKPO_RETPO <> 'X'
		AND		EKPO_PSTYP <> '7'
	) AS B09_13_IT_PTP_POS
	ON B09_03_TT_MAPP_POS_GRS.ZF_MAPP_PO_GR = B09_13_IT_PTP_POS.ZF_MAP_PO_GR_INV

	

	--Add Retro-active PO type which is used in the PTP Retroactive sheet
	EXEC SP_DROPTABLE 'B09_07_IT_MAPP_POS_INVS'
	SELECT 
		B09_07_TT_MAPP_POS_INVS.*,
		CASE
			WHEN DATEDIFF(DAY,B09_13_IT_PTP_POS.EKKO_BEDAT,B09_07_TT_MAPP_POS_INVS.EKBE_BLDAT) <= 0 THEN 'YES'
			ELSE 'NO'
		END AS ZF_RETRO_ACTIVE_PO_TYPE
	INTO B09_07_IT_MAPP_POS_INVS
	FROM B09_07_TT_MAPP_POS_INVS
	LEFT JOIN 
	(
		SELECT *
		FROM B09_13_IT_PTP_POS
		WHERE	ZF_EKKO_BEDAT_DOC_DATE_IN_PER = 'X'
		AND 	ZF_EKPO_LOEKZ_DEL=''
		AND		EKKO_BSTYP	= 'F' 
		AND		EKPO_RETPO <> 'X'
		AND		EKPO_PSTYP <> '7'
	) AS B09_13_IT_PTP_POS
	ON B09_13_IT_PTP_POS.ZF_MAP_PO_GR_INV = B09_07_TT_MAPP_POS_INVS.ZF_MAPP_PO_INV


	/*Update time: 13-12-2019 by Hung and Vinh*/
	--Save all PO GR items seperately to a table instead of concat with PO cube before because sometime we have more than one currency in Good Receipts of PO
	EXEC SP_DROPTABLE 'B09_14_IT_GR_HIST'
	SELECT
		EKBE_EBELN + EKBE_EBELP PO_GR_key,
		ZF_GR_EKBE_WAERS,
		ZF_EKBE_BELNR_NUM_GRS,
		ZF_EKBE_VGABE_IS_A_GR,
		ZF_EKBE_MENGE_GR_S,
		ZF_EKBE_DMBTR_GR_S,
		ZF_EKBE_DMBTR_GR_S_CUC,
		ZF_EKBE_WRBTR_GR_S,
		ZF_EKBE_WRBTR_GR_S_CUC
	INTO B09_14_IT_GR_HIST
	FROM B09_09_TT_PO_HIST_TOTALS
	WHERE ZF_GR_EKBE_WAERS IS NOT NULL

	--Save all PO IR items seperately to a table instead of concat with PO cube before because sometime we have more than one currency in Good Receipts of PO
	EXEC SP_DROPTABLE 'B09_15_IT_INV_HIST'
	SELECT
		EKBE_EBELN + EKBE_EBELP PO_INV_key,
		ZF_INV_EKBE_WAERS,
		ZF_EKBE_BELNR_NUM_INVS,
		ZF_EKBE_VGABE_IS_AN_INV,
		ZF_EKBE_MENGE_INV_S,
		ZF_EKBE_DMBTR_INV_S,
		ZF_EKBE_DMBTR_INV_S_CUC,
		ZF_EKBE_WRBTR_INV_S,
		ZF_EKBE_WRBTR_INV_S_CUC
	INTO B09_15_IT_INV_HIST
	FROM B09_09_TT_PO_HIST_TOTALS
	WHERE ZF_INV_EKBE_WAERS IS NOT NULL

	/*Update time: 13-12-2019 by Vinh*/
	--Create a table  to build a currency dropdown in the PTP Plans and Acctual Sheet which will save exchange rate from Doc to the Other
	EXEC SP_REMOVE_TABLES 'B09_16_TT_PO_DOC_CURR'
	SELECT DISTINCT EKKO_WAERS PO_CURR_LIST, EKKO_WAERS PO_DOC_CURR, EKPO_EBELN + EKPO_EBELP ZF_EBELN_EBELP_KEY
	INTO B09_16_TT_PO_DOC_CURR
	FROM B09_13_IT_PTP_POS
	UNION
	SELECT DISTINCT ZF_GR_EKBE_WAERS, ZF_GR_EKBE_WAERS, PO_GR_key ZF_EBELN_EBELP_KEY
	FROM B09_14_IT_GR_HIST
	UNION
	SELECT DISTINCT ZF_INV_EKBE_WAERS, ZF_INV_EKBE_WAERS, PO_INV_key ZF_EBELN_EBELP_KEY
	FROM B09_15_IT_INV_HIST
	

	ALTER TABLE B09_16_TT_PO_DOC_CURR ALTER COLUMN PO_CURR_LIST NVARCHAR(20)
	ALTER TABLE B09_16_TT_PO_DOC_CURR ADD PO_EXCHANGE_RATE FLOAT

	EXEC SP_REMOVE_TABLES 'B09_17_TT_PO_DOC_CURR'
	SELECT DISTINCT T2.PO_CURR_LIST, T1.PO_DOC_CURR PO_DOC_CURR_FROM, T2.PO_DOC_CURR PO_DOC_CURR_TO, T1.PO_EXCHANGE_RATE, T2.ZF_EBELN_EBELP_KEY
	INTO B09_17_TT_PO_DOC_CURR
	FROM B09_16_TT_PO_DOC_CURR AS T1
	, B09_16_TT_PO_DOC_CURR AS T2


	INSERT INTO B09_17_TT_PO_DOC_CURR
	SELECT DISTINCT 'Document Currency', PO_DOC_CURR_FROM, PO_DOC_CURR_TO , PO_EXCHANGE_RATE, ZF_EBELN_EBELP_KEY
	FROM B09_17_TT_PO_DOC_CURR
	WHERE PO_DOC_CURR_FROM = PO_DOC_CURR_TO
	UNION
	SELECT DISTINCT 'Global Currency', PO_DOC_CURR_FROM, @CURRENCY, 1.0000000000, ZF_EBELN_EBELP_KEY
	FROM B09_17_TT_PO_DOC_CURR

	--Update exchange rate for this table
		UPDATE B09_17_TT_PO_DOC_CURR
		SET PO_EXCHANGE_RATE = ROUND((ISNULL(IIF(A_TCURR.TCURR_UKURS >= 0, A_TCURR.TCURR_UKURS, (1.0/A_TCURR.TCURR_UKURS)*-1), NULL) * ISNULL(A_TCURF.TCURF_TFACT, NULL))/ISNULL(A_TCURF.TCURF_FFACT, NULL), 10)
		FROM B09_17_TT_PO_DOC_CURR
		
		LEFT JOIN 
			(
			SELECT *
			FROM A_TCURF T1
			WHERE T1.TCURF_GDATU IN (SELECT MIN(T2.TCURF_GDATU) FROM A_TCURF T2 WHERE T1.TCURF_FCURR = T2.TCURF_FCURR AND T1.TCURF_TCURR = T2.TCURF_TCURR)
			) A_TCURF
			ON A_TCURF.TCURF_FCURR = PO_DOC_CURR_FROM
			AND A_TCURF.TCURF_TCURR = PO_DOC_CURR_TO
		LEFT JOIN
			(
			SELECT *
			FROM A_TCURR T1
			WHERE T1.TCURR_GDATU IN (SELECT MIN(T2.TCURR_GDATU) FROM A_TCURR T2 WHERE T1.TCURR_FCURR = T2.TCURR_FCURR AND T1.TCURR_TCURR = T2.TCURR_TCURR)
			)A_TCURR
			ON A_TCURR.TCURR_FCURR = PO_DOC_CURR_FROM
			AND A_TCURR.TCURR_TCURR = PO_DOC_CURR_TO

		--Update exhange for some rows still null because the first update is not found
		--Example: GBP to USD do not found but USD to GBP, so we will update exhange to 1/ratio
		UPDATE B09_17_TT_PO_DOC_CURR
		SET PO_EXCHANGE_RATE = 1.0/(ROUND((ISNULL(IIF(A_TCURR.TCURR_UKURS >= 0, A_TCURR.TCURR_UKURS, (1.0/A_TCURR.TCURR_UKURS)*-1), NULL) * ISNULL(A_TCURF.TCURF_TFACT, NULL))/ISNULL(A_TCURF.TCURF_FFACT, NULL), 10))
		FROM B09_17_TT_PO_DOC_CURR
		LEFT JOIN A_EKBE
		ON A_EKBE.EKBE_EBELN + A_EKBE.EKBE_EBELP = B09_17_TT_PO_DOC_CURR.ZF_EBELN_EBELP_KEY
		LEFT JOIN 
			(
			SELECT *
			FROM A_TCURF T1
			WHERE T1.TCURF_GDATU IN (SELECT MIN(T2.TCURF_GDATU) FROM A_TCURF T2 WHERE T1.TCURF_FCURR = T2.TCURF_FCURR AND T1.TCURF_TCURR = T2.TCURF_TCURR)
			) A_TCURF
			ON A_TCURF.TCURF_FCURR = PO_DOC_CURR_FROM
			AND A_TCURF.TCURF_TCURR = PO_DOC_CURR_TO
		LEFT JOIN
			(
			SELECT *
			FROM A_TCURR T1
			WHERE T1.TCURR_GDATU IN (SELECT MIN(T2.TCURR_GDATU) FROM A_TCURR T2 WHERE T1.TCURR_FCURR = T2.TCURR_FCURR AND T1.TCURR_TCURR = T2.TCURR_TCURR)
			)A_TCURR
			ON A_TCURR.TCURR_FCURR = PO_DOC_CURR_TO
			AND A_TCURR.TCURR_TCURR = PO_DOC_CURR_FROM
		WHERE PO_EXCHANGE_RATE IS NULL

		--Use AM_EXHANGE for the others rows still blank
		UPDATE B09_17_TT_PO_DOC_CURR
		SET PO_EXCHANGE_RATE = COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1)
		FROM B09_17_TT_PO_DOC_CURR
		LEFT JOIN A_EKBE 
		ON B09_17_TT_PO_DOC_CURR.ZF_EBELN_EBELP_KEY = A_EKBE.EKBE_EBELN + A_EKBE.EKBE_EBELP
		LEFT JOIN B00_IT_TCURF 
		ON PO_DOC_CURR_FROM = B00_IT_TCURF.TCURF_FCURR
		AND B00_IT_TCURF.TCURF_TCURR  = PO_DOC_CURR_TO  
		AND B00_IT_TCURF.TCURF_GDATU = (
			SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
			FROM B00_IT_TCURF
			WHERE PO_DOC_CURR_FROM = B00_IT_TCURF.TCURF_FCURR AND 
					B00_IT_TCURF.TCURF_TCURR  = PO_DOC_CURR_TO  AND
					B00_IT_TCURF.TCURF_GDATU <= A_EKBE.EKBE_BUDAT
			ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
			)
		LEFT JOIN B00_IT_TCURR 
			ON PO_DOC_CURR_FROM = B00_IT_TCURR.TCURR_FCURR
			AND B00_IT_TCURR.TCURR_TCURR  = PO_DOC_CURR_TO  
			AND B00_IT_TCURR.TCURR_GDATU = (
				SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
				FROM B00_IT_TCURR
				WHERE PO_DOC_CURR_FROM = B00_IT_TCURR.TCURR_FCURR AND 
						B00_IT_TCURR.TCURR_TCURR  = PO_DOC_CURR_TO  AND
						B00_IT_TCURR.TCURR_GDATU <= A_EKBE.EKBE_BUDAT
				ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
				) 


		WHERE PO_EXCHANGE_RATE IS NULL

		--Use existing currency rate to interpolate for missing ones
		
		DELETE B09_17_TT_PO_DOC_CURR WHERE PO_DOC_CURR_FROM = ''
		UPDATE B09_17_TT_PO_DOC_CURR
		SET PO_EXCHANGE_RATE = ROUND(TO_USD.PO_EXCHANGE_RATE*FROM_USD.PO_EXCHANGE_RATE, 10)
		FROM B09_17_TT_PO_DOC_CURR A
		OUTER APPLY 
			(
			SELECT MAX(B.PO_EXCHANGE_RATE) PO_EXCHANGE_RATE
			FROM B09_17_TT_PO_DOC_CURR B
			WHERE B.PO_DOC_CURR_TO = 'USD' AND A.PO_DOC_CURR_FROM = B.PO_DOC_CURR_FROM) TO_USD
		OUTER APPLY  
			(
			SELECT MAX(C.PO_EXCHANGE_RATE) PO_EXCHANGE_RATE
			FROM B09_17_TT_PO_DOC_CURR C
			WHERE C.PO_DOC_CURR_FROM = 'USD' AND A.PO_DOC_CURR_TO = C.PO_DOC_CURR_TO) FROM_USD


	-- Update exhange rate 1 to 1 when convert a currency to itself
	UPDATE B09_17_TT_PO_DOC_CURR
	SET PO_EXCHANGE_RATE = 1
	WHERE PO_DOC_CURR_FROM = PO_DOC_CURR_TO

	EXEC SP_REMOVE_TABLES 'B09_21_TT_PO_DOC_CURR_FINAL'
	SELECT DISTINCT PO_CURR_LIST, PO_DOC_CURR_FROM, PO_DOC_CURR_TO, PO_EXCHANGE_RATE
	INTO B09_21_TT_PO_DOC_CURR_FINAL
	FROM B09_17_TT_PO_DOC_CURR
	--Only list of company currency, document currency and custom currency for dropdown list so we need inner join with BKPFto get HWAER
	--Sperate Exchange rate to 3, PO, IR, GR
	EXEC SP_REMOVE_TABLES 'B09_18_IT_PO_DOC_CURR'
	SELECT DISTINCT B09_21_TT_PO_DOC_CURR_FINAL.*
	INTO B09_18_IT_PO_DOC_CURR
	FROM B09_21_TT_PO_DOC_CURR_FINAL
	LEFT JOIN A_BKPF
	ON A_BKPF.BKPF_HWAER = B09_21_TT_PO_DOC_CURR_FINAL.PO_CURR_LIST
	WHERE A_BKPF.BKPF_HWAER IS NOT NULL OR B09_21_TT_PO_DOC_CURR_FINAL.PO_CURR_LIST IN ('Document Currency', 'Global Currency')
	ORDER BY B09_21_TT_PO_DOC_CURR_FINAL.PO_CURR_LIST


	EXEC SP_REMOVE_TABLES 'B09_19_IT_IR_PO_DOC_CURR'
	SELECT DISTINCT B09_21_TT_PO_DOC_CURR_FINAL.*
	INTO B09_19_IT_IR_PO_DOC_CURR
	FROM B09_21_TT_PO_DOC_CURR_FINAL
	LEFT JOIN A_BKPF
	ON A_BKPF.BKPF_HWAER = B09_21_TT_PO_DOC_CURR_FINAL.PO_CURR_LIST
	WHERE A_BKPF.BKPF_HWAER IS NOT NULL OR B09_21_TT_PO_DOC_CURR_FINAL.PO_CURR_LIST IN ('Document Currency', 'Global Currency')
	ORDER BY B09_21_TT_PO_DOC_CURR_FINAL.PO_CURR_LIST

	EXEC SP_REMOVE_TABLES 'B09_20_IT_GR_PO_DOC_CURR'
	SELECT DISTINCT B09_21_TT_PO_DOC_CURR_FINAL.*
	INTO B09_20_IT_GR_PO_DOC_CURR
	FROM B09_21_TT_PO_DOC_CURR_FINAL
	LEFT JOIN A_BKPF
	ON A_BKPF.BKPF_HWAER = B09_21_TT_PO_DOC_CURR_FINAL.PO_CURR_LIST
	WHERE A_BKPF.BKPF_HWAER IS NOT NULL OR B09_21_TT_PO_DOC_CURR_FINAL.PO_CURR_LIST IN ('Document Currency', 'Global Currency')
	ORDER BY B09_21_TT_PO_DOC_CURR_FINAL.PO_CURR_LIST


/*Rename fields for Qlik*/

EXEC sp_RENAME_FIELD 'B09_', 'B09_13_IT_PTP_POS'
EXEC sp_RENAME_FIELD 'B09_', 'B09_14_IT_GR_HIST'
EXEC sp_RENAME_FIELD 'B09_', 'B09_15_IT_INV_HIST'
EXEC sp_RENAME_FIELD 'IR_', 'B09_19_IT_IR_PO_DOC_CURR'
EXEC sp_RENAME_FIELD 'GR_', 'B09_20_IT_GR_PO_DOC_CURR'
EXEC sp_RENAME_FIELD 'B09B_', 'B09_07_IT_MAPP_POS_INVS'
EXEC sp_RENAME_FIELD 'B09C_', 'B09_03_IT_MAPP_POS_GRS'

EXEC SP_REMOVE_TABLES '%_TT_%'

/*Delete all temporary tables*/
--EXEC SP_REMOVE_TABLES '%[_]TT[_]%'

/* log cube creation*/

INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','B09_13_IT_PTP_POS',(SELECT COUNT(*) FROM B09_13_IT_PTP_POS) 
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','B09_07_IT_MAPP_POS_INVS',(SELECT COUNT(*) FROM B09_07_IT_MAPP_POS_INVS) 
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','B09_03_IT_MAPP_POS_GRS',(SELECT COUNT(*) FROM B09_03_IT_MAPP_POS_GRS) 
GO
