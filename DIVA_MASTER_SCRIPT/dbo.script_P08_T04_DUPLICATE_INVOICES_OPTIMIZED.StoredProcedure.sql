USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROCEDURE [dbo].[script_P08_T04_DUPLICATE_INVOICES_OPTIMIZED]
WITH EXECUTE AS CALLER
AS


--DYNAMIC_SCRIPT_START

BEGIN 
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
	Title			:	P08_T04: Duplicate invoices
	  
	--------------------------------------------------------------
	Update history
	--------------------------------------------------------------
	Date		    | Who |	Description
	27/03/2017		  HT	First creation
	28/03/2017		  CW    Review and standardization
*/

-- Step 1/ Filter invoices that get paid, don't have related documents and direct cancellation.
	EXEC sp_droptable 'P08_T04_01_TT_INV_PAID'
	SELECT * 
	INTO P08_T04_01_TT_INV_PAID
	FROM B11_06_IT_PTP_INV
	WHERE 
	--the reversal flag of paid invoice must be empty
	B11C_BSAIK_XRAGL <> 'X'
	--retrieve invoice with payment information only
	AND EXISTS(SELECT * FROM B11_08_IT_PTP_PAY 
				WHERE B11E_BSAIK_BUKRS = B11_06_IT_PTP_INV.B11C_BSAIK_BUKRS
						AND B11E_BSAIK_AUGBL = B11_06_IT_PTP_INV.B11C_BSAIK_AUGBL
						AND B11E_BSAIK_AUGDT = B11_06_IT_PTP_INV.B11C_BSAIK_AUGDT
				--filter out payment with direct cancellation
						AND NOT EXISTS(SELECT * FROM B11_09_IT_PTP_PAY_CANC
							WHERE B11F_BSAIK_BUKRS = B11E_BSAIK_BUKRS
							AND B11F_BSAIK_AUGBL = B11E_BSAIK_AUGBL
							AND B11F_BSAIK_AUGDT = B11E_BSAIK_AUGDT
							AND B11F_BSAIK_WRBTR = B11E_BSAIK_WRBTR))
	--filter out invoice with direct cancellation
	AND NOT EXISTS(SELECT * FROM B11_07_IT_PTP_INV_CANC WHERE B11D_BSAIK_BUKRS = B11_06_IT_PTP_INV.B11C_BSAIK_BUKRS
													AND B11D_BSAIK_AUGBL = B11_06_IT_PTP_INV.B11C_BSAIK_AUGBL
													AND B11D_BSAIK_AUGDT = B11_06_IT_PTP_INV.B11C_BSAIK_AUGDT
													AND B11D_BSAIK_WRBTR = B11C_BSAIK_WRBTR)
	AND NOT EXISTS(SELECT *
						FROM B11_04_IT_PTP_APA B WHERE B11C_BSAIK_LIFNR = B.B11B_BSAIK_LIFNR 
													AND B11C_ZF_BSAIK_DMBTR_S = B.B11B_ZF_BSAIK_DMBTR_S * -1 
													AND B11C_BSAIK_BUDAT <= B.B11B_BSAIK_BUDAT 
													AND B11C_BSAIK_BELNR <> B.B11B_BSAIK_BELNR)

