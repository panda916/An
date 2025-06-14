USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[script_DC13_PTP_GLOBAL_CUBES]
WITH EXECUTE AS CALLER
AS

--DYNAMIC_SCRIPT_START
/* Initiate the log */ 
----Create database log table if it does not exist
IF OBJECT_ID('LOG_SP_EXECUTION', 'U') IS NULL BEGIN CREATE TABLE [DBO].[LOG_SP_EXECUTION] ([DATABASE] NVARCHAR(MAX) NULL,[OBJECT] NVARCHAR(MAX) NULL,[OBJECT_TYPE] NVARCHAR(MAX) NULL,[USER] NVARCHAR(MAX) NULL,[DATE] DATE NULL,[TIME] TIME NULL,[DESCRIPTION] NVARCHAR(MAX) NULL,[TABLE] NVARCHAR(MAX),[ROWS] INT) END
 
--Log start of procedure
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Procedure started',NULL,NULL
 
/* Initialize parameters from globals table */
 
     DECLARE  
                      @CURRENCY NVARCHAR(MAX)                 = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'currency')
                     ,@DATE1 NVARCHAR(MAX)                           = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date1')
                     ,@DATE2 NVARCHAR(MAX)                           = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date2')
                     ,@DOWNLOADDATE NVARCHAR(MAX)             = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'downloaddate')
                     ,@DATEFORMAT VARCHAR(3)             = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'dateformat')
                     ,@EXCHANGERATETYPE NVARCHAR(MAX)  = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'exchangeratetype')
                     ,@LANGUAGE1 NVARCHAR(MAX)                = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language1')
                     ,@LANGUAGE2 NVARCHAR(MAX)                = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language2')
                     ,@YEAR NVARCHAR(MAX)                     = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'year')
                     ,@ID NVARCHAR(MAX)                       = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'id')
                     ,@LIMIT_RECORDS INT                    = CAST((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS') AS INT)
					 ,@ZV_SAME_QUARTER_BY_BLDAT NVARCHAR(MAX) = ISNULL((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'ZV_SAME_QUARTER_BY_BLDAT'), '')

--Khoi Comment
-- This cube is only have exchange rate update for RSEG-RBKP
--Instead of checking the whole flow, which is very heavy, only need to check RSEG-RBKP	 exechange rate

--Step 1/ Get the old ver of RSEG-RBKP

EXEC SP_DROPTABLE 'DC13_01_TT_RSEG_RBKP_OLD'

SELECT A_RSEG.*,A_RBKP.*,V_USERNAME_NAME_TEXT, T003T_LTEXT,EXCHNG_RATIO,TCURX_FACTOR,
CONVERT(MONEY,RSEG_WRBTR * COALESCE(TCURX_FACTOR,1) 
* iif(RSEG_SHKZG = 'H', -1, 1)) AS ZF_RSEG_WRBTR_S,
CONVERT(MONEY,RSEG_WRBTR * COALESCE(EXCHNG_RATIO,1) 
* COALESCE(TCURX_FACTOR,1) * iif(RSEG_SHKZG = 'H', -1, 1))	AS ZF_RSEG_WRBTR_S_CUC
INTO DC13_01_TT_RSEG_RBKP_OLD
FROM A_RSEG
JOIN A_RBKP ON RBKP_BELNR=RSEG_BELNR AND RBKP_GJAHR=RSEG_GJAHR
LEFT JOIN B00_TCURX AS TCURX_DOC  
	ON RBKP_WAERS = TCURX_DOC.TCURX_CURRKEY
LEFT JOIN AM_EXCHNG 
	ON RBKP_WAERS = AM_EXCHNG.EXCHNG_FROM
	AND AM_EXCHNG.EXCHNG_TO = @currency
LEFT JOIN A_V_USERNAME 
	ON RBKP_USNAM=V_USERNAME_BNAME
LEFT JOIN A_T003T 
	ON RBKP_BLART=T003T_BLART
WHERE RSEG_BUKRS IN (SELECT COMPANY_CODE FROM AM_COMPANY_CODE)


--Step 2/ Get the new ver of RSEG-RBKP

EXEC SP_DROPTABLE 'DC13_02_TT_RSEG_RBKP_NEW'

SELECT A.*,
CONVERT(MONEY,RSEG_WRBTR * COALESCE(TCURX_FACTOR,1) 
* iif(RSEG_SHKZG = 'H', -1, 1)) AS ZF_RSEG_WRBTR_S,
CONVERT(MONEY,RSEG_WRBTR * COALESCE(ZF_EXCHNG_RATIO,1) 
* COALESCE(TCURX_FACTOR,1) * iif(RSEG_SHKZG = 'H', -1, 1))	AS ZF_RSEG_WRBTR_S_CUC
INTO DC13_02_TT_RSEG_RBKP_NEW
FROM 
(
SELECT A_RSEG.*,A_RBKP.*,V_USERNAME_NAME_TEXT, T003T_LTEXT, 
RBKP_KURSF * COALESCE(TCURF_COC.TCURF_TFACT,1)/COALESCE(TCURF_COC.TCURF_FFACT,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1) AS ZF_EXCHNG_RATIO,
TCURX_FACTOR
FROM A_RSEG
JOIN A_RBKP ON RBKP_BELNR=RSEG_BELNR AND RBKP_GJAHR=RSEG_GJAHR
LEFT JOIN B00_TCURX AS TCURX_DOC  
	ON RBKP_WAERS = TCURX_DOC.TCURX_CURRKEY
LEFT JOIN A_T001 
ON RBKP_BUKRS = A_T001.T001_BUKRS 
-- Add currency factor from company currency to USD
LEFT JOIN B00_IT_TCURF TCURF_CUC
ON A_T001.T001_WAERS = TCURF_CUC.TCURF_FCURR
AND TCURF_CUC.TCURF_TCURR  = @currency  
AND TCURF_CUC.TCURF_GDATU = (
	SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
	FROM B00_IT_TCURF
	WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
			B00_IT_TCURF.TCURF_TCURR  = @currency  AND
			B00_IT_TCURF.TCURF_GDATU <= RBKP_BUDAT
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
				B00_IT_TCURR.TCURR_GDATU <= RBKP_BUDAT
		ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
	)

-- Add currency factor from document currency to local currency

LEFT JOIN B00_IT_TCURF TCURF_COC
ON RBKP_WAERS = TCURF_COC.TCURF_FCURR
AND TCURF_COC.TCURF_TCURR  = T001_WAERS  
AND TCURF_COC.TCURF_GDATU = (
	SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
	FROM B00_IT_TCURF
	WHERE RBKP_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
			B00_IT_TCURF.TCURF_TCURR  = T001_WAERS  AND
			B00_IT_TCURF.TCURF_GDATU <= RBKP_BUDAT
	ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
	)
	LEFT JOIN A_V_USERNAME 
	ON RBKP_USNAM=V_USERNAME_BNAME
LEFT JOIN A_T003T 
	ON RBKP_BLART=T003T_BLART
WHERE RSEG_BUKRS IN (SELECT COMPANY_CODE FROM AM_COMPANY_CODE)
) AS A

--Step 3 compare between old and new RSEG_RBKP
EXEC SP_DROPTABLE DC13_03_RT_COMPARE_RSEG_RBKP_OLD_NEW

SELECT
	A.RBKP_BELNR,
	A.RBKP_GJAHR,
	A_T001.T001_WAERS,
	MAX(A.RBKP_BUDAT) AS RBKP_BUDAT,
	SUM(A.ZF_RSEG_WRBTR_S_CUC) AS ZF_RSEG_WRBTR_S_CUC_OLD,
	SUM(B.ZF_RSEG_WRBTR_S_CUC) AS ZF_RSEG_WRBTR_S_CUC_NEW,
	SUM(A.ZF_RSEG_WRBTR_S) AS ZF_RSEG_WRBTR_S,
	MAX(EXCHNG_RATIO) AS ZF_EXCH_RATE_OLD,
	MAX(B.RBKP_KURSF * COALESCE(TCURF_COC.TCURF_TFACT,1)/COALESCE(TCURF_COC.TCURF_FFACT,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) AS ZF_EXCH_RATE_NEW
	INTO DC13_03_RT_COMPARE_RSEG_RBKP_OLD_NEW
FROM 
	(
		SELECT RBKP_BELNR,RBKP_GJAHR,
				SUM(ZF_RSEG_WRBTR_S_CUC) AS ZF_RSEG_WRBTR_S_CUC,
				SUM(ZF_RSEG_WRBTR_S) AS ZF_RSEG_WRBTR_S,
				MAX(RBKP_BUDAT) AS RBKP_BUDAT,
				MAX(RBKP_WAERS) AS RBKP_WAERS,
				MAX(RBKP_BUKRS) AS RBKP_BUKRS,
				MAX(RBKP_KURSF) AS RBKP_KURSF
		FROM DC13_01_TT_RSEG_RBKP_OLD
		WHERE RSEG_SHKZG='S'
		GROUP BY 
		RBKP_BELNR,RBKP_GJAHR
	) AS A
INNER JOIN 
	(
			SELECT RBKP_BELNR,RBKP_GJAHR,
				SUM(ZF_RSEG_WRBTR_S_CUC) AS ZF_RSEG_WRBTR_S_CUC,
				SUM(ZF_RSEG_WRBTR_S) AS ZF_RSEG_WRBTR_S,
				MAX(RBKP_BUDAT) AS RBKP_BUDAT,
				MAX(RBKP_WAERS) AS RBKP_WAERS,
				MAX(RBKP_BUKRS) AS RBKP_BUKRS,
				MAX(RBKP_KURSF) AS RBKP_KURSF
		FROM DC13_02_TT_RSEG_RBKP_NEW
		WHERE RSEG_SHKZG='S'
		GROUP BY 
		RBKP_BELNR,RBKP_GJAHR
	) AS B
ON A.RBKP_BELNR=B.RBKP_BELNR 
AND A.RBKP_GJAHR=B.RBKP_GJAHR
LEFT JOIN AM_EXCHNG 
	ON A.RBKP_WAERS = AM_EXCHNG.EXCHNG_FROM
	AND AM_EXCHNG.EXCHNG_TO = @currency
LEFT JOIN B00_TCURX AS TCURX_DOC  
	ON B.RBKP_WAERS = TCURX_DOC.TCURX_CURRKEY
LEFT JOIN A_T001 
ON B.RBKP_BUKRS = A_T001.T001_BUKRS 
-- Add currency factor from company currency to USD
LEFT JOIN B00_IT_TCURF TCURF_CUC
ON A_T001.T001_WAERS = TCURF_CUC.TCURF_FCURR
AND TCURF_CUC.TCURF_TCURR  = @currency  
AND TCURF_CUC.TCURF_GDATU = (
	SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
	FROM B00_IT_TCURF
	WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
			B00_IT_TCURF.TCURF_TCURR  = @currency  AND
			B00_IT_TCURF.TCURF_GDATU <= B.RBKP_BUDAT
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
				B00_IT_TCURR.TCURR_GDATU <= B.RBKP_BUDAT
		ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
	)

-- Add currency factor from document currency to local currency

LEFT JOIN B00_IT_TCURF TCURF_COC
ON B.RBKP_WAERS = TCURF_COC.TCURF_FCURR
AND TCURF_COC.TCURF_TCURR  = T001_WAERS  
AND TCURF_COC.TCURF_GDATU = (
	SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
	FROM B00_IT_TCURF
	WHERE B.RBKP_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
			B00_IT_TCURF.TCURF_TCURR  = T001_WAERS  AND
			B00_IT_TCURF.TCURF_GDATU <= B.RBKP_BUDAT
	ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
	)
GROUP BY 	A.RBKP_BELNR,
	A.RBKP_GJAHR,A_T001.T001_WAERS

--REname the field

EXEC SP_RENAME_FIELD 'DC13_03_','DC13_03_RT_COMPARE_RSEG_RBKP_OLD_NEW'
EXEC SP_DROPTABLE 'DC13_01_TT_RSEG_RBKP_OLD'
EXEC SP_DROPTABLE 'DC13_02_TT_RSEG_RBKP_NEW'


GO
