USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[script_DC01_FIN_TRIAL_BALANCE]
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


--Step 1/ Compare values (USD) between table B03_03_IT_FIN_TB_NEW (use TCURR and TCURF) and table B03_03_IT_FIN_TB (use AM_EXCHNG)
EXEC SP_DROPTABLE 	'DC01_01_IT_FIN_TB' 

SELECT 
	A.B03_TB_MONAT,
	A.B03_TB_RYEAR, 
	A.B03_T001_BUKRS, 
	A.B03_TB_RACCT, 
	T001_WAERS,
	MAX(A.B03_ZF_DATE) AS B03_ZF_DATE ,
	SUM(B.B03_ZF_TB_HSL_OPENING_BAL) AS B03_ZF_TB_HSL_OPENING_BAL,
	SUM(B.B03_ZF_TB_HSL_OPENING_BAL_CUC) AS B03_ZF_TB_HSL_OPENING_BAL_CUC_OLD,
	SUM(A.B03_ZF_TB_HSL_OPENING_BAL_CUC) AS B03_ZF_TB_HSL_OPENING_BAL_CUC_NEW,
	SUM(B.B03_ZF_TB_HSL_DEBIT_MOV) AS B03_TB_ZF_HSL_DEBIT_MOV,
	SUM(B.B03_ZF_TB_HSL_DEBIT_MOV_CUC) AS B03_ZF_TB_HSL_DEBIT_MOV_CUC_OLD,
	SUM(A.B03_ZF_TB_HSL_DEBIT_MOV_CUC) AS B03_ZF_TB_HSL_DEBIT_MOV_CUC_NEW,
	SUM(B.B03_ZF_TB_HSL_CREDIT_MOV) AS B03_ZF_TB_HSL_CREDIT_MOV,
	SUM(B.B03_ZF_TB_HSL_CREDIT_MOV_CUC) AS B03_ZF_TB_HSL_CREDIT_MOV_CUC_OLD,
	SUM(A.B03_ZF_TB_HSL_CREDIT_MOV_CUC) AS B03_ZF_TB_HSL_CREDIT_MOV_CUC_NEW,
	MAX(EXCHNG_RATIO) AS ZF_EXCH_RATE_OLD,
	MAX(COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1)) AS ZF_EXCH_RATE_NEW
INTO DC01_01_IT_FIN_TB
FROM 
	(
		SELECT DISTINCT 
			B03_TB_MONAT,
			B03_TB_RYEAR, 
			B03_T001_BUKRS, 
			B03_TB_RACCT,
			MAX(B03_ZF_DATE) AS B03_ZF_DATE ,
			SUM(B03_TB_HSL_OPENING_BAL_CUC) AS B03_ZF_TB_HSL_OPENING_BAL_CUC,
			SUM(B03_TB_HSL_DEBIT_MOV_CUC) AS B03_ZF_TB_HSL_DEBIT_MOV_CUC,
			SUM(B03_TB_HSL_CREDIT_MOV_CUC) AS B03_ZF_TB_HSL_CREDIT_MOV_CUC
		FROM B03_03_IT_FIN_TB_NEW 
		GROUP BY 
			B03_TB_MONAT,
			B03_TB_RYEAR, 
			B03_T001_BUKRS, 
			B03_TB_RACCT

	)A

INNER JOIN 
	(
			SELECT DISTINCT 
			B03_TB_MONAT,
			B03_TB_RYEAR, 
			B03_T001_BUKRS, 
			B03_TB_RACCT,
			SUM(B03_TB_HSL_OPENING_BAL) AS B03_ZF_TB_HSL_OPENING_BAL,
			SUM(B03_TB_HSL_OPENING_BAL_CUC) AS B03_ZF_TB_HSL_OPENING_BAL_CUC,
			SUM(B03_TB_HSL_DEBIT_MOV) AS B03_ZF_TB_HSL_DEBIT_MOV,
			SUM(B03_TB_HSL_DEBIT_MOV_CUC) AS B03_ZF_TB_HSL_DEBIT_MOV_CUC,
			SUM(B03_TB_HSL_CREDIT_MOV) AS B03_ZF_TB_HSL_CREDIT_MOV,
			SUM(B03_TB_HSL_CREDIT_MOV_CUC) AS B03_ZF_TB_HSL_CREDIT_MOV_CUC
		FROM B03_03_IT_FIN_TB
		GROUP BY 
			B03_TB_MONAT,
			B03_TB_RYEAR, 
			B03_T001_BUKRS, 
			B03_TB_RACCT

	)B
	ON A.B03_TB_MONAT = B.B03_TB_MONAT
	AND A.B03_T001_BUKRS = B.B03_T001_BUKRS
	AND A.B03_TB_RACCT = B.B03_TB_RACCT
	AND A.B03_TB_RYEAR = B.B03_TB_RYEAR

LEFT JOIN A_T001
	ON  A.B03_T001_BUKRS = A_T001.T001_BUKRS
	
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
				B00_IT_TCURF.TCURF_GDATU <= A.B03_ZF_DATE
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
				B00_IT_TCURR.TCURR_GDATU <= A.B03_ZF_DATE
		ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
		) 
GROUP BY A.B03_TB_MONAT,A.B03_TB_RYEAR, A.B03_T001_BUKRS, A.B03_TB_RACCT,A_T001.T001_WAERS


EXEC SP_UNNAME_FIELD 'B03_',DC01_01_IT_FIN_TB
EXEC SP_RENAME_FIELD 'DC01_01_',DC01_01_IT_FIN_TB
GO
