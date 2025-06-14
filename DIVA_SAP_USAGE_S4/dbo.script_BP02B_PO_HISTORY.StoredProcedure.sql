USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE        PROCEDURE [dbo].[script_BP02B_PO_HISTORY]
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

/*Change history comments*/

/*
	Title			:	BP02B: PO HISTORY
	  
	--------------------------------------------------------------
	Update history
	--------------------------------------------------------------
	Date		    | Who |	Description
	06/10/2022        KHOA   First version
*/



/*--Step 1
--Total value of GRs and invoices per PO:
--Create a unique list of purchase order numbers with the total values for invoices and goods receipts
--Fields are being calculated as mentioned in SELECT clause below
*/

EXEC SP_DROPTABLE 'BP02B_01_IT_PO_HIST_TOTALS'
	SELECT  
		A_EKBE.EKBE_EBELN,
		A_EKBE.EKBE_EBELP,
		MAX(IIF(EKBE_VGABE IN ('2', '3', '4'), EKBE_WAERS, NULL)) ZF_INV_EKBE_WAERS,
		MAX(IIF(EKBE_VGABE IN ('2', '3', '4'), T001_WAERS, NULL)) ZF_INV_T001_WAERS,
		COUNT(CASE WHEN EKBE_VGABE IN ('2', '3', '4') THEN A_EKBE.EKBE_BELNR END)																																			AS ZF_EKBE_BELNR_NUM_INVS,
		MAX(CASE WHEN EKBE_VGABE IN ('2', '3', '4') THEN 'X' ELSE '' END)																																					AS ZF_EKBE_VGABE_IS_AN_INV,
		SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4') THEN (CASE WHEN (EKBE_SHKZG = 'S') THEN A_EKBE.EKBE_MENGE ELSE A_EKBE.EKBE_MENGE * -1 END) END)																			AS ZF_EKBE_MENGE_INV_S,
		SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4') THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) ) END)	                                    	AS ZF_EKBE_DMBTR_INV_S,
		SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4') THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) END)	AS ZF_EKBE_DMBTR_INV_S_CUC, --check here
		SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4') THEN CONVERT(money,EKBE_WRBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_DOC.TCURX_FACTOR,1) ) END) AS ZF_EKBE_WRBTR_INV_S,
		SUM(CASE WHEN EKBE_VGABE IN ('2', '3', '4') THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) END)	AS ZF_EKBE_WRBTR_INV_S_CUC,
		COUNT(CASE WHEN EKBE_VGABE = '1' THEN A_EKBE.EKBE_BELNR END)																																					AS ZF_EKBE_BELNR_NUM_GRS,
		MAX(IIF(EKBE_VGABE IN ('1'), EKBE_WAERS, NULL)) ZF_GR_EKBE_WAERS,
		MAX(IIF(EKBE_VGABE IN ('1'), T001_WAERS, NULL)) ZF_GR_T001_WAERS,
		MAX(CASE WHEN EKBE_VGABE = '1' THEN 'X' ELSE '' END)																																								AS ZF_EKBE_VGABE_IS_A_GR,
		SUM(CASE WHEN EKBE_VGABE = '1' THEN (CASE WHEN (EKBE_SHKZG = 'S') THEN A_EKBE.EKBE_MENGE ELSE A_EKBE.EKBE_MENGE * -1 END) END)																						AS ZF_EKBE_MENGE_GR_S,
		SUM(CASE WHEN EKBE_VGABE = '1' THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) ) END)				                                        	AS ZF_EKBE_DMBTR_GR_S,
		SUM(CASE WHEN EKBE_VGABE = '1' THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) END) AS ZF_EKBE_DMBTR_GR_S_CUC, -- to change
		SUM(CASE WHEN EKBE_VGABE = '1' THEN CONVERT(money,EKBE_WRBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_DOC.TCURX_FACTOR,1) ) END)														AS ZF_EKBE_WRBTR_GR_S,
		SUM(CASE WHEN EKBE_VGABE = '1' THEN CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_FACTOR,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) END)	AS ZF_EKBE_WRBTR_GR_S_CUC -- to change
	INTO BP02B_01_IT_PO_HIST_TOTALS
    
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

   -- Add information from the scope table concerning the business domain   
	INNER JOIN AM_SCOPE                                         
		ON   EKPO_BUKRS = AM_SCOPE.SCOPE_CMPNY_CODE
	GROUP BY
		A_EKBE.EKBE_EBELN,
		A_EKBE.EKBE_EBELP


EXEC SP_REMOVE_TABLES '%BP02B_01_[_]TT[_]%'
EXEC SP_RENAME_FIELD 'BP02B_01_', 'BP02B_01_IT_PO_HIST_TOTALS'


GO