-- Step 2/ find similar suppliers for invoices.

	EXEC SP_DROPTABLE 'P08_T04_01_TT_DUP_PAY_SIMILAR_SUPP'
	SELECT  DBO.GROUP_CONCAT_S(B11E_BSAIK_LIFNR, 1 ) GROUP_LIFNR_KEY, B11E_BSAIK_XBLNR, B11E_BSAIK_WRBTR 
	INTO P08_T04_01_TT_DUP_PAY_SIMILAR_SUPP
	FROM B11_08_IT_PTP_PAY
	WHERE EXISTS(SELECT TOP 1 1 FROM B11_08_IT_PTP_PAY B 
							WHERE B.B11E_BSAIK_XBLNR = B11_08_IT_PTP_PAY.B11E_BSAIK_XBLNR
									AND (ABS(B.B11E_BSAIK_WRBTR + B11_08_IT_PTP_PAY.B11E_BSAIK_WRBTR) < 1
									OR ABS(B.B11E_ZF_BSAIK_DMBTR_S_CUC + B11_08_IT_PTP_PAY.B11E_ZF_BSAIK_DMBTR_S_CUC) < 1)
									AND B.B11E_BSAIK_BUKRS + B.B11E_BSAIK_GJAHR + B.B11E_BSAIK_BELNR <> B11_08_IT_PTP_PAY.B11E_BSAIK_BUKRS + B11_08_IT_PTP_PAY.B11E_BSAIK_GJAHR + B11_08_IT_PTP_PAY.B11E_BSAIK_BELNR 
									AND DBO.[Similarity](B.B11E_LFA1_NAME1, B11_08_IT_PTP_PAY.B11E_LFA1_NAME1, 2, 0.85, 0) > 0.92
									AND DBO.[Similarity](B.B11E_LFA1_NAME1, B11_08_IT_PTP_PAY.B11E_LFA1_NAME1, 2, 0.85, 0) < 1
									AND B11E_BSAIK_XBLNR <> '')
	GROUP BY B11E_BSAIK_XBLNR, B11E_BSAIK_WRBTR 

-- Step 3/ Classify each duplicate invoice based on scenario
EXEC sp_droptable 'P08_T04_02_TT_DUP_INVS'
SELECT 
	'' ZF_CLASSIFICATION,
	ZF_PAYMENT_WRBTR_CONCAT,
	ZF_PAYMENT_TOTAL,
	ZF_PAYMENT_COUNT,
	ISNULL(ZF_INVOICE_DIRECT_CANCEL_FLAG, '') ZF_INVOICE_DIRECT_CANCEL_FLAG,
	IIF(P08_T04_01_TT_INV_PAID.B11C_BSAIK_WRBTR = ZF_PAYMENT_TOTAL AND ZF_PAYMENT_COUNT = 1, 'X', '') ZF_ONE_PAYMENT_MATCH_ONE_INVOICE_ONLY,
	ISNULL(ZF_PAYMENT_MATCH_FLAG, '') ZF_PAYMENT_MATCH_FLAG,
	ISNULL(ZF_PAYMENT_MATCH_COUNT, 0) ZF_PAYMENT_MATCH_COUNT,
	ZF_PAYMENT_DATE_VARIANT,
		CASE
		WHEN SCENARIO_1.B11C_BSAIK_BUKRS IS NOT NULL THEN 'Same vendor#, inv #, inv date & inv value' 
		WHEN SCENARIO_2.B11C_BSAIK_BUKRS IS NOT NULL THEN 'Same vendor#, inv # & inv date' 
		WHEN SCENARIO_3.B11C_BSAIK_BUKRS IS NOT NULL THEN 'Same vendor#, inv # & inv value' 
		WHEN SCENARIO_4.B11C_BSAIK_BUKRS IS NOT NULL THEN 'Same vendor#, inv date & inv value' 
		WHEN SCENARIO_5.B11C_BSAIK_BUKRS IS NOT NULL THEN 'Same invoice#, inv date & inv value' 
	END ZF_SCENARIO_DESC,
	CASE
		WHEN SCENARIO_1.B11C_BSAIK_BUKRS IS NOT NULL THEN SCENARIO_1.ZF_SCENARIO_ID
		WHEN SCENARIO_2.B11C_BSAIK_BUKRS IS NOT NULL THEN SCENARIO_2.ZF_SCENARIO_ID
		WHEN SCENARIO_3.B11C_BSAIK_BUKRS IS NOT NULL THEN SCENARIO_3.ZF_SCENARIO_ID
		WHEN SCENARIO_4.B11C_BSAIK_BUKRS IS NOT NULL THEN SCENARIO_4.ZF_SCENARIO_ID
		WHEN SCENARIO_5.B11C_BSAIK_BUKRS IS NOT NULL THEN SCENARIO_5.ZF_SCENARIO_ID
	END ZF_SCENARIO_ID,
	SCENARIO_6.SIMILAR_SUPPLIER_KEY,
	P08_T04_01_TT_INV_PAID.*
