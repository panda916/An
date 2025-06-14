USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROC [dbo].[script_O08_T18_SALES_RED_PER_CUSTOMER_CHINA]
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
  Title:	[O08_T18_SALES_RED_PER_CUSTOMER]
  Description: Create a table that will enable to show total sales reductions per customer

    --------------------------------------------------------------
    Update history
    --------------------------------------------------------------
    Date		    | Who |	Description
	07-09-2018	     CJW   Created
	12-06-2018	     Hung  Reworked
	23-03-2022		 Thuan Remove MANDT field in join

  */

/*--Step 0
	Update scope table with GL acount in range 
--	LIKE '515%', '510%'
*/
	--INSERT INTO AM_SALES_RED_ACCOUNTS
	--SELECT DISTINCT BSEG_HKONT FROM 
	--	(SELECT DISTINCT BSEG_HKONT FROM A_BSEG WHERE ISNUMERIC(BSEG_HKONT) = 1) A_BSEG
	--WHERE CAST(BSEG_HKONT AS FLOAT) LIKE '515%' AND CAST(BSEG_HKONT AS FLOAT) LIKE '510%'
	--AND NOT EXISTS(SELECT * FROM AM_SALES_RED_ACCOUNTS WHERE AMSR_GL_ACCOUNT = BSEG_HKONT)

	--INSERT INTO AM_CUST_RED_HIERARCHY
	--SELECT DISTINCT 'Cost of sales', BSEG_HKONT FROM 
	--	(SELECT DISTINCT BSEG_HKONT FROM A_BSEG WHERE ISNUMERIC(BSEG_HKONT) = 1) A_BSEG
	--WHERE CAST(BSEG_HKONT AS FLOAT) LIKE '515%' AND CAST(BSEG_HKONT AS FLOAT) LIKE '510%'
	--AND NOT EXISTS(SELECT * FROM AM_CUST_RED_HIERARCHY WHERE AM_GL_ACCOUNT = BSEG_HKONT)
/*--Step 1
--Create a list of journal entry numbers and customer numbers
  */

    EXEC SP_DROPTABLE 'O18_03_IT_JES_LINES_CUST_RED'
	 EXEC SP_DROPTABLE 'O18_04_RT_JES_HEADER'

	EXEC SP_DROPTABLE 'O18_01_TT_JOURNAL_WITH_MORE_THAN_ONE_CUSTOMER'
	SELECT B04_BSEG_BUKRS, B04_BSEG_GJAHR, B04_BSEG_BELNR, COUNT(*) AS NR_CUSTOMER
	INTO O18_01_TT_JOURNAL_WITH_MORE_THAN_ONE_CUSTOMER
	FROM 
	(
		SELECT DISTINCT B04_BSEG_BUKRS, B04_BSEG_GJAHR, B04_BSEG_BELNR, B04_BSEG_KUNNR 
			FROM B04_11_IT_FIN_GL
			WHERE ISNULL(B04_BSEG_KUNNR, '') <> ''
	) B04_11_IT_FIN_GL
	GROUP BY B04_BSEG_BUKRS, B04_BSEG_GJAHR, B04_BSEG_BELNR
	HAVING COUNT(*) > 1

