USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROC [dbo].[script_P08_T24_BANK_OUT]
-- ALTER PROC [dbo].[[P08_T24_BANK_OUT]]

AS
--DYNAMIC_SCRIPT_START
SET NOCOUNT ON

DECLARE
       @currency nvarchar(max)                  = (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'currency')
       ,@DATE1 nvarchar(max)                           = (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'DATE1')
       ,@DATE2 nvarchar(max)                           = (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'DATE2')
       ,@downloadDATE nvarchar(max)             = (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'downloadDATE')
       ,@exchangeratetype nvarchar(max)  = (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'exchangeratetype')
       ,@language1 nvarchar(max)                = (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'language1')
       ,@language2 nvarchar(max)                = (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'language2')
       ,@year nvarchar(max)                     = (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'year')
       ,@id nvarchar(max)                              = (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'id')
       ,@LIMIT_RECORDS INT        = (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS')

/*DECLARE            @end_DATE DATE = CAST(@DATE2 AS DATETIME)
                     ,@current_snapshot_DATE DATE = CAST(@DATE1 AS DATE)
                     ,@current_snapshot_DATE_FROM DATE
                     ,@current_snapshot_DATE_TO DATE
                     ,@start_DATE DATE = (SELECT CAST(@DATE1 AS DATE))
                     ,@eof DATE
                     ,@SQL_CMD NVARCHAR(MAX)

DECLARE  @_AGEING AS DATE*/


/*Change history comments*/


  /*
  Title:      [P08_T24_BANK_OUT]
  Description: This procedure will gather all bank out transactions AND their related details

    --------------------------------------------------------------
    Update history
    --------------------------------------------------------------
    Date                 | Who |   Description
    16-10-2018             TH      First version
	05-04-2019             THUAN    Update
	23-03-2022			   Thuan	Remove MANDT field in join
  */



-- Step 0/ This step is to be moved to the AM_ phase
-- Ensure that the list of bank out accounts is unique AND obtain only the accounts that are really relevant to bank

EXEC SP_DROPTABLE 'P08_T24_00_TT_AM_BANK_ACC'
SELECT DISTINCT GL_BANK_ACC_HKONT, GL_BANK_ACC_BUKRS INTO P08_T24_00_TT_AM_BANK_ACC FROM AM_GL_BANK_ACC
WHERE NOT GL_BANK_TEXT1 LIKE '%' + 'BANKS INTERIM' + '%'
EXEC SP_CREATE_INDEX 'GL_BANK_ACC_HKONT, GL_BANK_ACC_BUKRS', 'P08_T24_00_TT_AM_BANK_ACC'
DECLARE @errormsg NVARCHAR(MAX)

-- Step 1/ Create a list of total bank-out D per JE = total bank-out C per JE in same journal entry (to be excluded in this step)
SET @errormsg = 'Create bank-out D per JE = total bank-out C per JE in same journal entry'
RAISERROR (@errormsg, 0, 1) WITH NOWAIT
EXEC SP_DROPTABLE 'P08_T24_01_TT_BELNR_BO_D_EQ_C'
 SELECT B04_BSEG_BUKRS, B04_BSEG_GJAHR, B04_BSEG_BELNR
 INTO P08_T24_01_TT_BELNR_BO_D_EQ_C
 FROM B04_11_IT_FIN_GL
 INNER JOIN P08_T24_00_TT_AM_BANK_ACC
       ON  B04_11_IT_FIN_GL.B04_BSEG_HKONT = P08_T24_00_TT_AM_BANK_ACC.GL_BANK_ACC_HKONT
              AND B04_11_IT_FIN_GL.B04_BSEG_BUKRS = P08_T24_00_TT_AM_BANK_ACC.GL_BANK_ACC_BUKRS
 GROUP BY B04_BSEG_BUKRS, B04_BSEG_GJAHR, B04_BSEG_BELNR
 HAVING SUM(B04_ZF_BSEG_DMBTR_S) = 0
-- Step 3/ Create a list of total bank-out D per AUGBL+AUGDT = total bank-out C per AUGBL+AUGDT (to be excluded in step 6)
SET @errormsg = 'Create bank-out D per JE = total bank-out C per AUGBL+AUGDT'
RAISERROR (@errormsg, 0, 1) WITH NOWAIT
EXEC SP_DROPTABLE 'P08_T24_02_TT_AUGBL_BO_D_EQ_C'
 SELECT B04_BSEG_BUKRS, B04_BSEG_AUGBL, B04_BSEG_AUGDT
 INTO P08_T24_02_TT_AUGBL_BO_D_EQ_C
 FROM B04_11_IT_FIN_GL
 INNER JOIN P08_T24_00_TT_AM_BANK_ACC
       ON  B04_11_IT_FIN_GL.B04_BSEG_HKONT = P08_T24_00_TT_AM_BANK_ACC.GL_BANK_ACC_HKONT
              AND B04_11_IT_FIN_GL.B04_BSEG_BUKRS = P08_T24_00_TT_AM_BANK_ACC.GL_BANK_ACC_BUKRS
 GROUP BY B04_BSEG_BUKRS, B04_BSEG_AUGBL, B04_BSEG_AUGDT
 HAVING SUM(B04_ZF_BSEG_DMBTR_S) = 0

CREATE INDEX BUKRS ON P08_T24_02_TT_AUGBL_BO_D_EQ_C(B04_BSEG_BUKRS)
CREATE INDEX AUGBL ON P08_T24_02_TT_AUGBL_BO_D_EQ_C(B04_BSEG_AUGBL)
CREATE INDEX AUGDT ON P08_T24_02_TT_AUGBL_BO_D_EQ_C(B04_BSEG_AUGDT)

EXEC SP_CREATE_INDEX 'B02_T001_BUKRS, B02_SKB1_SAKNR', 'B02_04_IT_FIN_COA'
-- Step 4/ Create a no bank to bank data source
SET @errormsg = 'Create no bank to bank data source'
RAISERROR (@errormsg, 0, 1) WITH NOWAIT
EXEC SP_DROPTABLE 'P08_T24_03_TT_FIN_GL_NO_BTB'

-- Filter out AUGBL transactions that have Bank to Bank transfer
SELECT 
		B04_11_IT_FIN_GL.B04_BSEG_BUKRS,
		B04_11_IT_FIN_GL.B04_BSEG_GJAHR,
		B04_11_IT_FIN_GL.B04_BKPF_BUDAT,
		B04_11_IT_FIN_GL.B04_BSEG_BELNR,
		B04_11_IT_FIN_GL.B04_BSEG_BUZEI,
		B04_11_IT_FIN_GL.B04_BSEG_KOART,
		B04_11_IT_FIN_GL.B04_BSEG_AUGDT,
		B04_11_IT_FIN_GL.B04_BSEG_AUGBL,
		B04_11_IT_FIN_GL.B04_BSEG_SHKZG,
		B04_11_IT_FIN_GL.B04_BSEG_HKONT,
		B02_04_IT_FIN_COA.B02_SKAT_TXT50 AS B04_SKAT_TXT50,
		B04_11_IT_FIN_GL.B04_BSEG_LIFNR,
		B04_11_IT_FIN_GL.B04_BSEG_KUNNR,
		B04_11_IT_FIN_GL.B04_BSEG_BUKRS + ' - ' +  A_T001.T001_BUTXT AS B04_ZF_BKPF_BUKRS_BUTXT,
		B04_11_IT_FIN_GL.B04_BKPF_WAERS,
		B04_11_IT_FIN_GL.B04_ZF_BSEG_DMBTR_S,
		B04_11_IT_FIN_GL.B04_AM_GLOBALS_CURRENCY,
		B04_11_IT_FIN_GL.B04_ZF_BSEG_DMBTR_S_CUC,
		B04_11_IT_FIN_GL.B04_ZF_BSEG_DMBE2_S,
		B04_11_IT_FIN_GL.B04_ZF_BSEG_DMBE3_S
INTO P08_T24_03_TT_FIN_GL_NO_BTB 
FROM B04_11_IT_FIN_GL
LEFT JOIN P08_T24_02_TT_AUGBL_BO_D_EQ_C ON 
	 P08_T24_02_TT_AUGBL_BO_D_EQ_C.B04_BSEG_AUGDT = B04_11_IT_FIN_GL.B04_BSEG_AUGDT 
	 AND P08_T24_02_TT_AUGBL_BO_D_EQ_C.B04_BSEG_AUGBL = B04_11_IT_FIN_GL.B04_BSEG_AUGBL
	 AND P08_T24_02_TT_AUGBL_BO_D_EQ_C.B04_BSEG_BUKRS = B04_11_IT_FIN_GL.B04_BSEG_BUKRS
LEFT JOIN B02_04_IT_FIN_COA
              ON     B04_11_IT_FIN_GL.B04_BSEG_BUKRS = B02_04_IT_FIN_COA.B02_T001_BUKRS AND
                     B04_11_IT_FIN_GL.B04_BSEG_HKONT = B02_04_IT_FIN_COA.B02_SKB1_SAKNR
LEFT JOIN A_T001
	ON A_T001.T001_BUKRS = B04_11_IT_FIN_GL.B04_BSEG_BUKRS
WHERE P08_T24_02_TT_AUGBL_BO_D_EQ_C.B04_BSEG_AUGBL IS NULL

-- Delete Journal entry that have Bank to Bank transfer

SET @errormsg = 'Exclude bank to bank within one Journal entry'
RAISERROR (@errormsg, 0, 1) WITH NOWAIT
DELETE P08_T24_03_TT_FIN_GL_NO_BTB
	WHERE EXISTS(SELECT TOP 1 1 FROM P08_T24_01_TT_BELNR_BO_D_EQ_C WHERE 
		 P08_T24_01_TT_BELNR_BO_D_EQ_C.B04_BSEG_GJAHR = P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_GJAHR 
		 AND P08_T24_01_TT_BELNR_BO_D_EQ_C.B04_BSEG_BUKRS = P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS
		 AND P08_T24_01_TT_BELNR_BO_D_EQ_C.B04_BSEG_BELNR = P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BELNR)

-- Create index to resolve performance issues
CREATE INDEX AUGBL
ON P08_T24_03_TT_FIN_GL_NO_BTB (B04_BSEG_AUGBL);
CREATE INDEX BUKRS
ON P08_T24_03_TT_FIN_GL_NO_BTB (B04_BSEG_BUKRS);
CREATE INDEX GJAHR
ON P08_T24_03_TT_FIN_GL_NO_BTB (B04_BSEG_GJAHR);
CREATE INDEX BELNR
ON P08_T24_03_TT_FIN_GL_NO_BTB (B04_BSEG_BELNR);
CREATE INDEX AUGDT
ON P08_T24_03_TT_FIN_GL_NO_BTB (B04_BSEG_AUGDT);

-- Step 5/ Create a list of matching keys per journal entry number 
--        DISTINCT to ensure no duplication
SET @errormsg = 'Create a list of matching keys per journal entry number '
RAISERROR (@errormsg, 0, 1) WITH NOWAIT
EXEC SP_DROPTABLE 'P08_T24_04_TT_LIST_BELNR_AUGBL'
SELECT DISTINCT P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS,
              P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_GJAHR,
              P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BELNR,
              P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_AUGBL,
             P08_T24_03_TT_FIN_GL_NO_BTB. B04_BSEG_AUGDT
INTO P08_T24_04_TT_LIST_BELNR_AUGBL
FROM P08_T24_03_TT_FIN_GL_NO_BTB
WHERE ISNULL(P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_AUGBL, '') <> ''

CREATE INDEX AUGBL ON P08_T24_04_TT_LIST_BELNR_AUGBL (B04_BSEG_AUGBL);
CREATE INDEX BUKRS ON P08_T24_04_TT_LIST_BELNR_AUGBL (B04_BSEG_BUKRS);
CREATE INDEX GJAHR ON P08_T24_04_TT_LIST_BELNR_AUGBL (B04_BSEG_GJAHR);
CREATE INDEX BELNR ON P08_T24_04_TT_LIST_BELNR_AUGBL (B04_BSEG_BELNR);
CREATE INDEX AUGDT ON P08_T24_04_TT_LIST_BELNR_AUGBL (B04_BSEG_AUGDT);

-- Step 6/ Create a list of payroll journal entries AND add the document type
SET @errormsg = 'Create a list of payroll journal entries AND add the document type'
RAISERROR (@errormsg, 0, 1) WITH NOWAIT
EXEC SP_DROPTABLE 'P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE'
SELECT DISTINCT 
              P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS, 
              P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_GJAHR, 
              P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BELNR,
              'Payroll journal entry' ZF_DOCUMENT_TYPE 
INTO P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE
FROM P08_T24_03_TT_FIN_GL_NO_BTB
-- Filter on payroll lines, based on payroll account
INNER JOIN AM_SPEND_CATEGORY
       ON  P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_HKONT = AM_SPEND_CATEGORY.SPCAT_GL_ACCNT
              AND (AM_SPEND_CATEGORY.SPCAT_SPEND_CAT_LEVEL_3 LIKE '%' + 'SALARIES' + '%' 
					OR AM_SPEND_CATEGORY.SPCAT_SPEND_CAT_LEVEL_3 LIKE '%' + 'SALARY' + '%' 
					OR AM_SPEND_CATEGORY.SPCAT_SPEND_CAT_LEVEL_3 LIKE '%' + 'WAGE'  + '%')
EXEC SP_CREATE_INDEX 'B04_BSEG_BUKRS, B04_BSEG_GJAHR, B04_BSEG_BELNR', 'P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE'

                                                 
-- Step 7/ Create a list of supplier journal entries AND add the document type AND third party type
SET @errormsg = 'Create a list of supplier journal entries AND add the document type AND third party type'
RAISERROR (@errormsg, 0, 1) WITH NOWAIT
EXEC SP_DROPTABLE 'P08_T24_06_TT_SUPP_BELNR_DOC_TYPE'
SELECT DISTINCT
              B07B_BSAIK_BUKRS,    
              B07B_BSAIK_GJAHR,    
              B07B_BSAIK_BELNR,    
		CASE
			--WHEN B07B_ZF_EMP_INV = 'X' THEN 'Employee invoice'
			--WHEN B07B_ZF_EMP_INV_CANC = 'X' THEN 'Employee invoice cancellation' 
			--WHEN B07B_ZF_EMP_PAY_CANC = 'X' THEN 'Employee payment cancellation'
			--WHEN B07B_ZF_INTERCO_INV = 'X' THEN 'Supplier intercompany invoice'
			--WHEN B07B_ZF_INTERCO_CANC = 'X' THEN 'Supplier intercompany invoice cancellation'
			WHEN B07B_ZF_SUPP_INV = 'X' THEN 'Supplier invoice'
			WHEN B07B_ZF_SUPP_INV_CANC = 'X' THEN 'Supplier invoice cancellation'
			--WHEN B07B_ZF_INTERCO_PAY_CANC = 'X' THEN 'Intercompany payment cancellation' 
			--WHEN B07B_ZF_EMP_PAY = 'X' THEN 'Employee payment'
			WHEN B07B_ZF_SUPP_PAY = 'X' THEN 'Supplier payment'
			WHEN B07B_ZF_SUPP_PAY_CANC = 'X' THEN 'Supplier payment cancellation'
			ELSE 'Supplier uncategorized' 
		END ZF_DOCUMENT_TYPE,
		B07B_BSAIK_BUZEI,
		'Supplier' ZF_THIRD_PARTY_TYPE
INTO P08_T24_06_TT_SUPP_BELNR_DOC_TYPE
FROM B07_03_IT_FIN_AP_INV_PAY_FLAGS
EXEC SP_CREATE_INDEX 'B07B_BSAIK_BUKRS, B07B_BSAIK_GJAHR, B07B_BSAIK_BELNR, B07B_BSAIK_BUZEI', 'P08_T24_06_TT_SUPP_BELNR_DOC_TYPE'


-- Step 8/ Create a list of customer journal entries AND add the document type AND third party type
SET @errormsg = 'Create a list of customer journal entries AND add the document type AND third party type'
RAISERROR (@errormsg, 0, 1) WITH NOWAIT
EXEC SP_REMOVE_TABLES 'P08_T24_07_TT_CUST_BELNR_DOC_TYPE'
SELECT DISTINCT B07D_BSAID_BUKRS,
                B07D_BSAID_GJAHR,
                B07D_BSAID_BELNR,
                B07D_ZF_AR_DOC_TYPE_BUCKET ZF_DOCUMENT_TYPE,
				B07D_BSAID_BUZEI,
                'Customer' ZF_THIRD_PARTY_TYPE
                                                                
INTO P08_T24_07_TT_CUST_BELNR_DOC_TYPE
FROM B07_04_IT_FIN_AR_INV_PAY_FLAGS
EXEC SP_CREATE_INDEX 'B07D_BSAID_BUKRS, B07D_BSAID_GJAHR, B07D_BSAID_BELNR, B07D_BSAID_BUZEI', 'P08_T24_07_TT_CUST_BELNR_DOC_TYPE'

-- Step 9/ Create a list of journal entries for bank out AND add the documen type

-- 9.1/ List of bank-out journal entries
SET @errormsg = 'List of bank-out journal entries'
RAISERROR (@errormsg, 0, 1) WITH NOWAIT
EXEC SP_DROPTABLE 'P08_T24_08_TT_BO_BELNR_DOC_TYPE'
SELECT DISTINCT 
	P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS, 
	P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_GJAHR, 
	P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BELNR,
	CASE
		WHEN ISNULL(P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_AUGBL, '') <> '' THEN 'Bank out matched'
		ELSE 'Bank out unmatched'
	END ZF_DOCUMENT_TYPE 
                                  
INTO P08_T24_08_TT_BO_BELNR_DOC_TYPE
FROM P08_T24_03_TT_FIN_GL_NO_BTB
-- Filter on bank out lines, based on bank account
INNER JOIN P08_T24_00_TT_AM_BANK_ACC
       ON  P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_HKONT = P08_T24_00_TT_AM_BANK_ACC.GL_BANK_ACC_HKONT
              AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS = P08_T24_00_TT_AM_BANK_ACC.GL_BANK_ACC_BUKRS
			   
-- Check if there is a matching key - to know if it is matched or unmatched bank out 
LEFT JOIN P08_T24_04_TT_LIST_BELNR_AUGBL
       ON P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS = P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_BUKRS
       AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_GJAHR = P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_GJAHR
       AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BELNR = P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_BELNR
-- Filter on bank out lines, based on credit indicator
WHERE P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_SHKZG = 'H'

EXEC SP_CREATE_INDEX 'B04_BSEG_BUKRS, B04_BSEG_GJAHR, B04_BSEG_BELNR', 'P08_T24_08_TT_BO_BELNR_DOC_TYPE'
			                                      
-- Step 10 Create a list of journal entry numbers + matching key for all documents that are bank related 
--        This is the step where we do the matching 

-- Step 10.1: JEs + matching key for bank out
--           Excluding those matching keys for which total bank out debit = total bank out credit 
SET @errormsg = 'JEs + matching key for bank out'
RAISERROR (@errormsg, 0, 1) WITH NOWAIT
EXEC SP_DROPTABLE 'P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL'
SELECT DISTINCT 
              P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS, 
              P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_GJAHR, 
              P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BELNR,
              -- Copy matching key on all lines: Keep matching key if exists on bank-out line 
              IIF(ISNULL(P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_AUGBL, '') <> '', P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_AUGBL, P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_AUGBL) B04_BSEG_AUGBL,
              IIF(ISNULL(P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_AUGDT,'') <> '', P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_AUGDT, P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_AUGDT) B04_BSEG_AUGDT
INTO P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL
FROM P08_T24_03_TT_FIN_GL_NO_BTB

-- Filter on bank out lines, based on bank account
INNER JOIN P08_T24_00_TT_AM_BANK_ACC
       ON  P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_HKONT = P08_T24_00_TT_AM_BANK_ACC.GL_BANK_ACC_HKONT
              AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS = P08_T24_00_TT_AM_BANK_ACC.GL_BANK_ACC_BUKRS

-- Add the matching key on all lines 
-- !!!!!!! Note this step may duplicate the lines for bank-out if there is  more than
-- A pro-rata value is calculated in step 12 to cater for this

LEFT JOIN P08_T24_04_TT_LIST_BELNR_AUGBL
       ON P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS = P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_BUKRS
       AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_GJAHR = P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_GJAHR
       AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BELNR = P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_BELNR

-- Filter on bank out lines, based on credit indicator
WHERE P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_SHKZG = 'H'


--EXEC SP_CREATE_INDEX 'B04_BSEG_BUKRS, B04_BSEG_GJAHR, B04_BSEG_BELNR', 'P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL'

-- Step 10.2 Create unique tables for filtering (in step 6.4): Check that the matching key is found
SET @errormsg = 'Create unique tables for filtering (in step 6.4): Check that the matching key is found'
RAISERROR (@errormsg, 0, 1) WITH NOWAIT
EXEC SP_DROPTABLE 'P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL'
SELECT DISTINCT B04_BSEG_BUKRS, B04_BSEG_AUGBL, B04_BSEG_AUGDT INTO P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL FROM P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL
EXEC SP_CREATE_INDEX 'B04_BSEG_BUKRS, B04_BSEG_AUGBL, B04_BSEG_AUGDT', 'P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL'

-- Step 10.3 Create unique tables for filtering (in step 6.4): Check that the document number key is NOT found
SET @errormsg = 'Create unique tables for filtering (in step 6.4): Check that the document number key is NOT found'
RAISERROR (@errormsg, 0, 1) WITH NOWAIT
EXEC SP_DROPTABLE 'P08_T24_11_TT_UNIQUE_LIST_BO_BELNR'
SELECT DISTINCT B04_BSEG_BUKRS, B04_BSEG_GJAHR, B04_BSEG_BELNR INTO P08_T24_11_TT_UNIQUE_LIST_BO_BELNR FROM P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL
EXEC SP_CREATE_INDEX 'B04_BSEG_BUKRS, B04_BSEG_GJAHR, B04_BSEG_BELNR', 'P08_T24_11_TT_UNIQUE_LIST_BO_BELNR'

-- Step 10.4 Concatenate journal entry numbers to the list that are:
--          1/ Matched to a bank out
--          2/ Are not a bank out themselves 
SET @errormsg = 'Concatenate journal entry numbers to the list'
RAISERROR (@errormsg, 0, 1) WITH NOWAIT
INSERT INTO P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL
SELECT 
        P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_BUKRS, 
        P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_GJAHR, 
        P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_BELNR,
        P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_AUGBL,
        P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_AUGDT

FROM P08_T24_04_TT_LIST_BELNR_AUGBL

        -- OUTER APPLY with WHERE to check whether or not the matching key is found in the list of bank out
        -- (include only these)
		-- use ISNULL to prevent matching between unmatched bank out with empty matching key
        OUTER APPLY(SELECT TOP 1 * FROM P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL
                                    WHERE P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL.B04_BSEG_BUKRS  = P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_BUKRS
                                        AND P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL.B04_BSEG_AUGBL  = P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_AUGBL
                                        AND P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL.B04_BSEG_AUGDT  = P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_AUGDT
										AND ISNULL(P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL.B04_BSEG_AUGDT, '') <> '') XTEMP1

        -- OUTER APPLY with WHERE to check whether or not the document number is found in the list of bank out
        -- (exclude these)
        OUTER APPLY(SELECT TOP 1 * FROM P08_T24_11_TT_UNIQUE_LIST_BO_BELNR
                                    WHERE P08_T24_11_TT_UNIQUE_LIST_BO_BELNR.B04_BSEG_BUKRS  = P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_BUKRS
                                        AND P08_T24_11_TT_UNIQUE_LIST_BO_BELNR.B04_BSEG_BELNR  = P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_BELNR
                                        AND P08_T24_11_TT_UNIQUE_LIST_BO_BELNR.B04_BSEG_GJAHR  = P08_T24_04_TT_LIST_BELNR_AUGBL.B04_BSEG_GJAHR) XTEMP2
		-- Where clause to append the matched documents AND exclude those that are already in the file as bank-out
		WHERE XTEMP1.B04_BSEG_AUGBL IS NOT NULL AND XTEMP2.B04_BSEG_BUKRS IS NULL 

CREATE INDEX AUGBL ON P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL (B04_BSEG_AUGBL);
CREATE INDEX BUKRS ON P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL (B04_BSEG_BUKRS);
CREATE INDEX GJAHR ON P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL (B04_BSEG_GJAHR);
CREATE INDEX BELNR ON P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL (B04_BSEG_BELNR);
CREATE INDEX AUGDT ON P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL (B04_BSEG_AUGDT);
           
-- Step 11/ Add the document type to the bank-out related journal entries 
--         Create a unique list of bank-related journal entry numbers AND document types
SET @errormsg = 'Create a unique list of bank-related journal entry numbers AND document types'
RAISERROR (@errormsg, 0, 1) WITH NOWAIT
DELETE P08_T24_03_TT_FIN_GL_NO_BTB
	WHERE NOT EXISTS(
		SELECT TOP 1 1 FROM P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL B
			WHERE B.B04_BSEG_BUKRS = P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS
				AND B.B04_BSEG_GJAHR = P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_GJAHR 
				AND B.B04_BSEG_BELNR = P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BELNR)
		
		AND NOT EXISTS(
		SELECT TOP 1 1 FROM P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL B
			WHERE B.B04_BSEG_BUKRS = P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS
				AND B.B04_BSEG_AUGDT = P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_AUGDT 
				AND B.B04_BSEG_AUGBL = P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_AUGBL)

EXEC SP_DROPTABLE 'P08_T24_12_TT_LIST_BELNR_DOC_TYPE'
SELECT DISTINCT 
	P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_BUKRS, 
	P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_GJAHR, 
	P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_BELNR,
	CASE WHEN ISNULL(P08_T24_06_TT_SUPP_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE, '') <> '' THEN B07B_BSAIK_BUZEI
	ELSE B07D_BSAID_BUZEI END SUPP_CUST_BUZEI,
	-- Add document types: 
	-- !!!!!!!!! Note: 
	-- In the above steps to create lists of journal entry number + document type for:
	--    - payroll, supplier, customer AND bank-out
	--    - one journal entry number might be picked up in more than one list
	-- Therefore prioritise 1/bankout, 2/payroll, 3/suppliers, 4/customers
	CASE 
		--WHEN ISNULL(P08_T24_08_TT_BO_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE, '') <> '' THEN P08_T24_08_TT_BO_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE
		WHEN ISNULL(P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE, '') <> '' THEN P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE
		WHEN ISNULL(P08_T24_06_TT_SUPP_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE, '') <> '' THEN P08_T24_06_TT_SUPP_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE
		WHEN ISNULL(P08_T24_07_TT_CUST_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE, '') <> '' THEN P08_T24_07_TT_CUST_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE
		ELSE 'Uncategorized document type'
	END AS ZF_DOCUMENT_TYPE,

	-- Add third-party type:
	-- Note: 
	-- In the above steps to create lists of journal entry number + third-party type for:
	--    - supplier, custome
	--    - one journal entry number might be picked up in more than one list
	-- Therefore prioritise 1/suppliers, 2/customers		
	ISNULL(ISNULL(P08_T24_06_TT_SUPP_BELNR_DOC_TYPE.ZF_THIRD_PARTY_TYPE, P08_T24_07_TT_CUST_BELNR_DOC_TYPE.ZF_THIRD_PARTY_TYPE), '') ZF_THIRD_PARTY_TYPE 
                                                                
    INTO P08_T24_12_TT_LIST_BELNR_DOC_TYPE
    FROM P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL
		-- Get document types: 
		-- !!!!!!!!! Note: A document might be in more than one list, so prioritise bankout, then payroll, then suppliers, then customers
		-- Get document type from bank-out 
		--LEFT JOIN P08_T24_08_TT_BO_BELNR_DOC_TYPE ON 
  --      P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_BUKRS = P08_T24_08_TT_BO_BELNR_DOC_TYPE.B04_BSEG_BUKRS
  --      AND P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_GJAHR = P08_T24_08_TT_BO_BELNR_DOC_TYPE.B04_BSEG_GJAHR 
  --      AND P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_BELNR = P08_T24_08_TT_BO_BELNR_DOC_TYPE.B04_BSEG_BELNR

        -- Get document type from payroll
        LEFT JOIN P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE ON 
        P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_BUKRS = P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE.B04_BSEG_BUKRS
        AND P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_GJAHR = P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE.B04_BSEG_GJAHR
        AND P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_BELNR = P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE.B04_BSEG_BELNR

        -- Get document type from suppliers
        LEFT JOIN P08_T24_06_TT_SUPP_BELNR_DOC_TYPE ON 
        P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_BUKRS = P08_T24_06_TT_SUPP_BELNR_DOC_TYPE.B07B_BSAIK_BUKRS
        AND P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_GJAHR = P08_T24_06_TT_SUPP_BELNR_DOC_TYPE.B07B_BSAIK_GJAHR 
        AND P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_BELNR = P08_T24_06_TT_SUPP_BELNR_DOC_TYPE.B07B_BSAIK_BELNR

        -- Get document type from customers 
        LEFT JOIN P08_T24_07_TT_CUST_BELNR_DOC_TYPE ON 
        P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_BUKRS = P08_T24_07_TT_CUST_BELNR_DOC_TYPE.B07D_BSAID_BUKRS
        AND P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_GJAHR = P08_T24_07_TT_CUST_BELNR_DOC_TYPE.B07D_BSAID_GJAHR 
        AND P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_BELNR = P08_T24_07_TT_CUST_BELNR_DOC_TYPE.B07D_BSAID_BELNR
		AND B07B_BSAIK_BUZEI = B07D_BSAID_BUZEI
                                       
-- Step 12/ Create indexes to increase performance for the next step
CREATE INDEX B04_BSEG_BELNR_IDX ON P08_T24_12_TT_LIST_BELNR_DOC_TYPE (B04_BSEG_BELNR)
CREATE INDEX B04_BSEG_BUKRS_IDX ON P08_T24_12_TT_LIST_BELNR_DOC_TYPE (B04_BSEG_BUKRS)
CREATE INDEX B04_BSEG_GJAHR_IDX ON P08_T24_12_TT_LIST_BELNR_DOC_TYPE (B04_BSEG_GJAHR)
CREATE INDEX B04_BSEG_BUZEI_IDX ON P08_T24_12_TT_LIST_BELNR_DOC_TYPE (SUPP_CUST_BUZEI)

EXEC SP_DROPTABLE 'P08_T24_13_TT_LIST_BELNR_DOC_LIST'
SELECT DISTINCT B04_BSEG_BUKRS, B04_BSEG_GJAHR, B04_BSEG_BELNR INTO P08_T24_13_TT_LIST_BELNR_DOC_LIST FROM P08_T24_12_TT_LIST_BELNR_DOC_TYPE
EXEC SP_CREATE_INDEX 'B04_BSEG_BUKRS, B04_BSEG_GJAHR, B04_BSEG_BELNR', 'P08_T24_13_TT_LIST_BELNR_DOC_LIST'

-- Step 13/ Filter the general ledger on bank-out related journal entries 
--          Add the document type field 
--          Add the third-party type field
--          Add the line type field  (used to filter relevant lines for the QLIK bar chart)
--          Add the matching key on all lines (to enable join between detailed table AND QLIK bar chart)
--          !! - some duplication will occur for cases for which there is more than one matching key per journal entry number 
SET @errormsg = 'Filter the general ledger on bank-out related journal entries'
RAISERROR (@errormsg, 0, 1) WITH NOWAIT

	EXEC SP_DROPTABLE 'P08_T24_13_TT_BANK_OUT_REL_JES'
	SELECT  P08_T24_03_TT_FIN_GL_NO_BTB.*,
				  LFA1_NAME1,
				  KNA1_NAME1,
				  T001_WAERS,
				  -- Add flexible join key that follows: if the AUGBL field is NULL or '' then use BUKRS+BELNR+GJAHR
				  ISNULL(P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_AUGBL, P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BELNR) ZF_AUGBL_BELNR_KEY,
				  ISNULL(P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_AUGDT, P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_GJAHR) ZF_AUGDT_GJAHR_KEY,
				  -- Add the matching key on all lines so that we can do the following in QLIK:
				  --   1/ filter the dashboard 
				  --   2/ link detailed table to bar chart
				  P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_AUGBL ZF_BSEG_AUGBL_FILLED,
				  P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_AUGDT ZF_BSEG_AUGDT_FILLED,

				  -- Create the payment month for the filter
				  -- -- Take the AUGDT for the payment date, if the document is matched
				  -- -- Take BUDAT for unmatched payments
				  -- -- Note:
				  -- -- --  if the document number does not have a matching date, then it is an unmatched payment 
				  -- -- -- (due to exclusion in step 6.4 of all non-bank items that are not matched to bank)
				  -- -- -- Therefore, we can assume that in this case BUDAT is the payment month
				  CASE 
						 WHEN ISNULL(P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_AUGDT, '') <> '' THEN EOMONTH(P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_AUGDT)          
						 ELSE EOMONTH(P08_T24_03_TT_FIN_GL_NO_BTB.B04_BKPF_BUDAT)
				  END ZF_PAYMENT_MONTH,

				  -- Create the document month for the x-axis of the bar-chart:
				  -- In order to split the bank-out month into one bar for bank-out AND one bar for source documents:
				  -- -- If it is a bank out line, then we take the end of the month 
				  -- -- Else we take the beginning of the month
				  IIF(P08_T24_00_TT_AM_BANK_ACC.GL_BANK_ACC_HKONT IS NOT NULL AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_SHKZG = 'H',
					  EOMONTH(P08_T24_03_TT_FIN_GL_NO_BTB.B04_BKPF_BUDAT),
					  DATEADD(MONTH, DATEDIFF(MONTH, 0, P08_T24_03_TT_FIN_GL_NO_BTB.B04_BKPF_BUDAT), 0)) ZF_DOCUMENT_MONTH,
             

				  P08_T24_12_TT_LIST_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE,
				  -- Field for the bar chart dimension AND also to ignore lines that are counterparty lines 
				  -- within the same journal entry
				  CASE
						 -- Bank out lines 
						 WHEN P08_T24_00_TT_AM_BANK_ACC.GL_BANK_ACC_HKONT IS NOT NULL
								--AND P08_T24_08_TT_BO_BELNR_DOC_TYPE.B04_BSEG_BELNR IS NOT NULL 
								AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_SHKZG = 'H' 
							THEN P08_T24_08_TT_BO_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE
                     
						 -- Payroll lines for which the document type is payroll 
						 WHEN P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL.B04_BSEG_AUGBL IS NOT NULL 
								AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_SHKZG = 'H' 
								AND P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE.B04_BSEG_BUKRS IS NOT NULL 
								AND P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE = 'Payroll journal entry' 
							THEN P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE
                                                                                                                                                                                
						 -- Supplier lines for which the document type is for supplier 
						 WHEN P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL.B04_BSEG_AUGBL IS NOT NULL 
								 AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_SHKZG = 'H' 
								 AND B04_BSEG_KOART = 'K' 
								 AND P08_T24_12_TT_LIST_BELNR_DOC_TYPE.ZF_THIRD_PARTY_TYPE = 'Supplier' 
								 AND P08_T24_12_TT_LIST_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE NOT IN ('Bank out unmatched', 'Bank out matched', 'Payroll') 
							THEN P08_T24_12_TT_LIST_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE
                                                                                
						-- Customer lines for which the document type is for customer 
						WHEN P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL.B04_BSEG_AUGBL IS NOT NULL 
								AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_SHKZG = 'H' 
								AND B04_BSEG_KOART = 'D' 
								AND P08_T24_12_TT_LIST_BELNR_DOC_TYPE.ZF_THIRD_PARTY_TYPE = 'Customer' 
								AND P08_T24_12_TT_LIST_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE NOT IN ('Bank out unmatched', 'Bank out matched', 'Payroll') 
							THEN P08_T24_12_TT_LIST_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE
                     
						 -- Matrials lines for which the document type is not bank-out, payroll, supplier or customer 
						 WHEN P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL.B04_BSEG_AUGBL IS NOT NULL 
								 AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_SHKZG = 'H' 
								 AND B04_BSEG_KOART = 'M' 
								 AND P08_T24_12_TT_LIST_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE NOT IN ('Bank out unmatched', 'Bank out matched', 'Payroll') 
								 AND P08_T24_12_TT_LIST_BELNR_DOC_TYPE.ZF_THIRD_PARTY_TYPE NOT IN('Customer', 'Supplier') 
							THEN 'Materials'
                    
						 -- Fixed assets lines for which the document type is not bank-out, payroll, supplier or customer 
						 WHEN P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL.B04_BSEG_AUGBL IS NOT NULL 
								 AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_SHKZG = 'H' 
								 AND B04_BSEG_KOART = 'A' 
								 AND P08_T24_12_TT_LIST_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE NOT IN ('Bank out unmatched' ,'Bank out matched' ,'Payroll') 
								 AND P08_T24_12_TT_LIST_BELNR_DOC_TYPE.ZF_THIRD_PARTY_TYPE NOT IN('Customer' ,'Supplier') 
						 THEN 'Fixed assets'
                                                                                
						-- G/L lines for which the document type is not bank-out, payroll, supplier or customer 
						WHEN P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL.B04_BSEG_AUGBL IS NOT NULL 
						AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_SHKZG = 'H' 
						AND B04_BSEG_KOART = 'S' 
						AND P08_T24_12_TT_LIST_BELNR_DOC_TYPE.ZF_DOCUMENT_TYPE NOT IN ('Bank out unmatched' ,'Bank out matched' ,'Payroll') 
						AND P08_T24_12_TT_LIST_BELNR_DOC_TYPE.ZF_THIRD_PARTY_TYPE NOT IN('Customer' ,'Supplier') 
						THEN 'G/L accounts '
                                                                                
						-- Ignore all lines that are counterparty lines of the above (for example, supplier line within a bank-out journal entry)
				  ELSE 'Line not included in bar chart'
		   END AS ZF_LINE_TYPE                  
		   INTO P08_T24_13_TT_BANK_OUT_REL_JES
		   FROM P08_T24_03_TT_FIN_GL_NO_BTB
                   
                   
		   -- Filter the general ledger on the bank out transactions AND their source documents AND add the document type   
		   INNER JOIN P08_T24_13_TT_LIST_BELNR_DOC_LIST B ON 
				 P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS = B.B04_BSEG_BUKRS
				 AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_GJAHR = B.B04_BSEG_GJAHR
				 AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BELNR = B.B04_BSEG_BELNR
			  
		   LEFT JOIN P08_T24_12_TT_LIST_BELNR_DOC_TYPE ON 
				 P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS = P08_T24_12_TT_LIST_BELNR_DOC_TYPE.B04_BSEG_BUKRS
				 AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_GJAHR = P08_T24_12_TT_LIST_BELNR_DOC_TYPE.B04_BSEG_GJAHR
				 AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BELNR = P08_T24_12_TT_LIST_BELNR_DOC_TYPE.B04_BSEG_BELNR
				 AND B04_BSEG_BUZEI = P08_T24_12_TT_LIST_BELNR_DOC_TYPE.SUPP_CUST_BUZEI
			-- Add the matching key on all lines 
			-- (!!!!!!!this join will create duplication if more than one matching key per journal entry number)
			-- This problem is hANDled by pro-rata value calculation below
			LEFT JOIN P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL ON 
				P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS = P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_BUKRS
				AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_GJAHR = P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_GJAHR
				AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BELNR = P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_BELNR               
      
		   -- Join to the bank account numbers so that we can create the flag for bank-out lines
			LEFT JOIN P08_T24_00_TT_AM_BANK_ACC
				ON  P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_HKONT = P08_T24_00_TT_AM_BANK_ACC.GL_BANK_ACC_HKONT
				AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS = P08_T24_00_TT_AM_BANK_ACC.GL_BANK_ACC_BUKRS

			LEFT JOIN P08_T24_08_TT_BO_BELNR_DOC_TYPE
				on P08_T24_08_TT_BO_BELNR_DOC_TYPE.B04_BSEG_BELNR = P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BELNR
				AND P08_T24_08_TT_BO_BELNR_DOC_TYPE.B04_BSEG_BUKRS = P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS
				AND P08_T24_08_TT_BO_BELNR_DOC_TYPE.B04_BSEG_GJAHR = P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_GJAHR
		   -- Join to the payroll account numbers so that we can create the flag for payroll lines
		   LEFT JOIN P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE
		   ON P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS = P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE.B04_BSEG_BUKRS
				AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_GJAHR = P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE.B04_BSEG_GJAHR
				AND P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BELNR = P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE.B04_BSEG_BELNR
	   
		   -- Check if the matching key belongs to bank out, otherwise we ignore
		   -- (because more than one matching key per journal entry)
		   LEFT JOIN P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL ON 
				P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_BUKRS = P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL.B04_BSEG_BUKRS
				AND P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_AUGDT = P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL.B04_BSEG_AUGDT
				AND P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL.B04_BSEG_AUGBL = P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL.B04_BSEG_AUGBL        

		   -- Add the supplier name
		   LEFT JOIN A_LFA1 ON
				LFA1_LIFNR = P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_LIFNR

		   -- Add the customer name
		   LEFT JOIN A_KNA1 ON 
				B04_BSEG_KUNNR = KNA1_KUNNR

			LEFT JOIN A_T001 ON T001_BUKRS = P08_T24_03_TT_FIN_GL_NO_BTB.B04_BSEG_BUKRS
		WHERE P08_T24_10_TT_UNIQUE_LIST_BO_AUGBL.B04_BSEG_AUGBL IS NOT NULL 
			OR P08_T24_08_TT_BO_BELNR_DOC_TYPE.B04_BSEG_BELNR IS NOT NULL

	-- Step 14/ For the detailed table in QLIK, SELECT DISTINCT  to remove any duplication

		EXEC SP_DROPTABLE 'P08_T24_14_RT_BANK_OUT_DETAIL_TABLE'
		SELECT DISTINCT * INTO P08_T24_14_RT_BANK_OUT_DETAIL_TABLE FROM P08_T24_13_TT_BANK_OUT_REL_JES 

	
	-- Step 15/ For the bar chart in QLIK, remove lines that are not categorized

		EXEC SP_DROPTABLE 'P08_T24_15_TT_BANK_OUT_REM_IGNORE'
		SELECT *
		INTO P08_T24_15_TT_BANK_OUT_REM_IGNORE
		FROM P08_T24_14_RT_BANK_OUT_DETAIL_TABLE 
		WHERE ZF_LINE_TYPE <> 'Line not included in bar chart'



	-- Step 16/ Add ZF_LIST_LINE_TYPES_PER_AUGBL to show the list of document types per matching key

	--  16.1 Create a unique list of document types per matching key

		EXEC SP_DROPTABLE 'P08_T24_16_TT_LIST_AUGBL_DOC_TYPE'
		SELECT B04_BSEG_BUKRS, ZF_BSEG_AUGBL_FILLED, ZF_BSEG_AUGDT_FILLED, ZF_LINE_TYPE
		INTO P08_T24_16_TT_LIST_AUGBL_DOC_TYPE	
		FROM P08_T24_15_TT_BANK_OUT_REM_IGNORE
		GROUP BY B04_BSEG_BUKRS, ZF_BSEG_AUGBL_FILLED, ZF_BSEG_AUGDT_FILLED, ZF_LINE_TYPE


		--  13.2 Make a table with one line per matching key AND a list of document types for each matching key

		EXEC SP_DROPTABLE 'P08_T24_17_TT_LIST_AUGBL_DOC_TYPE'
		SELECT 
		B04_BSEG_BUKRS,
		ZF_BSEG_AUGBL_FILLED, 
		ZF_BSEG_AUGDT_FILLED
		--Create a list of document types
		 ,DBO.TRIM(STUFF((SELECT ', ' + ZF_LINE_TYPE
		 FROM P08_T24_16_TT_LIST_AUGBL_DOC_TYPE b
		 WHERE (b.B04_BSEG_BUKRS = P08_T24_16_TT_LIST_AUGBL_DOC_TYPE.B04_BSEG_BUKRS  
			AND b.ZF_BSEG_AUGBL_FILLED = P08_T24_16_TT_LIST_AUGBL_DOC_TYPE.ZF_BSEG_AUGBL_FILLED
			AND b.ZF_BSEG_AUGDT_FILLED = P08_T24_16_TT_LIST_AUGBL_DOC_TYPE.ZF_BSEG_AUGDT_FILLED)
		 GROUP BY ZF_LINE_TYPE
		 FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)'),1,1,'')) ZF_LIST_LINE_TYPES_PER_AUGBL
		INTO P08_T24_17_TT_LIST_AUGBL_DOC_TYPE
		FROM P08_T24_16_TT_LIST_AUGBL_DOC_TYPE
		--USE GROUP BY TO AVOID DUPLICATION
		GROUP BY 	
			B04_BSEG_BUKRS,
			ZF_BSEG_AUGBL_FILLED, 
			ZF_BSEG_AUGDT_FILLED



	-- Step 17/ Count how many times a journal entry line occurs

		EXEC SP_DROPTABLE 'P08_T24_18_TT_NUM_OCC_JELINE'
		SELECT 
				COUNT(*) AS ZF_NUM_OCCURENCES, 
				B04_BSEG_BUKRS,
				B04_BSEG_GJAHR,
				B04_BSEG_BELNR,
				B04_BSEG_BUZEI
		INTO P08_T24_18_TT_NUM_OCC_JELINE
		FROM P08_T24_15_TT_BANK_OUT_REM_IGNORE
		GROUP BY      
				B04_BSEG_BUKRS,
				B04_BSEG_GJAHR,
				B04_BSEG_BELNR,
				B04_BSEG_BUZEI




	-- Step 18/ Create final table for Bar-Chart
	--         Add back:
	--         -- List of document types per matching key
	--         -- Number of occurrences per journal entry line
	--         -- Calculate pro-rata value for journal entry lines that were repeated

		EXEC SP_DROPTABLE 'P08_T24_19_RT_BANK_OUT_BAR_CHART'
		SELECT P08_T24_15_TT_BANK_OUT_REM_IGNORE.*,
				ZF_LIST_LINE_TYPES_PER_AUGBL,
				B04_ZF_BSEG_DMBE2_S / ZF_NUM_OCCURENCES ZF_BSEG_DMBE2_S_PRORATA,
				B04_ZF_BSEG_DMBE3_S / ZF_NUM_OCCURENCES ZF_BSEG_DMBE3_S_PRORATA,
				B04_ZF_BSEG_DMBTR_S / ZF_NUM_OCCURENCES ZF_BSEG_DMBTR_S_PRORATA,
				B04_ZF_BSEG_DMBTR_S_CUC / ZF_NUM_OCCURENCES ZF_BSEG_DMBTR_S_CUC_PRORATA
		INTO P08_T24_19_RT_BANK_OUT_BAR_CHART
		FROM P08_T24_15_TT_BANK_OUT_REM_IGNORE

		-- Add the list of document types per matching key
		LEFT JOIN P08_T24_17_TT_LIST_AUGBL_DOC_TYPE ON
			 P08_T24_17_TT_LIST_AUGBL_DOC_TYPE.B04_BSEG_BUKRS = P08_T24_15_TT_BANK_OUT_REM_IGNORE.B04_BSEG_BUKRS AND
			 P08_T24_17_TT_LIST_AUGBL_DOC_TYPE.ZF_BSEG_AUGBL_FILLED = P08_T24_15_TT_BANK_OUT_REM_IGNORE.ZF_BSEG_AUGBL_FILLED AND 
			 P08_T24_17_TT_LIST_AUGBL_DOC_TYPE.ZF_BSEG_AUGDT_FILLED = P08_T24_15_TT_BANK_OUT_REM_IGNORE.ZF_BSEG_AUGDT_FILLED

		-- Add the number of occurrences of a journal entry line in case of duplication of the journal entry line
		LEFT JOIN P08_T24_18_TT_NUM_OCC_JELINE ON
				P08_T24_15_TT_BANK_OUT_REM_IGNORE.B04_BSEG_BUKRS = P08_T24_18_TT_NUM_OCC_JELINE.B04_BSEG_BUKRS
				AND P08_T24_15_TT_BANK_OUT_REM_IGNORE.B04_BSEG_GJAHR = P08_T24_18_TT_NUM_OCC_JELINE.B04_BSEG_GJAHR
				AND P08_T24_15_TT_BANK_OUT_REM_IGNORE.B04_BSEG_BELNR = P08_T24_18_TT_NUM_OCC_JELINE.B04_BSEG_BELNR
				AND P08_T24_15_TT_BANK_OUT_REM_IGNORE.B04_BSEG_BUZEI = P08_T24_18_TT_NUM_OCC_JELINE.B04_BSEG_BUZEI


	/*Rename fields for Qlik*/

	EXEC SP_UNNAME_FIELD 'B04_', 'P08_T24_14_RT_BANK_OUT_DETAIL_TABLE'
	EXEC SP_RENAME_FIELD 'P08_', 'P08_T24_14_RT_BANK_OUT_DETAIL_TABLE'
	EXEC SP_UNNAME_FIELD 'B04_', 'P08_T24_19_RT_BANK_OUT_BAR_CHART'
	EXEC SP_RENAME_FIELD 'P08B_', 'P08_T24_19_RT_BANK_OUT_BAR_CHART'


	/*Remove temporary tables*/

	/*

	EXEC SP_DROPTABLE 'P08_T24_00_TT_AM_BANK_ACC'
	EXEC SP_DROPTABLE 'P08_T24_04_TT_LIST_BELNR_AUGBL'                                           
	EXEC SP_DROPTABLE 'P08_T24_05_TT_PAYROLL_BELNR_DOC_TYPE'
	EXEC SP_DROPTABLE 'P08_T24_06_TT_SUPP_BELNR_DOC_TYPE'
	EXEC SP_DROPTABLE 'P08_T24_07_TT_CUST_BELNR_DOC_TYPE'
	EXEC SP_DROPTABLE 'P08_T24_08_TT_BO_BELNR_DOC_TYPE'
	EXEC SP_DROPTABLE 'P08_T24_09_TT_LIST_BANK_REL_BELNR_AUGBL'
	EXEC SP_DROPTABLE 'P08_T24_12_TT_LIST_BELNR_DOC_TYPE'
	EXEC SP_DROPTABLE 'P08_T24_13_TT_BANK_OUT_REL_JES'
	EXEC SP_DROPTABLE 'P08_T24_14_RT_BANK_OUT_DETAIL_TABLE'
	EXEC SP_DROPTABLE 'P08_T24_15_TT_BANK_OUT_REM_IGNORE'
	EXEC SP_DROPTABLE 'P08_T24_16_TT_LIST_AUGBL_DOC_TYPE'
	EXEC SP_DROPTABLE 'P08_T24_17_TT_LIST_AUGBL_DOC_TYPE'
	EXEC SP_DROPTABLE 'P08_T24_18_TT_NUM_OCC_JELINE'

	*/

	/* log cube creation*/

	INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
	SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','P08_T24_14_RT_BANK_OUT_DETAIL_TABLE',(SELECT COUNT(*) FROM P08_T24_14_RT_BANK_OUT_DETAIL_TABLE) 
	SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','P08_T24_19_RT_BANK_OUT_BAR_CHART',(SELECT COUNT(*) FROM P08_T24_19_RT_BANK_OUT_BAR_CHART) 


	/* log end of procedure*/


	INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
	SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL
GO
