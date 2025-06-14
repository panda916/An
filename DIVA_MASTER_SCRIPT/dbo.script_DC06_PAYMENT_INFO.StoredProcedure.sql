USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[script_DC06_PAYMENT_INFO]
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


--Step 1/ Compare values (USD) between table B12A_SS01_01_IT_REGUP_PAYMENT_INFO_NEW (use TCURR and TCURF) and table B12A_SS01_01_IT_REGUP_PAYMENT_INFO (use AM_EXCHNG)
EXEC SP_DROPTABLE 	'DC06_01_IT_REGUP_PAYMENT_INFO' 
SELECT 
	A.B12A_SS01_REGUP_BUKRS,
	A.B12A_SS01_REGUP_BELNR, 
	A.B12A_SS01_REGUP_GJAHR, 
	A.B12A_SS01_REGUP_BUZEI, 
	T001_WAERS,
	MAX(A.B12A_SS01_REGUP_BUDAT) AS B12A_SS01_REGUP_BUDAT,
	SUM(B.B12A_SS01_REGUP_DMBTR_S) AS B12A_SS01_REGUP_DMBTR_S,
	SUM(B.B12A_SS01_ZF_REGUP_DMBTR_S_CUC) AS B12A_SS01_ZF_REGUP_DMBTR_S_CUC_OLD,
	SUM(A.B12A_SS01_ZF_REGUP_DMBTR_S_CUC) AS B12A_SS01_ZF_REGUP_DMBTR_S_CUC_NEW,
	MAX(AM_EXCHNG.EXCHNG_RATIO*ISNULL(TCURX_COC.TCURX_factor,1)) AS EXCH_RATE_OLD,
	MAX(COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1)*ISNULL(TCURX_COC.TCURX_factor,1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1)) AS EXCH_RATE_NEW
INTO DC06_01_IT_REGUP_PAYMENT_INFO
FROM 
	(
		SELECT DISTINCT 
			B12A_SS01_REGUP_BUKRS,
			B12A_SS01_REGUP_BELNR,
			B12A_SS01_REGUP_GJAHR,
			B12A_SS01_REGUP_BUZEI,
			MAX(B12A_SS01_REGUP_BUDAT) AS B12A_SS01_REGUP_BUDAT,
			SUM(B12A_SS01_ZF_REGUP_DMBTR_S_CUC) AS B12A_SS01_ZF_REGUP_DMBTR_S_CUC
		FROM B12A_SS01_01_IT_REGUP_PAYMENT_INFO_NEW
		GROUP BY 			
			B12A_SS01_REGUP_BUKRS,
			B12A_SS01_REGUP_BELNR,
			B12A_SS01_REGUP_GJAHR,
			B12A_SS01_REGUP_BUZEI
	) A

INNER JOIN 
	(
			SELECT DISTINCT 
			B12A_SS01_REGUP_BUKRS,
			B12A_SS01_REGUP_BELNR,
			B12A_SS01_REGUP_GJAHR,
			B12A_SS01_REGUP_BUZEI,
			SUM(B12A_SS01_REGUP_DMBTR * (CASE WHEN (B12A_SS01_REGUP_SHKZG = 'S') THEN 1 ELSE -1 END)) AS B12A_SS01_REGUP_DMBTR_S,
			SUM(B12A_SS01_ZF_REGUP_DMBTR_S_CUC) AS B12A_SS01_ZF_REGUP_DMBTR_S_CUC
		FROM B12A_SS01_01_IT_REGUP_PAYMENT_INFO
		GROUP BY 			
			B12A_SS01_REGUP_BUKRS,
			B12A_SS01_REGUP_BELNR,
			B12A_SS01_REGUP_GJAHR,
			B12A_SS01_REGUP_BUZEI
		
	) B
	ON A.B12A_SS01_REGUP_BUKRS = B.B12A_SS01_REGUP_BUKRS
	AND A.B12A_SS01_REGUP_BELNR = B.B12A_SS01_REGUP_BELNR
	AND A.B12A_SS01_REGUP_GJAHR = B.B12A_SS01_REGUP_GJAHR
	AND A.B12A_SS01_REGUP_BUZEI = B.B12A_SS01_REGUP_BUZEI

LEFT JOIN A_T001
	ON  A.B12A_SS01_REGUP_BUKRS = A_T001.T001_BUKRS

    -- Add currency factor for house currency
LEFT JOIN B00_TCURX TCURX_COC
ON T001_WAERS = TCURX_COC.TCURX_CURRKEY
	
LEFT JOIN AM_EXCHNG
	ON  AM_EXCHNG.EXCHNG_FROM = A_T001.T001_WAERS
	AND AM_EXCHNG.EXCHNG_TO   =  @currency

LEFT JOIN B00_IT_TCURF
	ON A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR
	AND B00_IT_TCURF.TCURF_TCURR  = @currency  
	AND B00_IT_TCURF.TCURF_GDATU = (
		SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
		FROM B00_IT_TCURF
		WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
				B00_IT_TCURF.TCURF_TCURR  = @currency  AND
				B00_IT_TCURF.TCURF_GDATU <= A.B12A_SS01_REGUP_BUDAT
		ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
		)

LEFT JOIN B00_IT_TCURR
	ON A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR
	AND B00_IT_TCURR.TCURR_TCURR  = @currency  
	AND B00_IT_TCURR.TCURR_GDATU = (
		SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
		FROM B00_IT_TCURR
		WHERE A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
				B00_IT_TCURR.TCURR_TCURR  = @currency  AND
				B00_IT_TCURR.TCURR_GDATU <= A.B12A_SS01_REGUP_BUDAT
		ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
		) 

GROUP BY A.B12A_SS01_REGUP_BUKRS,
		 A.B12A_SS01_REGUP_BELNR, 
		 A.B12A_SS01_REGUP_GJAHR,
		 A.B12A_SS01_REGUP_BUZEI,
		 T001_WAERS


EXEC SP_UNNAME_FIELD 'B12A_SS01_',DC06_01_IT_REGUP_PAYMENT_INFO
EXEC SP_RENAME_FIELD 'DC06_01_',DC06_01_IT_REGUP_PAYMENT_INFO
GO
