USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[script_DC04_PTP_PO_HISTORY]
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


-- Step 1/ Compare values (USD) between table B10_02_IT_PTP_PO_HISTORY_NEW (use TCURR and TCURF) and table B10_02_IT_PTP_PO_HISTORY (use AM_EXCHNG)

EXEC SP_DROPTABLE 	'DC04_01_IT_PTP_PO_HISTORY'


SELECT A.B10_EKKO_EBELN,
	A.B10_EKPO_EBELP,
	A.B10_EKBE_BELNR,
	A.B10_EKBE_ZEKKN,
	A.B10_EKBE_VGABE,
	A.B10_EKBE_GJAHR, 
	A.B10_EKKO_BUKRS, 
	A.B10_EKBE_BUZEI,
	A_T001.T001_WAERS,
	MAX(A.B10_EKBE_BUDAT) AS B10_EKBE_BUDAT,
	MAX(B.B10_ZF_EKBE_WRBTR_S)	AS B10_ZF_EKBE_WRBTR_S,
	MAX(B.B10_ZF_EKBE_DMBTR_S) AS B10_ZF_EKBE_DMBTR_S,
	MAX(B.B10_ZF_EKBE_AREWR_S)	AS B10_ZF_EKBE_AREWR_S,
	MAX(B.B10_ZF_EKBE_DMBTR_S_CUC)	AS B10_ZF_EKBE_DMBTR_S_CUC_OLD,
	MAX(A.B10_ZF_EKBE_DMBTR_S_CUC)	AS B10_ZF_EKBE_DMBTR_S_CUC_NEW,
	MAX(ISNULL(AM_EXCHNG.EXCHNG_RATIO,1)) AS EXCH_RATE_DMBTR_OLD,
	MAX(COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) AS EXCH_RATE_DMBTR_NEW,
	MAX(B.B10_ZF_EKBE_AREWR_S_CUC) AS B10_ZF_EKBE_AREWR_S_CUC_OLD,
	MAX(A.B10_ZF_EKBE_AREWR_S_CUC) AS B10_ZF_EKBE_AREWR_S_CUC_NEW,
	MAX(ISNULL(AM_EXCHNG.EXCHNG_RATIO,1)) AS EXCH_RATE_AREWR_OLD,
	MAX(COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) AS EXCH_RATE_AREWR_NEW,
	MAX(B.B10_ZF_EKBE_WBRTR_S_CUC) 	AS B10_ZF_EKBE_WBRTR_S_CUC_OLD,
	MAX(A.B10_ZF_EKBE_WBRTR_S_CUC)	AS B10_ZF_EKBE_WBRTR_S_CUC_NEW,
	MAX(ISNULL(AM_EXCHNG_DOC.EXCHNG_RATIO,1)) AS EXCH_RATE_WBRTR_OLD,
	MAX(COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) AS EXCH_RATE_WBRTR_NEW

INTO DC04_01_IT_PTP_PO_HISTORY
FROM (SELECT B10_EKKO_EBELN,
            B10_EKPO_EBELP,
			B10_EKBE_BELNR,
			B10_EKBE_ZEKKN,
			B10_EKBE_VGABE,
			B10_EKBE_GJAHR, 
			B10_EKKO_BUKRS, 
			B10_EKBE_BUZEI,
			MAX(B10_EKBE_BUDAT) AS B10_EKBE_BUDAT,
			MAX(B10_EKBE_WAERS) AS B10_EKBE_WAERS,			
			SUM(B10_ZF_EKBE_DMBTR_S_CUC) AS B10_ZF_EKBE_DMBTR_S_CUC,
			SUM(B10_ZF_EKBE_AREWR_S_CUC) AS B10_ZF_EKBE_AREWR_S_CUC,
			SUM(B10_ZF_EKBE_WBRTR_S_CUC)  AS B10_ZF_EKBE_WBRTR_S_CUC
     FROM B10_02_IT_PTP_PO_HISTORY_NEW     
	 GROUP BY B10_EKKO_EBELN,
            B10_EKPO_EBELP,
			B10_EKBE_BELNR,
			B10_EKBE_ZEKKN,
			B10_EKBE_VGABE,
			B10_EKBE_GJAHR, 
			B10_EKKO_BUKRS, 
			B10_EKBE_BUZEI) A