/*--Step 2
-- Get essential field for Sale reduction header table
-- Fill customer number for journal entry line item without customer name
-- Update Journal entry with multiple entry line item field
*/

	EXEC SP_DROPTABLE 'O18_02_TT_JES_HEADER'

	SELECT 
		   B04_BKPF_MANDT as BKPF_MANDT,
		   B04_11_IT_FIN_GL.B04_BSEG_BUKRS AS BSEG_BUKRS,
		   B04_11_IT_FIN_GL.B04_BSEG_GJAHR AS BSEG_GJAHR,
		   B04_11_IT_FIN_GL.B04_BSEG_BELNR AS BSEG_BELNR,
		   B04_BSEG_KOART AS BSEG_KOART,
		   B04_BSEG_BUZEI AS BSEG_BUZEI,
		   B04_BSEG_SHKZG AS BSEG_SHKZG,
		   B04_BSEG_HKONT AS BSEG_HKONT,
		   IIF(ISNULL(B04_11_IT_FIN_GL.B04_BSEG_KUNNR, '') <> '', B04_11_IT_FIN_GL.B04_BSEG_KUNNR,
				(SELECT TOP 1 B.B04_BSEG_KUNNR FROM B04_11_IT_FIN_GL B
											WHERE B.B04_BSEG_BUKRS = B04_11_IT_FIN_GL.B04_BSEG_BUKRS
												AND B.B04_BSEG_GJAHR = B04_11_IT_FIN_GL.B04_BSEG_GJAHR
												AND B.B04_BSEG_BELNR = B04_11_IT_FIN_GL.B04_BSEG_BELNR
												AND ISNULL(B.B04_BSEG_KUNNR, '') <> ''))
		   AS BSEG_KUNNR,
		   B04_BKPF_HWAER AS BKPF_HWAER,
		   B04_AM_GLOBALS_CURRENCY AS AM_GLOBALS_CURRENCY,
		   B04_BSEG_PRCTR as BSEG_PRCTR,
		   B04_ZF_BKPF_BUDAT_FQ,
		   AM_ACCOUNT_BUCKET,
		   Level1 as Hierarchy_L1,
		   Level2 as Hierarchy_L2,
		   Level3 as Hierarchy_L3,
		   -- Amount in Detail table
		   B04_ZF_BSEG_DMBTR_S  AS ZF_BSEG_DMBTR_S,
		   B04_ZF_BSEG_DMBTR_S_CUC  AS ZF_BSEG_DMBTR_S_CUC,
           B04_ZF_BSEG_DMBE2_S  AS ZF_BSEG_DMBE2_S,
           B04_ZF_BSEG_DMBE3_S  AS ZF_BSEG_DMBE3_S,	
		   -- Amount caculation in KPI, Pivot, Tree chart..
			B04_ZF_BSEG_DMBTR_S * AM_CUST_RED_HIERARCHY.[sign] AS ZF_BSEG_DMBTR_S_SIGN,
			B04_ZF_BSEG_DMBTR_S_CUC * AM_CUST_RED_HIERARCHY.[sign] AS ZF_BSEG_DMBTR_S_CUC_SIGN,
			B04_ZF_BSEG_DMBE2_S * AM_CUST_RED_HIERARCHY.[sign] AS ZF_BSEG_DMBE2_S_SIGN,
			B04_ZF_BSEG_DMBE3_S * AM_CUST_RED_HIERARCHY.[sign] AS ZF_BSEG_DMBE3_S_SIGN,	

		   B04_ZF_BKPF_BUDAT_YEAR_MNTH AS ZF_BKPF_BUDAT_YEAR_MNTH,
		   ISNULL(NR_CUSTOMER, 0) AS CUSTOMER_IN_ONE_JOURNAL_ENTRY,
		   B04_BSEG_MATNR as BSEG_MATNR,
		   B04_BKPF_BUDAT as BKPF_BUDAT,
		   B04_ZF_BKPF_AWKEY_DOC_NUM as ZF_BKPF_AWKEY_DOC_NUM,
		   B04_BKPF_AWTYP as BKPF_AWTYP
		INTO O18_02_TT_JES_HEADER
		FROM B04_11_IT_FIN_GL

		INNER JOIN AM_SALES_RED_ACCOUNTS