INTO P08_T04_02_TT_DUP_INVS
FROM P08_T04_01_TT_INV_PAID
	--SCENARIO 1 EXACT VENDOR#/INVOICE#/INVOICE DATE/INVOICE AMOUNT
	OUTER APPLY (SELECT TOP 1 B.B11C_BSAIK_BUKRS, CONCAT('LIFNR:', B.B11C_BSAIK_LIFNR, '_XBLNR:', B.B11C_BSAIK_XBLNR , '_BLDAT:', B.B11C_BSAIK_BLDAT, '_WRBTR:',B.B11C_BSAIK_WRBTR) AS ZF_SCENARIO_ID
						FROM P08_T04_01_TT_INV_PAID B WHERE P08_T04_01_TT_INV_PAID.B11C_BSAIK_LIFNR = B.B11C_BSAIK_LIFNR
												AND  P08_T04_01_TT_INV_PAID.B11C_BSAIK_XBLNR = B.B11C_BSAIK_XBLNR
												AND P08_T04_01_TT_INV_PAID.B11C_BSAIK_BLDAT = B.B11C_BSAIK_BLDAT
												AND P08_T04_01_TT_INV_PAID.B11C_BSAIK_WRBTR = B.B11C_BSAIK_WRBTR
												AND P08_T04_01_TT_INV_PAID.B11C_BSAIK_BUKRS + P08_T04_01_TT_INV_PAID.B11C_BSAIK_GJAHR + P08_T04_01_TT_INV_PAID.B11C_BSAIK_BELNR <> B.B11C_BSAIK_BUKRS + B.B11C_BSAIK_GJAHR + B.B11C_BSAIK_BELNR
												) SCENARIO_1
	-- SCENARIO 2 EXACT VENDOR#/INVOICE#/INVOICE DATE
	OUTER APPLY(SELECT TOP 1 B.B11C_BSAIK_BUKRS, CONCAT('LIFNR:', B.B11C_BSAIK_LIFNR, '_XBLNR:', B.B11C_BSAIK_XBLNR, '_BLDAT:', B.B11C_BSAIK_BLDAT, '_BELNR:', B.B11C_BSAIK_BELNR) AS ZF_SCENARIO_ID
							FROM P08_T04_01_TT_INV_PAID B 
							WHERE P08_T04_01_TT_INV_PAID.B11C_BSAIK_LIFNR = B.B11C_BSAIK_LIFNR
														AND B.B11C_BSAIK_XBLNR = P08_T04_01_TT_INV_PAID.B11C_BSAIK_XBLNR
														AND B.B11C_BSAIK_BLDAT = P08_T04_01_TT_INV_PAID.B11C_BSAIK_BLDAT
														AND P08_T04_01_TT_INV_PAID.B11C_BSAIK_BUKRS + P08_T04_01_TT_INV_PAID.B11C_BSAIK_GJAHR + P08_T04_01_TT_INV_PAID.B11C_BSAIK_BELNR <> B.B11C_BSAIK_BUKRS + B.B11C_BSAIK_GJAHR + B.B11C_BSAIK_BELNR
														) SCENARIO_2
	-- SCENARIO 3 EXACT VENDOR#/INVOICE#/INVOICE AMOUNT
	OUTER APPLY(SELECT TOP 1 B.B11C_BSAIK_BUKRS, CONCAT('LIFNR:', B.B11C_BSAIK_LIFNR, '_XBLNR:', B.B11C_BSAIK_XBLNR, '_WRBTR:', B.B11C_BSAIK_WRBTR) AS ZF_SCENARIO_ID
						FROM P08_T04_01_TT_INV_PAID B 
						WHERE P08_T04_01_TT_INV_PAID.B11C_BSAIK_LIFNR = B.B11C_BSAIK_LIFNR
													AND B.B11C_BSAIK_XBLNR = P08_T04_01_TT_INV_PAID.B11C_BSAIK_XBLNR
													AND B.B11C_BSAIK_WRBTR = P08_T04_01_TT_INV_PAID.B11C_BSAIK_WRBTR
													AND P08_T04_01_TT_INV_PAID.B11C_BSAIK_BUKRS + P08_T04_01_TT_INV_PAID.B11C_BSAIK_GJAHR + P08_T04_01_TT_INV_PAID.B11C_BSAIK_BELNR <> B.B11C_BSAIK_BUKRS + B.B11C_BSAIK_GJAHR + B.B11C_BSAIK_BELNR
													) SCENARIO_3
	-- SCENARIO 4 EXACT VENDOR#/INVOICE DATE/INVOICE AMOUNT
	OUTER APPLY(SELECT TOP 1 B.B11C_BSAIK_BUKRS, CONCAT('LIFNR:', B.B11C_BSAIK_LIFNR, '_WRBTR:', B.B11C_BSAIK_WRBTR, '_BLDAT:', B.B11C_BSAIK_BLDAT) AS ZF_SCENARIO_ID
						FROM P08_T04_01_TT_INV_PAID B 
						WHERE P08_T04_01_TT_INV_PAID.B11C_BSAIK_LIFNR = B.B11C_BSAIK_LIFNR
													AND B.B11C_BSAIK_WRBTR = P08_T04_01_TT_INV_PAID.B11C_BSAIK_WRBTR
													AND B.B11C_BSAIK_BLDAT = P08_T04_01_TT_INV_PAID.B11C_BSAIK_BLDAT
													AND P08_T04_01_TT_INV_PAID.B11C_BSAIK_BUKRS + P08_T04_01_TT_INV_PAID.B11C_BSAIK_GJAHR + P08_T04_01_TT_INV_PAID.B11C_BSAIK_BELNR <> B.B11C_BSAIK_BUKRS + B.B11C_BSAIK_GJAHR + B.B11C_BSAIK_BELNR
													) SCENARIO_4
	-- SCENARIO 5 EXACT INVOICE#/INVOICE DATE/INVOICE AMOUNT
	OUTER APPLY(SELECT TOP 1 B.B11C_BSAIK_BUKRS, CONCAT('LIFNR:', '_XBLNR:', B.B11C_BSAIK_XBLNR,'_WRBTR:',B.B11C_BSAIK_WRBTR , '_BLDAT:', B.B11C_BSAIK_BLDAT) AS ZF_SCENARIO_ID
						FROM P08_T04_01_TT_INV_PAID B WHERE B.B11C_BSAIK_XBLNR = P08_T04_01_TT_INV_PAID.B11C_BSAIK_XBLNR
													AND B.B11C_BSAIK_WRBTR = P08_T04_01_TT_INV_PAID.B11C_BSAIK_WRBTR
													AND B.B11C_BSAIK_BLDAT = P08_T04_01_TT_INV_PAID.B11C_BSAIK_BLDAT
													AND P08_T04_01_TT_INV_PAID.B11C_BSAIK_BUKRS + P08_T04_01_TT_INV_PAID.B11C_BSAIK_GJAHR + P08_T04_01_TT_INV_PAID.B11C_BSAIK_BELNR <> B.B11C_BSAIK_BUKRS + B.B11C_BSAIK_GJAHR + B.B11C_BSAIK_BELNR
													) SCENARIO_5
	-- SCENARIO 6 Similar vendor / EXACT INVOICE#/INVOICE AMOUNT
	OUTER APPLY(SELECT CONCAT(GROUP_LIFNR_KEY , B11E_BSAIK_XBLNR , B11E_BSAIK_WRBTR) SIMILAR_SUPPLIER_KEY FROM P08_T04_01_TT_DUP_PAY_SIMILAR_SUPP B 
					WHERE B.B11E_BSAIK_XBLNR = P08_T04_01_TT_INV_PAID.B11C_BSAIK_XBLNR
						--AND B.B11E_BSAIK_WRBTR = P08_T04_01_TT_INV_PAID.B11C_BSAIK_WRBTR
						AND B.GROUP_LIFNR_KEY LIKE '%' + P08_T04_01_TT_INV_PAID.B11C_BSAIK_LIFNR + '%') SCENARIO_6
	--get general information about payment
	OUTER APPLY(SELECT ISNULL(dbo.GROUP_CONCAT(B11E_BSAIK_WRBTR), 0) AS ZF_PAYMENT_WRBTR_CONCAT,
						ISNULL(SUM(B11E_BSAIK_DMBTR), 0) AS ZF_PAYMENT_TOTAL,
						ISNULL(COUNT(B11E_BSAIK_WRBTR), 0) AS ZF_PAYMENT_COUNT,
						ABS(ISNULL(DATEDIFF(DD, MAX(B11E_BSAIK_BLDAT), MIN(B11E_BSAIK_BLDAT)), 0)) AS ZF_PAYMENT_DATE_VARIANT
				FROM B11_08_IT_PTP_PAY 
				WHERE B11E_BSAIK_BUKRS = P08_T04_01_TT_INV_PAID.B11C_BSAIK_BUKRS
						AND B11E_BSAIK_AUGBL = P08_T04_01_TT_INV_PAID.B11C_BSAIK_AUGBL
						AND B11E_BSAIK_AUGDT = P08_T04_01_TT_INV_PAID.B11C_BSAIK_AUGDT
				--filter out payment with direct cancellation
						AND NOT EXISTS(SELECT * FROM B11_09_IT_PTP_PAY_CANC
							WHERE B11F_BSAIK_BUKRS = B11E_BSAIK_BUKRS
							AND B11F_BSAIK_AUGBL = B11E_BSAIK_AUGBL
							AND B11F_BSAIK_AUGDT = B11E_BSAIK_AUGDT
							AND B11F_BSAIK_WRBTR = B11E_BSAIK_WRBTR)) PAYMENT_AMOUNT_INFO
	--get general information about payment amount match
	OUTER APPLY(SELECT 'X' ZF_PAYMENT_MATCH_FLAG, COUNT(*) ZF_PAYMENT_MATCH_COUNT
				FROM B11_08_IT_PTP_PAY 
				WHERE B11E_BSAIK_BUKRS = P08_T04_01_TT_INV_PAID.B11C_BSAIK_BUKRS
						AND B11E_BSAIK_AUGBL = P08_T04_01_TT_INV_PAID.B11C_BSAIK_AUGBL
						AND B11E_BSAIK_AUGDT = P08_T04_01_TT_INV_PAID.B11C_BSAIK_AUGDT
						AND B11E_BSAIK_WRBTR = P08_T04_01_TT_INV_PAID.B11C_BSAIK_WRBTR
				--filter out payment with direct cancellation
						AND NOT EXISTS(SELECT * FROM B11_09_IT_PTP_PAY_CANC
							WHERE B11F_BSAIK_BUKRS = B11E_BSAIK_BUKRS
							AND B11F_BSAIK_AUGBL = B11E_BSAIK_AUGBL
							AND B11F_BSAIK_AUGDT = B11E_BSAIK_AUGDT
							AND B11F_BSAIK_WRBTR = B11E_BSAIK_WRBTR)) PAYMENT_AMOUNT_MATCH
	OUTER APPLY(SELECT TOP 1 'X' AS ZF_INVOICE_DIRECT_CANCEL_FLAG FROM B11_07_IT_PTP_INV_CANC WHERE B11D_BSAIK_BUKRS = P08_T04_01_TT_INV_PAID.B11C_BSAIK_BUKRS
													AND B11D_BSAIK_AUGBL = P08_T04_01_TT_INV_PAID.B11C_BSAIK_AUGBL
													AND B11D_BSAIK_AUGDT = P08_T04_01_TT_INV_PAID.B11C_BSAIK_AUGDT
													AND B11D_BSAIK_WRBTR = P08_T04_01_TT_INV_PAID.B11C_BSAIK_WRBTR) DIRECT_CANCELATION_FLAG

