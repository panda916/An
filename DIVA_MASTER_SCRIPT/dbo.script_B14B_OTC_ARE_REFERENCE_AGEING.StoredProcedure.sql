USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROC[dbo].[script_B14B_OTC_ARE_REFERENCE_AGEING]
AS
--DYNAMIC_SCRIPT_START

/*  Change history comments
	Update history 
	-------------------------------------------------------
	Date            | Who   |  Description 
	23-03-2022	| Thuan	| Remove MANDT field in join
*/

BEGIN
    /*
        Step 1: 
            List all AR documents have an assignmet number and debit/credit indicator is debit.
    */
	EXEC SP_REMOVE_TABLES 'B14B_01_TT_AR_ASSIGMENT_DOCS'     
	SELECT DISTINCT
        B14_BSAID_MANDT,
		B14_BSAID_BUKRS,
		B14_BSAID_GJAHR,
		B14_BSAID_BELNR,
		B14_BSAID_BUZEI,
		B14_BSAID_BLDAT,
        B14_BSAID_ZUONR,
		B14_ZF_BSAID_DMBTR_COC
	INTO B14B_01_TT_AR_ASSIGMENT_DOCS
	FROM B14_06_IT_ARE A    
	WHERE B14_BSAID_XBLNR = B14_BSAID_ZUONR AND ISNULL(B14_BSAID_ZUONR, '') <> '' AND B14_ZF_BSAID_SHKZG_DESC = 'Debit'


    /*
        Step 2: 
            List all documents offset value of all document we gets at step 1.
            Only keep one documents if we got many one offset value for a document in step 1.
    */
    EXEC SP_REMOVE_TABLES 'B14B_02_TT_OFFSET_DOCS'
    ;WITH OFFSET_TEMP AS (
        SELECT DISTINCT
            B14_06_IT_ARE.B14_BSAID_MANDT,
            B14_06_IT_ARE.B14_BSAID_BUKRS,
            B14_06_IT_ARE.B14_BSAID_GJAHR,
            B14_06_IT_ARE.B14_BSAID_BELNR,
            B14_06_IT_ARE.B14_BSAID_BUZEI,
            B14_06_IT_ARE.B14_BSAID_ZUONR,
            DATEDIFF(DD , B14B_01_TT_AR_ASSIGMENT_DOCS.B14_BSAID_BLDAT, B14_06_IT_ARE.B14_BSAID_BLDAT) B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT,
            ROW_NUMBER() OVER (
                PARTITION BY B14_06_IT_ARE.B14_BSAID_BUKRS,
                             B14_06_IT_ARE.B14_BSAID_GJAHR,
                             B14_06_IT_ARE.B14_BSAID_BELNR,
                             B14_06_IT_ARE.B14_BSAID_BUZEI
                ORDER BY B14B_01_TT_AR_ASSIGMENT_DOCS.B14_BSAID_BLDAT ASC
            ) ROW_ID
        FROM B14_06_IT_ARE
        INNER JOIN B14B_01_TT_AR_ASSIGMENT_DOCS
        ON  B14_06_IT_ARE.B14_BSAID_BUKRS = B14B_01_TT_AR_ASSIGMENT_DOCS.B14_BSAID_BUKRS AND
            B14_06_IT_ARE.B14_BSAID_ZUONR = B14B_01_TT_AR_ASSIGMENT_DOCS.B14_BSAID_ZUONR AND
            B14_06_IT_ARE.B14_BSAID_ZUONR <> '' AND
            (B14_06_IT_ARE.B14_ZF_BSAID_DMBTR_COC + B14B_01_TT_AR_ASSIGMENT_DOCS.B14_ZF_BSAID_DMBTR_COC) < 0.2
    )  
    SELECT DISTINCT 
            B14_BSAID_MANDT,
            B14_BSAID_BUKRS,
            B14_BSAID_GJAHR,
            B14_BSAID_BELNR,
            B14_BSAID_BUZEI,
            B14_BSAID_ZUONR,
            B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT
    INTO B14B_02_TT_OFFSET_DOCS
    FROM OFFSET_TEMP
    WHERE ROW_ID = 1


    /*
        Step 3: Combine open invoices and offset of open invoices to one table.
    */
    EXEC SP_REMOVE_TABLES 'B14B_03_TT_ASSIGMENT_DOCS_FULL'
    SELECT DISTINCT
            B14_BSAID_MANDT,
            B14_BSAID_BUKRS,
            B14_BSAID_GJAHR,
            B14_BSAID_BELNR,
            B14_BSAID_BUZEI,
            B14_BSAID_ZUONR,
            NULL B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT,
            '1. Original' B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT_BUCKET
    INTO B14B_03_TT_ASSIGMENT_DOCS_FULL
    FROM B14B_01_TT_AR_ASSIGMENT_DOCS
    UNION
    SELECT DISTINCT
            B14_BSAID_MANDT,
            B14_BSAID_BUKRS,
            B14_BSAID_GJAHR,
            B14_BSAID_BELNR,
            B14_BSAID_BUZEI,
            B14_BSAID_ZUONR,
            NULL,
            '2. Open'
    FROM B14B_01_TT_AR_ASSIGMENT_DOCS
    UNION
    SELECT DISTINCT
            B14_BSAID_MANDT,
            B14_BSAID_BUKRS,
            B14_BSAID_GJAHR,
            B14_BSAID_BELNR,
            B14_BSAID_BUZEI,
            B14_BSAID_ZUONR,
            B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT,
            CASE          
				WHEN B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT < 0 THEN '3. < 0'          
				WHEN B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT > -1 AND B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT < 31 THEN '4. 00 - 30'          
				WHEN B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT > 30 AND B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT < 61 THEN '5. 31 - 60'          
				WHEN B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT > 60 AND B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT < 91 THEN '6. 61 - 90'          
			    WHEN B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT > 90 AND B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT < 121 THEN '7. 91 - 120'          
				WHEN B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT > 120 AND B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT < 151 THEN '8. 121 - 150'          
				ELSE '9. > 150'
			END
    FROM B14B_02_TT_OFFSET_DOCS
    UNION
    SELECT DISTINCT
            B14_BSAID_MANDT,
            B14_BSAID_BUKRS,
            B14_BSAID_GJAHR,
            B14_BSAID_BELNR,
            B14_BSAID_BUZEI,
            B14_BSAID_ZUONR,
            NULL,
            '2. Open'
    FROM B14B_02_TT_OFFSET_DOCS
  
    /*
        Step 4: Get more information
    */
    EXEC SP_REMOVE_TABLES 'B14B_04_IT_ASSIGMENT_DOCS_DETAIL'
    SELECT DISTINCT
           B14_06_IT_ARE.B14_BSAID_MANDT,
           B14_06_IT_ARE.B14_BSAID_BUKRS,
           B14_06_IT_ARE.B14_BSAID_GJAHR,
           B14_06_IT_ARE.B14_BSAID_BELNR,
           B14_06_IT_ARE.B14_BSAID_BUZEI,
           B14_06_IT_ARE.B14_BSAID_BLDAT,
           B14_06_IT_ARE.B14_BSAID_BUDAT,
           B14_06_IT_ARE.B14_BSAID_AUGDT,
           B14_06_IT_ARE.B14_BSAID_XBLNR,
           B14_06_IT_ARE.B14_BSAID_ZUONR,
           CONCAT(B14_06_IT_ARE.B14_BSAID_BUKRS, '-', B14_06_IT_ARE.B14_BSAID_BELNR, '-', B14_06_IT_ARE.B14_BSAID_GJAHR) ZF_BSAID_DOC_DETAIL,
           CONCAT(IIF(B14_06_IT_ARE.B14_ZF_BSAID_SHKZG_DESC = 'Debit', 'a.', 'z.') ,B14_06_IT_ARE.B14_BSAID_BELNR,  ' - ',  IIF(B14_06_IT_ARE.B14_ZF_BSAID_SHKZG_DESC = 'Debit', 'Open Invoice - ', ''), B14_06_IT_ARE.B14_T003T_LTEXT, ', ',  B14_06_IT_ARE.B14_TBSLT_LTEXT) ZF_BSAID_BELNR_DESC,
           B14B_03_TT_ASSIGMENT_DOCS_FULL.B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT,
           B14B_03_TT_ASSIGMENT_DOCS_FULL.B14_ZF_OPEN_BLDAT_MINUS_OFFSET_BLDAT_BUCKET,
           B14_06_IT_ARE.B14_ZF_BSAID_SHKZG_DESC,
           B14_06_IT_ARE.B14_BSAID_WAERS,
           B14_06_IT_ARE.B14_ZF_BSAID_WRBTR_DOC,
           B14_06_IT_ARE.B14_T001_WAERS,
           B14_06_IT_ARE.B14_ZF_BSAID_DMBTR_COC,
           B14_06_IT_ARE.B14_BSAID_DMBE2,
           B14_06_IT_ARE.B14_BSAID_DMBE3,
           B14_06_IT_ARE.B14_ZF_BSAID_DMBTR_CUC
        
    INTO B14B_04_IT_ASSIGMENT_DOCS_DETAIL
    FROM B14B_03_TT_ASSIGMENT_DOCS_FULL
    LEFT JOIN B14_06_IT_ARE
    ON B14_06_IT_ARE.B14_BSAID_BUKRS = B14B_03_TT_ASSIGMENT_DOCS_FULL.B14_BSAID_BUKRS AND
       B14_06_IT_ARE.B14_BSAID_GJAHR = B14B_03_TT_ASSIGMENT_DOCS_FULL.B14_BSAID_GJAHR AND
       B14_06_IT_ARE.B14_BSAID_BELNR = B14B_03_TT_ASSIGMENT_DOCS_FULL.B14_BSAID_BELNR AND
       B14_06_IT_ARE.B14_BSAID_BUZEI = B14B_03_TT_ASSIGMENT_DOCS_FULL.B14_BSAID_BUZEI


    /*
        Step 5: Create snapshot table for all AR documents with a assigment number
    */

    EXEC SP_REMOVE_TABLES 'B14B_05_IT_ASSIGMENT_DOCS_SNAPSHOT'
    SELECT DISTINCT 
            B16_00_TT_SNAPSHOT_DATE.ZF_MNTH_END,
            B14_BSAID_MANDT,
            B14_BSAID_BUKRS,
            B14_BSAID_GJAHR,
            B14_BSAID_BELNR,
            B14_BSAID_BUZEI
    INTO B14B_05_IT_ASSIGMENT_DOCS_SNAPSHOT
    FROM B14B_04_IT_ASSIGMENT_DOCS_DETAIL
    LEFT JOIN B16_00_TT_SNAPSHOT_DATE
    ON 1 = 1
    WHERE B14B_04_IT_ASSIGMENT_DOCS_DETAIL.B14_BSAID_BUDAT <= B16_00_TT_SNAPSHOT_DATE.ZF_MNTH_END 
          AND (B14B_04_IT_ASSIGMENT_DOCS_DETAIL.B14_BSAID_AUGDT = '' OR B14B_04_IT_ASSIGMENT_DOCS_DETAIL.B14_BSAID_AUGDT > B16_00_TT_SNAPSHOT_DATE.ZF_MNTH_END)

    /*
        Rename fiels for result table.
    */
    EXEC SP_UNNAME_FIELD 'B14_', 'B14B_04_IT_ASSIGMENT_DOCS_DETAIL'
    EXEC SP_UNNAME_FIELD 'B14_', 'B14B_05_IT_ASSIGMENT_DOCS_SNAPSHOT'
    EXEC SP_RENAME_FIELD 'B14B_04_', 'B14B_04_IT_ASSIGMENT_DOCS_DETAIL'
    EXEC SP_RENAME_FIELD 'B14B_05_', 'B14B_05_IT_ASSIGMENT_DOCS_SNAPSHOT'
	EXEC SP_REMOVE_TABLES '%_TT_%'


END
GO