-- Add remove leading zero 
			ON dbo.REMOVE_LEADING_ZEROES(AM_SALES_RED_ACCOUNTS.AMSR_GL_ACCOUNT) = dbo.REMOVE_LEADING_ZEROES(B04_11_IT_FIN_GL.B04_BSEG_HKONT)

		LEFT JOIN AM_CUST_RED_HIERARCHY
			ON  AM_SALES_RED_ACCOUNTS.AMSR_GL_ACCOUNT = AM_CUST_RED_HIERARCHY.AM_GL_ACCOUNT
		LEFT JOIN O18_01_TT_JOURNAL_WITH_MORE_THAN_ONE_CUSTOMER
			ON B04_11_IT_FIN_GL.B04_BSEG_BUKRS = O18_01_TT_JOURNAL_WITH_MORE_THAN_ONE_CUSTOMER.B04_BSEG_BUKRS
		   AND B04_11_IT_FIN_GL.B04_BSEG_GJAHR = O18_01_TT_JOURNAL_WITH_MORE_THAN_ONE_CUSTOMER.B04_BSEG_GJAHR
		   AND B04_11_IT_FIN_GL.B04_BSEG_BELNR = O18_01_TT_JOURNAL_WITH_MORE_THAN_ONE_CUSTOMER.B04_BSEG_BELNR