INNER JOIN (SELECT B10_EKKO_EBELN,
					B10_EKPO_EBELP,
					B10_EKBE_BELNR,
					B10_EKBE_ZEKKN,
					B10_EKBE_VGABE,
					B10_EKBE_GJAHR, 
					B10_EKKO_BUKRS, 
					B10_EKBE_BUZEI,
					SUM(B10_ZF_EKBE_WRBTR_S) AS B10_ZF_EKBE_WRBTR_S,
					SUM(B10_ZF_EKBE_DMBTR_S) AS B10_ZF_EKBE_DMBTR_S,
					SUM(B10_ZF_EKBE_AREWR_S) AS B10_ZF_EKBE_AREWR_S,
					SUM(B10_ZF_EKBE_DMBTR_S_CUC) AS B10_ZF_EKBE_DMBTR_S_CUC,
					SUM(B10_ZF_EKBE_AREWR_S_CUC) AS B10_ZF_EKBE_AREWR_S_CUC,
					SUM(B10_ZF_EKBE_WBRTR_S_CUC) AS B10_ZF_EKBE_WBRTR_S_CUC
            FROM B10_02_IT_PTP_PO_HISTORY
		    GROUP BY  B10_EKKO_EBELN,
					B10_EKPO_EBELP,
					B10_EKBE_BELNR,
					B10_EKBE_ZEKKN,
					B10_EKBE_VGABE,
					B10_EKBE_GJAHR, 
					B10_EKKO_BUKRS, 
					B10_EKBE_BUZEI
			)B

	ON A.B10_EKKO_EBELN = B.B10_EKKO_EBELN
	AND A.B10_EKPO_EBELP = B.B10_EKPO_EBELP
	AND A.B10_EKBE_GJAHR = B.B10_EKBE_GJAHR
	AND A.B10_EKBE_BUZEI = B.B10_EKBE_BUZEI
	AND A.B10_EKKO_BUKRS = B.B10_EKKO_BUKRS
	AND A.B10_EKBE_BELNR = B.B10_EKBE_BELNR
	AND A.B10_EKBE_ZEKKN =  B.B10_EKBE_ZEKKN
	AND	A.B10_EKBE_VGABE = B.B10_EKBE_VGABE 
LEFT JOIN A_T001
	ON  A.B10_EKKO_BUKRS = A_T001.T001_BUKRS
	   
LEFT JOIN AM_EXCHNG 
	ON A_T001.T001_WAERS = AM_EXCHNG.EXCHNG_FROM
	AND AM_EXCHNG.EXCHNG_TO = @currency
  
LEFT JOIN AM_EXCHNG AM_EXCHNG_DOC  
	ON A.B10_EKBE_WAERS  = AM_EXCHNG_DOC.EXCHNG_FROM
	AND AM_EXCHNG_DOC.EXCHNG_TO = @currency		
LEFT JOIN B00_IT_TCURF TCURF_CUC
	ON A_T001.T001_WAERS = TCURF_CUC.TCURF_FCURR
	AND TCURF_CUC.TCURF_TCURR  = @currency  
	AND TCURF_CUC.TCURF_GDATU = (
	SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
	FROM B00_IT_TCURF
	WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
			B00_IT_TCURF.TCURF_TCURR  = @currency  AND
			B00_IT_TCURF.TCURF_GDATU <= A.B10_EKBE_BUDAT
	ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
	)

LEFT JOIN B00_IT_TCURR TCURR_CUC
	ON A_T001.T001_WAERS = TCURR_CUC.TCURR_FCURR
	AND TCURR_CUC.TCURR_TCURR  = @currency  
	AND TCURR_CUC.TCURR_GDATU = (
		SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
		FROM B00_IT_TCURR
		WHERE A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
				B00_IT_TCURR.TCURR_TCURR  = @currency  AND
				B00_IT_TCURR.TCURR_GDATU <= A.B10_EKBE_BUDAT
		ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
		) 

GROUP BY A.B10_EKKO_EBELN,
	A.B10_EKPO_EBELP,
	A.B10_EKBE_BELNR,
	A.B10_EKBE_ZEKKN,
	A.B10_EKBE_VGABE,
	A.B10_EKBE_GJAHR, 
	A.B10_EKKO_BUKRS, 
	A.B10_EKBE_BUZEI,
	A_T001.T001_WAERS

EXEC SP_UNNAME_FIELD 'B10_',DC04_01_IT_PTP_PO_HISTORY
EXEC SP_RENAME_FIELD 'DC04_01_',DC04_01_IT_PTP_PO_HISTORY

GO
