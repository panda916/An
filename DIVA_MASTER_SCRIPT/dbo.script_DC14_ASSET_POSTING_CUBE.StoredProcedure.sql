USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[script_DC14_ASSET_POSTING_CUBE]
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

--Step 1/ Compare values (USD) between table B27_01_IT_ASSET_POSTING_NEW (use TCURR and TCURF) and table B27_01_IT_ASSET_POSTING (use AM_EXCHNG)
EXEC SP_DROPTABLE 	'DC14_01_IT_ASSET_POSTING' 

SELECT 
	A.B27_ANEK_BUKRS,
	A.B27_ANEK_ANLN1,
	A.B27_ANEK_ANLN2,
	A.B27_ANEK_GJAHR,
	A.B27_ANEK_LNRAN,
	A_T001.T001_WAERS,
	MAX(A.B27_ANEK_BZDAT) AS B27_ANEK_BZDAT,
	SUM(B.B27_ZF_ANEP_ANBTR) AS B27_ZF_ANEP_ANBTR,
	SUM(B.B27_ZF_ANEP_ANBTR_CUC) AS B27_ZF_ANEP_ANBTR_CUC_OLD,
	SUM(A.B27_ZF_ANEP_ANBTR_CUC) AS B27_ZF_ANEP_ANBTR_CUC_NEW,
	MAX(AM_EXCHNG.EXCHNG_RATIO) AS EXCH_RATE_OLD,
	MAX(COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) AS EXCH_RATE_OLD_NEW
INTO DC14_01_IT_ASSET_POSTING
FROM 
(
SELECT B27_ANEK_BUKRS,
	B27_ANEK_ANLN1,
	B27_ANEK_ANLN2,
	B27_ANEK_GJAHR,
	B27_ANEK_LNRAN,
	MAX(B27_ANEK_BZDAT) AS B27_ANEK_BZDAT,
	SUM(B27_ZF_ANEP_ANBTR) AS B27_ZF_ANEP_ANBTR,
	SUM(B27_ZF_ANEP_ANBTR_CUC) AS B27_ZF_ANEP_ANBTR_CUC
FROM B27_01_IT_ASSET_POSTING_NEW
GROUP BY B27_ANEK_BUKRS,
	B27_ANEK_ANLN1,
	B27_ANEK_ANLN2,
	B27_ANEK_GJAHR,
	B27_ANEK_LNRAN
) A
INNER JOIN
(
SELECT B27_ANEK_BUKRS,
	B27_ANEK_ANLN1,
	B27_ANEK_ANLN2,
	B27_ANEK_GJAHR,
	B27_ANEK_LNRAN,
	MAX(B27_ANEK_BZDAT) AS B27_ANEK_BZDAT,
	SUM(B27_ZF_ANEP_ANBTR) AS B27_ZF_ANEP_ANBTR,
	SUM(B27_ZF_ANEP_ANBTR_CUC) AS B27_ZF_ANEP_ANBTR_CUC
FROM B27_01_IT_ASSET_POSTING
GROUP BY B27_ANEK_BUKRS,
	B27_ANEK_ANLN1,
	B27_ANEK_ANLN2,
	B27_ANEK_GJAHR,
	B27_ANEK_LNRAN
) B
	ON 	A.B27_ANEK_BUKRS=B.B27_ANEK_BUKRS AND 
	A.B27_ANEK_ANLN1=B.B27_ANEK_ANLN1 AND 
	A.B27_ANEK_ANLN2=B.B27_ANEK_ANLN2 AND 
	A.B27_ANEK_GJAHR=B.B27_ANEK_GJAHR AND 
	A.B27_ANEK_LNRAN=B.B27_ANEK_LNRAN

--Add currency from T001
LEFT JOIN A_T001 ON A.B27_ANEK_BUKRS=A_T001.T001_BUKRS
----Add TCURX for T001_WAERS 
LEFT JOIN B00_TCURX 
	ON A_T001.T001_WAERS=B00_TCURX.TCURX_CURRKEY
--Add exchange currency
LEFT JOIN AM_EXCHNG ON AM_EXCHNG.EXCHNG_FROM=A_T001.T001_WAERS

-- Add currency factor from company currency to USD

LEFT JOIN B00_IT_TCURF TCURF_CUC
ON A_T001.T001_WAERS = TCURF_CUC.TCURF_FCURR
AND TCURF_CUC.TCURF_TCURR  = @CURRENCY  
AND TCURF_CUC.TCURF_GDATU = (
	SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
	FROM B00_IT_TCURF
	WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
			B00_IT_TCURF.TCURF_TCURR  = @CURRENCY  AND
			B00_IT_TCURF.TCURF_GDATU <= A.B27_ANEK_BZDAT
	ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
	)
-- Add exchange rate from company currency to USD
LEFT JOIN B00_IT_TCURR TCURR_CUC
	ON A_T001.T001_WAERS = TCURR_CUC.TCURR_FCURR
	AND TCURR_CUC.TCURR_TCURR  = @CURRENCY  
	AND TCURR_CUC.TCURR_GDATU = (
		SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
		FROM B00_IT_TCURR
		WHERE A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
				B00_IT_TCURR.TCURR_TCURR  = @CURRENCY  AND
				B00_IT_TCURR.TCURR_GDATU <= A.B27_ANEK_BZDAT
		ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
		) 
GROUP BY 
	A.B27_ANEK_BUKRS,
	A.B27_ANEK_ANLN1,
	A.B27_ANEK_ANLN2,
	A.B27_ANEK_GJAHR,
	A.B27_ANEK_LNRAN
	,A_T001.T001_WAERS

EXEC SP_UNNAME_FIELD 'B27_',DC14_01_IT_ASSET_POSTING
EXEC SP_RENAME_FIELD 'DC14_01_',DC14_01_IT_ASSET_POSTING
GO