/*--Step 3/
--Create table to calculate the sale reduction, gross sales, net sales,  Operating revenue and intracompany
*/
	EXEC SP_DROPTABLE 'O18_03_IT_JES_LINES_CUST_RED'
	SELECT 	
		BSEG_BUKRS,
		BSEG_GJAHR,
		BSEG_BELNR,
		BSEG_BUZEI,
		Hierarchy_L1,
		Hierarchy_L2,
		Hierarchy_L3,
		IIF(Hierarchy_L1 = 'Sales reductions', Hierarchy_L1, NULL) as ZF_SR_L1,
		IIF(Hierarchy_L1 = 'Sales reductions', Hierarchy_L2, NULL) as ZF_SR_L2,
		IIF(Hierarchy_L1 = 'Sales reductions', Hierarchy_L3, NULL) as ZF_SR_L3,
		-- Amount
		ZF_BSEG_DMBTR_S_SIGN,
		ZF_BSEG_DMBTR_S_CUC_SIGN,
        ZF_BSEG_DMBE2_S_SIGN,
        ZF_BSEG_DMBE3_S_SIGN,	
		'Non relevant for Sale reduction analysis' AM_ACCOUNT_BUCKET
	INTO  O18_03_IT_JES_LINES_CUST_RED
	FROM O18_02_TT_JES_HEADER
	WHERE AM_ACCOUNT_BUCKET IS NULL

	--Sale reduction calculation
	INSERT INTO O18_03_IT_JES_LINES_CUST_RED
	SELECT 
		BSEG_BUKRS,
		BSEG_GJAHR,
		BSEG_BELNR,
		BSEG_BUZEI,
		Hierarchy_L1,
		Hierarchy_L2,
		Hierarchy_L3,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L1, NULL) as ZF_SR_L1,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L2, NULL) as ZF_SR_L2,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L3, NULL) as ZF_SR_L3,
		ZF_BSEG_DMBTR_S_SIGN,
		ZF_BSEG_DMBTR_S_CUC_SIGN,
        ZF_BSEG_DMBE2_S_SIGN,
        ZF_BSEG_DMBE3_S_SIGN,	
		'Sale reductions' AM_ACCOUNT_BUCKET
	FROM O18_02_TT_JES_HEADER	 
	WHERE AM_ACCOUNT_BUCKET = 'SALES REDUCTIONS'

	--Gross sales
	INSERT INTO O18_03_IT_JES_LINES_CUST_RED
	SELECT 	
		BSEG_BUKRS,
		BSEG_GJAHR,
		BSEG_BELNR,
		BSEG_BUZEI,
		Hierarchy_L1,
		Hierarchy_L2,
		Hierarchy_L3,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L1, NULL) as ZF_SR_L1,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L2, NULL) as ZF_SR_L2,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L3, NULL) as ZF_SR_L3,
		ZF_BSEG_DMBTR_S_SIGN,
		ZF_BSEG_DMBTR_S_CUC_SIGN,
        ZF_BSEG_DMBE2_S_SIGN,
        ZF_BSEG_DMBE3_S_SIGN,	
		'Gross sales' AM_ACCOUNT_BUCKET
	FROM O18_02_TT_JES_HEADER
	WHERE AM_ACCOUNT_BUCKET = 'TOTAL GROSS SALES'

	--Net sales
	INSERT INTO O18_03_IT_JES_LINES_CUST_RED
	SELECT 	
		BSEG_BUKRS,
		BSEG_GJAHR,
		BSEG_BELNR,
		BSEG_BUZEI,
		Hierarchy_L1,
		Hierarchy_L2,
		Hierarchy_L3,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L1, NULL) as ZF_SR_L1,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L2, NULL) as ZF_SR_L2,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L3, NULL) as ZF_SR_L3,
		IIF(AM_ACCOUNT_BUCKET = 'SALES REDUCTIONS',ZF_BSEG_DMBTR_S *-1,ZF_BSEG_DMBTR_S_SIGN) AS ZF_BSEG_DMBTR_S_SIGN,
		IIF(AM_ACCOUNT_BUCKET = 'SALES REDUCTIONS',ZF_BSEG_DMBTR_S_CUC*-1,ZF_BSEG_DMBTR_S_CUC_SIGN) AS ZF_BSEG_DMBTR_S_CUC_SIGN,
		IIF(AM_ACCOUNT_BUCKET = 'SALES REDUCTIONS',ZF_BSEG_DMBE2_S*-1,ZF_BSEG_DMBE2_S_SIGN) AS ZF_BSEG_DMBE2_S_SIGN,
		IIF(AM_ACCOUNT_BUCKET = 'SALES REDUCTIONS',ZF_BSEG_DMBE3_S*-1,ZF_BSEG_DMBE3_S_SIGN) AS ZF_BSEG_DMBE3_S_SIGN,
		'Net sales' AM_ACCOUNT_BUCKET
	FROM O18_02_TT_JES_HEADER
	WHERE AM_ACCOUNT_BUCKET IN ( 'SALES REDUCTIONS', 'TOTAL GROSS SALES') 

	--Cost of sales
	INSERT INTO O18_03_IT_JES_LINES_CUST_RED
	SELECT 	
		BSEG_BUKRS,
		BSEG_GJAHR,
		BSEG_BELNR,
		BSEG_BUZEI,
		Hierarchy_L1,
		Hierarchy_L2,
		Hierarchy_L3,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L1, NULL) as ZF_SR_L1,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L2, NULL) as ZF_SR_L2,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L3, NULL) as ZF_SR_L3,
		ZF_BSEG_DMBTR_S_SIGN,
		ZF_BSEG_DMBTR_S_CUC_SIGN,
        ZF_BSEG_DMBE2_S_SIGN,
        ZF_BSEG_DMBE3_S_SIGN,	
		'Cost of sales' AM_ACCOUNT_BUCKET
	FROM O18_02_TT_JES_HEADER
	WHERE AM_ACCOUNT_BUCKET IN ('Cost of sales') 

	--Gross profit
	INSERT INTO O18_03_IT_JES_LINES_CUST_RED
	SELECT 	
		BSEG_BUKRS,
		BSEG_GJAHR,
		BSEG_BELNR,
		BSEG_BUZEI,
		Hierarchy_L1,
		Hierarchy_L2,
		Hierarchy_L3,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L1, NULL) as ZF_SR_L1,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L2, NULL) as ZF_SR_L2,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L3, NULL) as ZF_SR_L3,
		IIF((AM_ACCOUNT_BUCKET = 'SALES REDUCTIONS' OR AM_ACCOUNT_BUCKET = 'Cost of sales'),ZF_BSEG_DMBTR_S *-1,  ZF_BSEG_DMBTR_S_SIGN) AS ZF_BSEG_DMBTR_S_SIGN,
		IIF((AM_ACCOUNT_BUCKET = 'SALES REDUCTIONS' OR AM_ACCOUNT_BUCKET = 'Cost of sales'),ZF_BSEG_DMBTR_S_CUC*-1,ZF_BSEG_DMBTR_S_CUC_SIGN) AS ZF_BSEG_DMBTR_S_CUC_SIGN,
		IIF((AM_ACCOUNT_BUCKET = 'SALES REDUCTIONS' OR AM_ACCOUNT_BUCKET = 'Cost of sales'),ZF_BSEG_DMBE2_S*-1,ZF_BSEG_DMBE2_S_SIGN) AS ZF_BSEG_DMBE2_S_SIGN,
		IIF((AM_ACCOUNT_BUCKET = 'SALES REDUCTIONS' OR AM_ACCOUNT_BUCKET = 'Cost of sales'),ZF_BSEG_DMBE3_S*-1,ZF_BSEG_DMBE3_S_SIGN) AS ZF_BSEG_DMBE3_S_SIGN,
		'Gross profit' AM_ACCOUNT_BUCKET
	FROM O18_02_TT_JES_HEADER
	WHERE AM_ACCOUNT_BUCKET IN ( 'SALES REDUCTIONS', 'TOTAL GROSS SALES', 'Cost of sales') 

	-- Operating reveneu

	INSERT INTO O18_03_IT_JES_LINES_CUST_RED
	SELECT 	
		BSEG_BUKRS,
		BSEG_GJAHR,
		BSEG_BELNR,
		BSEG_BUZEI,
		Hierarchy_L1,
		Hierarchy_L2,
		Hierarchy_L3,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L1, NULL) as ZF_SR_L1,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L2, NULL) as ZF_SR_L2,
		IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L3, NULL) as ZF_SR_L3,
		ZF_BSEG_DMBTR_S_SIGN,
		ZF_BSEG_DMBTR_S_CUC_SIGN,
        ZF_BSEG_DMBE2_S_SIGN,
        ZF_BSEG_DMBE3_S_SIGN,	
		'Operating revenue' AM_ACCOUNT_BUCKET
	FROM O18_02_TT_JES_HEADER
	WHERE AM_ACCOUNT_BUCKET IN ( 'OPERATING REVENUE') 

	-- New group from Jesper
		INSERT INTO O18_03_IT_JES_LINES_CUST_RED
		SELECT 	
			BSEG_BUKRS,
			BSEG_GJAHR,
			BSEG_BELNR,
			BSEG_BUZEI,
			Hierarchy_L1,
			Hierarchy_L2,
			Hierarchy_L3,
			IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L1, NULL) as ZF_SR_L1,
			IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L2, NULL) as ZF_SR_L2,
			IIF(Hierarchy_L1 = 'SALES REDUCTIONS', Hierarchy_L3, NULL) as ZF_SR_L3,
			ZF_BSEG_DMBTR_S_SIGN,
			ZF_BSEG_DMBTR_S_CUC_SIGN,
			ZF_BSEG_DMBE2_S_SIGN,
			ZF_BSEG_DMBE3_S_SIGN,	
			'Intracompany' AM_ACCOUNT_BUCKET
		FROM O18_02_TT_JES_HEADER
		WHERE AM_ACCOUNT_BUCKET IN ( 'INTRACOMPANY') 