WHERE ISNULL(P08_T04_01_TT_INV_PAID.B11C_BSAIK_XBLNR, '') <> ''
	AND (SCENARIO_1.B11C_BSAIK_BUKRS IS NOT NULL
		--OR SCENARIO_2.B11C_BSAIK_BUKRS IS NOT NULL
		OR SCENARIO_3.B11C_BSAIK_BUKRS IS NOT NULL
		OR SCENARIO_4.B11C_BSAIK_BUKRS IS NOT NULL
		OR SCENARIO_5.B11C_BSAIK_BUKRS IS NOT NULL
		OR SCENARIO_6.SIMILAR_SUPPLIER_KEY IS NOT NULL)

ALTER TABLE P08_T04_02_TT_DUP_INVS
ALTER COLUMN ZF_CLASSIFICATION NVARCHAR(100)

EXEC SP_DROPTABLE 'P08_T04_02B_TT_DUP_INVS'

SELECT *
INTO P08_T04_02B_TT_DUP_INVS
FROM P08_T04_02_TT_DUP_INVS
WHERE (SELECT COUNT(*) FROM P08_T04_02_TT_DUP_INVS B WHERE B.ZF_SCENARIO_ID = P08_T04_02_TT_DUP_INVS.ZF_SCENARIO_ID) > 1