--Step 4/ Create VBELN from sale and billing document
EXEC SP_DROPTABLE 'O18_05_IT_VBELN'
	SELECT DISTINCT VBRK_VBELN, VBAK_VBELN 
	INTO O18_05_IT_VBELN 
	FROM A_VBRK
		LEFT JOIN A_VBRP ON VBRP_VBELN = VBRK_VBELN
		LEFT JOIN A_VBAP ON VBAP_VBELN = VBRP_AUBEL AND VBAP_POSNR = VBRP_POSNR
		LEFT JOIN A_VBAK ON VBAP_VBELN = VBAK_VBELN

	WHERE VBAK_VBELN IS NOT NULL



-- Step 5/ update NULL to blank before load into qlik
ALTER TABLE O18_02_TT_JES_HEADER DROP COLUMN ZF_BSEG_DMBTR_S_SIGN;
ALTER TABLE O18_02_TT_JES_HEADER DROP COLUMN ZF_BSEG_DMBTR_S_CUC_SIGN;
ALTER TABLE O18_02_TT_JES_HEADER DROP COLUMN ZF_BSEG_DMBE2_S_SIGN;
ALTER TABLE O18_02_TT_JES_HEADER DROP COLUMN ZF_BSEG_DMBE3_S_SIGN;

/*Rename fields for Qlik*/
EXEC SP_RENAME_FIELD 'O08_T18_', 'O18_02_TT_JES_HEADER'
EXEC SP_RENAME_FIELD 'O08_T18B_', 'O18_03_IT_JES_LINES_CUST_RED'
EXEC SP_DROPTABLE 'O18_04_RT_JES_HEADER'
EXEC sp_rename 'O18_02_TT_JES_HEADER', 'O18_04_RT_JES_HEADER'