EXEC SP_DROPTABLE 'P08_T04_03_IT_DUP_INVS'
SELECT 
ZF_PAYMENT_TOTAL - ZF_INVOICE_DUPLICATE_TOTAL_VALUE ZF_PAYMENT_OFFSET,
ZF_INVOICE_DUPLICATE_COUNT,
(SELECT ABS(DATEDIFF(DD, MAX(B11C_BSAIK_BLDAT), MIN(B11C_BSAIK_BLDAT))) FROM P08_T04_02B_TT_DUP_INVS B WHERE B.ZF_SCENARIO_ID = P08_T04_02B_TT_DUP_INVS.ZF_SCENARIO_ID) AS ZF_INVOICE_DATE_VARIANT,
P08_T04_02B_TT_DUP_INVS.*
INTO P08_T04_03_IT_DUP_INVS
FROM P08_T04_02B_TT_DUP_INVS
LEFT JOIN (SELECT COUNT(*) ZF_INVOICE_DUPLICATE_COUNT, ZF_SCENARIO_ID, SUM(B11C_ZF_BSAIK_DMBTR_S) ZF_INVOICE_DUPLICATE_TOTAL_VALUE FROM P08_T04_02B_TT_DUP_INVS GROUP BY ZF_SCENARIO_ID) B
	ON  B.ZF_SCENARIO_ID = P08_T04_02B_TT_DUP_INVS.ZF_SCENARIO_ID

EXEC SP_UNNAME_FIELD 'B11C_', 'P08_T04_03_IT_DUP_INVS'

UPDATE P08_T04_03_IT_DUP_INVS
SET ZF_CLASSIFICATION = IIF(ZF_PAYMENT_COUNT = 1 
								AND ZF_ONE_PAYMENT_MATCH_ONE_INVOICE_ONLY = 'X' 
								AND ZF_PAYMENT_MATCH_FLAG = 'X', 'Duplicate invoice but only one payment to one invoice',
								IIF(ZF_INVOICE_DIRECT_CANCEL_FLAG = 'X', 'Cancellation',
								IIF(ZF_PAYMENT_COUNT = 0, 'Invoice without payment',
								IIF(ZF_PAYMENT_OFFSET < 0, 'Payment lower than invoice', ZF_CLASSIFICATION))))

UPDATE P08_T04_03_IT_DUP_INVS
SET ZF_CLASSIFICATION = IIF(LOWER(BSAIK_SGTXT) LIKE N'%???????%' 
							OR LOWER(BSAIK_SGTXT) LIKE N'%???????????%' 
							OR LOWER(BSAIK_SGTXT) LIKE N'%????%' 
							OR LOWER(BSAIK_SGTXT) LIKE N'%??????%', 'Recurring invoice', ZF_CLASSIFICATION)
	
			