UPDATE O18_04_RT_JES_HEADER
SET O08_T18_BSEG_KUNNR = ''
WHERE O08_T18_BSEG_KUNNR IS NULL

--Step 6/ Create Material table before load into qlik
EXEC SP_DROPTABLE 'O18_05_IT_MATNR'
	SELECT DISTINCT MARA_MATNR , MARA_MANDT
	INTO O18_05_IT_MATNR
		FROM O18_04_RT_JES_HEADER 
		LEFT JOIN A_MARA ON MARA_MATNR = O08_T18_BSEG_MATNR
			
-- Step 7/ Update order field in pivot table in QLIK

SELECT DISTINCT  O08_T18B_AM_ACCOUNT_BUCKET FROM O18_03_IT_JES_LINES_CUST_RED

ALTER TABLE O18_03_IT_JES_LINES_CUST_RED ADD AM_BUCKET_ORDER FLOAT;

UPDATE O18_03_IT_JES_LINES_CUST_RED
SET AM_BUCKET_ORDER = 1
WHERE O08_T18B_AM_ACCOUNT_BUCKET = 'Gross sales'

UPDATE O18_03_IT_JES_LINES_CUST_RED
SET AM_BUCKET_ORDER = 2
WHERE O08_T18B_AM_ACCOUNT_BUCKET = 'Sale reductions'

UPDATE O18_03_IT_JES_LINES_CUST_RED
SET AM_BUCKET_ORDER = 3
WHERE O08_T18B_AM_ACCOUNT_BUCKET = 'Net sales'

UPDATE O18_03_IT_JES_LINES_CUST_RED
SET AM_BUCKET_ORDER = 4
WHERE O08_T18B_AM_ACCOUNT_BUCKET = 'Cost of sales'

UPDATE O18_03_IT_JES_LINES_CUST_RED
SET AM_BUCKET_ORDER = 5
WHERE O08_T18B_AM_ACCOUNT_BUCKET = 'Gross profit'

UPDATE O18_03_IT_JES_LINES_CUST_RED
SET AM_BUCKET_ORDER = 6
WHERE O08_T18B_AM_ACCOUNT_BUCKET = 'Operating revenue'

UPDATE O18_03_IT_JES_LINES_CUST_RED
SET AM_BUCKET_ORDER = 7
WHERE O08_T18B_AM_ACCOUNT_BUCKET = 'Intracompany'





/* log cube creation*/
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','O18_04_RT_JES_HEADER',(SELECT COUNT(*) FROM O18_04_RT_JES_HEADER) 

/* log end of procedure*/
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL

END
GO