UPDATE P08_T04_03_IT_DUP_INVS
SET ZF_CLASSIFICATION = IIF(A.ZF_CLASSIFICATION = '',
						ISNULL((SELECT TOP 1 ZF_CLASSIFICATION FROM P08_T04_03_IT_DUP_INVS B WHERE B.ZF_SCENARIO_ID = A.ZF_SCENARIO_ID AND B.ZF_CLASSIFICATION <> ''), ''), A.ZF_CLASSIFICATION)
FROM P08_T04_03_IT_DUP_INVS A
WHERE EXISTS(SELECT C.ZF_SCENARIO_ID FROM P08_T04_03_IT_DUP_INVS C WHERE C.ZF_SCENARIO_ID = A.ZF_SCENARIO_ID AND C.ZF_CLASSIFICATION = '' GROUP BY C.ZF_SCENARIO_ID HAVING COUNT(*) = 1)

EXEC SP_DROPTABLE 'P08_T04_04_IT_DUP_INVS'

SELECT A.* 

INTO P08_T04_04_IT_DUP_INVS
FROM P08_T04_03_IT_DUP_INVS A
WHERE EXISTS(SELECT * FROM P08_T04_03_IT_DUP_INVS B WHERE A.ZF_SCENARIO_ID = B.ZF_SCENARIO_ID
													AND A.BSAIK_BELNR <> B.BSAIK_BELNR
													AND A.BSAIK_SGTXT = B.BSAIK_SGTXT
													AND A.BSAIK_BLDAT = B.BSAIK_BLDAT)
													AND ZF_CLASSIFICATION = ''
													AND BSAIK_SGTXT <> ''
													ORDER BY A.ZF_SCENARIO_ID


EXEC SP_RENAME_FIELD 'P08_T04_', 'P08_T04_04_IT_DUP_INVS'

--Filter the AP cube and flag the duplicate item
EXEC SP_DROPTABLE 'P08_T04_05B_IT_AP_LINES'
SELECT A.*,
IIF(B.P08_T04_BSAIK_BUKRS IS NOT NULL, 1, 0) B11B_ZF_DUPLICATE_FLAG
INTO P08_T04_05B_IT_AP_LINES
FROM B11_04_IT_PTP_APA A
LEFT JOIN P08_T04_04_IT_DUP_INVS B ON A.B11B_BSAIK_BUKRS = B.P08_T04_BSAIK_BUKRS
									AND A.B11B_BSAIK_GJAHR = B.P08_T04_BSAIK_GJAHR
									AND A.B11B_BSAIK_BELNR = B.P08_T04_BSAIK_BELNR
									AND A.B11B_BSAIK_BUZEI = B.P08_T04_BSAIK_BUZEI
WHERE EXISTS(SELECT * FROM P08_T04_04_IT_DUP_INVS C WHERE A.B11B_BSAIK_AUGBL = C.P08_T04_BSAIK_AUGBL
														AND A.B11B_BSAIK_AUGGJ = C.P08_T04_BSAIK_AUGGJ)



EXEC SP_DROPTABLE 'P08_T04_06_TT_AP_KEY'
SELECT DISTINCT P08_T04_BSAIK_BUKRS, P08_T04_BKPF_AWKEY, P08_T04_ZF_FLAG_SUMMARY
INTO P08_T04_06_TT_AP_KEY
FROM P08_T04_04_IT_DUP_INVS
GROUP BY P08_T04_BSAIK_BUKRS, P08_T04_BKPF_AWKEY, P08_T04_ZF_FLAG_SUMMARY
CREATE CLUSTERED INDEX IDX ON P08_T04_06_TT_AP_KEY(P08_T04_BSAIK_BUKRS, P08_T04_BKPF_AWKEY)

EXEC SP_DROPTABLE 'P08_T04_07C_IT_RSEG'
SELECT DISTINCT RSEG_BUKRS, RSEG_BELNR, RSEG_GJAHR, RSEG_EBELN, RSEG_EBELP
INTO P08_T04_07C_IT_RSEG
FROM A_RSEG A
INNER JOIN P08_T04_06_TT_AP_KEY B ON A.RSEG_BUKRS + A.RSEG_BELNR + A.RSEG_GJAHR = B.P08_T04_BSAIK_BUKRS + B.P08_T04_BKPF_AWKEY

EXEC SP_DROPTABLE 'P08_T04_08_TT_GL_KEY'
SELECT DISTINCT RSEG_EBELN, RSEG_EBELP
INTO P08_T04_08_TT_GL_KEY
FROM P08_T04_07C_IT_RSEG
CREATE CLUSTERED INDEX IDX ON P08_T04_08_TT_GL_KEY(RSEG_EBELN, RSEG_EBELP)



EXEC SP_DROPTABLE 'P08_T04_09D_IT_PO'
SELECT A.* 
INTO P08_T04_09D_IT_PO
FROM B09_13_IT_PTP_POS A
INNER JOIN P08_T04_08_TT_GL_KEY B ON A.B09_EKKO_EBELN = B.RSEG_EBELN
									AND A.B09_EKPO_EBELP = B.RSEG_EBELP



EXEC SP_DROPTABLE 'P08_T04_10_TT_CASE_W_SAME_REF_PO'
SELECT DISTINCT P08_T04_ZF_SCENARIO_ID
INTO P08_T04_10_TT_CASE_W_SAME_REF_PO
FROM P08_T04_04_IT_DUP_INVS A
LEFT JOIN P08_T04_07C_IT_RSEG B ON A.P08_T04_BSAIK_BUKRS + A.P08_T04_BKPF_AWKEY = B.RSEG_BUKRS + B.RSEG_BELNR + B.RSEG_GJAHR
LEFT JOIN P08_T04_09D_IT_PO C ON B.RSEG_EBELN = C.B09_EKKO_EBELN AND B.RSEG_EBELP = C.B09_EKPO_EBELP
GROUP BY P08_T04_ZF_SCENARIO_ID
HAVING (COUNT(DISTINCT P08_T04_BSAIK_XBLNR) < COUNT(DISTINCT P08_T04_ZF_SCENARIO_ID + P08_T04_BSAIK_BELNR))
OR (COUNT(DISTINCT B09_EKKO_EBELN + B09_EKPO_EBELP) < COUNT(DISTINCT P08_T04_ZF_SCENARIO_ID + P08_T04_BSAIK_BELNR) AND COUNT(DISTINCT B09_EKKO_EBELN + B09_EKPO_EBELP) <> 0)


DELETE P08_T04_04_IT_DUP_INVS    
FROM P08_T04_04_IT_DUP_INVS A
WHERE NOT EXISTS(SELECT * FROM P08_T04_10_TT_CASE_W_SAME_REF_PO B WHERE A.P08_T04_ZF_SCENARIO_ID = B.P08_T04_ZF_SCENARIO_ID)

EXEC SP_UNNAME_FIELD 'B11B_', 'P08_T04_05B_IT_AP_LINES'
EXEC SP_RENAME_FIELD 'P08_T04B_', 'P08_T04_05B_IT_AP_LINES'

EXEC SP_CONVERT_FIELD_VALUE 'P08_T04_%IT%', 'MONEY', 'REAL'

EXEC SP_REMOVE_TABLES '%_TT_%'


/* log cube creation*/

INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','P08_T04_03_IT_DUP_INVS',(SELECT COUNT(*) FROM P08_T04_03_IT_DUP_INVS) 


/* log end of procedure*/


INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL

END
GO
