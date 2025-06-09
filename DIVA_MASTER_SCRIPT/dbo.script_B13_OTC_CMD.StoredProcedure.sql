USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROCEDURE [dbo].[script_B13_OTC_CMD]  

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


      ---------------------------------------------------------------------------------------------------------------------------- 
      --Declare parameters here 
      DECLARE 	 
			 @currency nvarchar(max)			= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'currency')
			,@date1 nvarchar(max)				= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'date1')
			,@date2 nvarchar(max)				= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'date2')
			,@downloaddate nvarchar(max)		= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'downloaddate')
			,@exchangeratetype nvarchar(max)	= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'exchangeratetype')
			,@language1 nvarchar(max)			= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'language1')
			,@language2 nvarchar(max)			= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'language2')
			,@year nvarchar(max)				= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'year')
			,@id nvarchar(max)					= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'id')
			,@LIMIT_RECORDS INT                    = CAST((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS') AS INT)
 
 
/*Test mode*/
 
--SET ROWCOUNT @LIMIT_RECORDS


/* 
	Title        :  B13_05_IT_CMD 
    Description  :  Customer master data 
       
    -------------------------------------------------------------- 
    Update history 
    -------------------------------------------------------------- 
    Date		|  Who    |  Description 
    13-07-2016     EH        Initial version for Sony 
    04-02-2016     SK        Code Reformatting to create standard(region/system specific) version 
	30-09-2017	   HT        Update and standardisation for GULF
	22-03-2022	   Thuan	Remove MANDT field in join
*/ 
 
 
 
/* Step 1
-- Create one customer master table including information from the customer master data by company code (KNB1) and address information (KNA1)
-- Rows are being removed based on the following tables (because INNER JOIN): 
---- Only keep lines for which the CUSTOMER (KNB1_KUNNR) is found in
---- the list of customers per company code (KNB1)
---- Only keep lines for which the company code (KNB1_BUKRS) and the mandate (KNB1_MANDT) is found in the AM_SCOPE table

*/
 
      EXEC SP_DROPTABLE 'B13_00_TT_KNA1_KNB1'

      SELECT A_KNB1.KNB1_MANDT
			 ,A_KNB1.KNB1_KUNNR
             ,AM_SCOPE.SCOPE_BUSINESS_DMN_L1
			 ,AM_SCOPE.SCOPE_BUSINESS_DMN_L2
             ,A_KNB1.KNB1_BUKRS 
             ,A_KNA1.KNA1_LOEVM
             ,A_KNA1.KNA1_NAME1 
             ,A_KNA1.KNA1_LAND1 
             ,A_KNA1.KNA1_KUKLA 
             ,A_KNA1.KNA1_KONZS 
             ,A_KNB1.KNB1_LOEVM
             ,A_KNA1.KNA1_ORT01 
             ,A_KNA1.KNA1_STRAS 
             ,A_KNA1.KNA1_PSTLZ 
             ,A_KNA1.KNA1_SORTL 
             ,A_KNA1.KNA1_VBUND 
             ,A_KNA1.KNA1_KTOKD 
             ,A_KNA1.KNA1_SPERR
             ,A_KNB1.KNB1_AKONT 
             ,A_KNB1.KNB1_SPERR
             ,A_KNA1.KNA1_STCEG 
             ,A_KNA1.KNA1_ERDAT
             ,A_KNB1.KNB1_ERDAT
             ,A_KNA1.KNA1_ERNAM 
             ,A_KNB1.KNB1_ZWELS 
             ,A_KNB1.KNB1_ZTERM 
             ,A_KNA1.KNA1_XCPDK  
             -- add Sony specific ECOT codes 
             ,A_KNA1.KNA1_BRAN1 
             ,A_KNA1.KNA1_BRAN2 
             ,A_KNA1.KNA1_BRAN3 
             ,A_KNA1.KNA1_BRAN4 
             ,A_KNA1.KNA1_BRAN5 
             ,A_KNB1.KNB1_VLIBB 
      
	  INTO   B13_00_TT_KNA1_KNB1 
      
	  FROM   A_KNA1 
      
	  INNER JOIN A_KNB1 
      ON A_KNA1.KNA1_KUNNR = A_KNB1.KNB1_KUNNR

	  INNER JOIN AM_SCOPE 
      ON A_KNB1.KNB1_BUKRS = AM_SCOPE.SCOPE_CMPNY_CODE

/* Step 2
-- Create a list of active customers. Customers are considered active if there is a customer order, delivery 
-- invoice, payment or other FI document after the date1 variable that is specified in the AM_GLOBALS table 
*/


	  EXEC sp_DROPTABLE 'B13_01_TT_ACTV_CUST'

	  -- Customers from customer orders where there is an order after date1 in AM_GLOBALS
	  SELECT A_VBAK.VBAK_MANDT, A_TVKO.TVKO_BUKRS, A_VBAK.VBAK_KUNNR INTO B13_01_TT_ACTV_CUST FROM A_VBAK INNER JOIN A_TVKO ON (A_VBAK.VBAK_VKORG = A_TVKO.TVKO_VKORG) WHERE (A_VBAK.VBAK_ERDAT >= @date1) 
	  UNION
	  -- Customers (ship to) from deliveries where there is an order after date1 in AM_GLOBALS
	  SELECT LIKP_MANDT, TVKO_BUKRS, LIKP_KUNNR FROM A_LIKP INNER JOIN A_TVKO ON (LIKP_VKORG = TVKO_VKORG) WHERE  (LIKP_ERDAT >= @date1)
	  UNION 
	  -- Customers (sold to) from deliveries where there is an order after date1 in AM_GLOBALS
	  SELECT LIKP_MANDT, TVKO_BUKRS, LIKP_KUNAG FROM A_LIKP INNER JOIN A_TVKO ON (LIKP_VKORG = TVKO_VKORG) WHERE  (LIKP_ERDAT >= @date1) 
	  UNION 
	  -- Customers (ship to) for SD invoices where there is an order after date1 in AM_GLOBALS
      SELECT VBRK_MANDT, VBRK_BUKRS, VBRK_KUNAG AS VBRK_KUNNR FROM A_VBRK WHERE (VBRK_ERDAT >= @date1) 
      UNION 
	  -- Customers (sold to) for SD invoices where there is an order after date1 in AM_GLOBALS
      SELECT VBRK_MANDT, VBRK_BUKRS, VBRK_KUNRG AS VBRK_KUNNR FROM A_VBRK WHERE (VBRK_ERDAT >= @date1) 
      UNION 
	  -- Customers (open items) for SD invoices where there is an order after date1 in AM_GLOBALS
      SELECT BSID_MANDT, BSID_BUKRS, BSID_KUNNR FROM A_BSID WHERE (BSID_BUDAT >= @date1) 
      UNION 
	  -- Customers (closed items) for SD invoices where there is an order after date1 in AM_GLOBALS
      SELECT BSAD_MANDT, BSAD_BUKRS, BSAD_KUNNR FROM A_BSAD WHERE  (BSAD_BUDAT >= @date1) 

/* Step 3
-- Create a table that shows for each customer, whether or not the customer is a customer that acts as:
-- -- sold to
-- -- ship to
-- -- bill to
-- -- payer
-- -- forwarding agent
-- The following hard-coded values are found in this step for the description of third-party type (KNVP_PARVW).
-- -- these values are standard as found here: https://edigkim.wordpress.com/2013/10/07/sap-idoc-qualifiers/
-- Rows are being removed based on the following tables (because INNER JOIN): Only keep lines for which the 
-- sales organization (VKORG) and company code (BUKRS) is found in the list of sales organizations (TVKO)

*/

      EXEC sp_DROPTABLE 'B13_02_TT_KNVP_MSD'

      SELECT A_KNVP.KNVP_MANDT 
            ,A_TVKO.TVKO_BUKRS 
            ,KNVP_KUNNR 
            ,Max(CASE WHEN KNVP_PARVW = 'AG' THEN 'X' ELSE '' END) ZF_PARVW_SOLD_TO
            ,Max(CASE WHEN KNVP_PARVW = 'WE' THEN 'X' ELSE '' END) ZF_PARVW_SHIP_TO
            ,Max(CASE WHEN KNVP_PARVW = 'RE' THEN 'X' ELSE '' END) ZF_PARVW_BILL_TO
            ,Max(CASE WHEN KNVP_PARVW = 'RG' THEN 'X' ELSE '' END) ZF_PARVW_PAYER
            ,Max(CASE WHEN KNVP_PARVW = 'SP' THEN 'X' ELSE '' END) ZF_PARVW_FORWARDING_AGENT
            ,Max(CASE WHEN KNVP_PARVW <> 'AG' AND
						   KNVP_PARVW <> 'WE' AND
						   KNVP_PARVW <> 'RE' AND
						   KNVP_PARVW <> 'RG' AND
						   KNVP_PARVW <> 'SP'				   						   						 
				THEN 'X' ELSE '' END) ZF_PARVW_OTHER

      INTO  B13_02_TT_KNVP_MSD 
      FROM  A_KNVP
      -- Limit on sales organizations found in the list of sales organizations
      INNER JOIN A_TVKO 
      ON (KNVP_VKORG = TVKO_VKORG) 
      GROUP BY KNVP_MANDT 
              ,TVKO_BUKRS 
              ,KNVP_KUNNR 
	  
--step 4: create credit data table
	  EXEC sp_DROPTABLE 'B13_03_TT_KNKK_CR_DATA'

      SELECT A_KNKK.KNKK_MANDT 
            ,A_KNKK.KNKK_KUNNR 
            ,A_KNKK.KNKK_KKBER 
            ,A_KNKK.KNKK_KNKLI 
            ,A_KNA1.KNA1_NAME1
            ,A_KNKK.KNKK_CTLPC 
            ,A_T691T.T691T_RTEXT 
            ,A_T014.T014_WAERS 
            ,A_T014.T014_KLIMK AS CR_T014_KLIMK_LIM_AREA_DEF --       AS [Credit limit - credit control area default] 
            ,A_KNKK.KNKK_KLIMK AS CR_KNKK_KLIMK_LIMIT_IND --       AS [Credit limit - individual] 
            ,KNKLI_data.KNKK_KLIMK AS CR_KNKK_KLIMK_LIMIT_ACC -- AS [Credit limit - credit account] 
            -- Credit limit calculation 
            ,CASE 
               WHEN ISNULL(A_KNKK.KNKK_KLIMK, A_T014.T014_KLIMK) > KNKLI_data.KNKK_KLIMK THEN ISNULL(A_KNKK.KNKK_KLIMK, A_T014.T014_KLIMK) 
               ELSE KNKLI_data.KNKK_KLIMK 
            END [ZF_KLIMK_CR_LIMIT]              -- AS [Z_Calculated credit limit] 
      
	  INTO B13_03_TT_KNKK_CR_DATA 
      
	  FROM A_KNKK 
      
	  LEFT JOIN A_KNA1 
      ON A_KNA1.KNA1_KUNNR = A_KNKK.KNKK_KNKLI 
      
	  LEFT JOIN A_KNKK KNKLI_data 
      ON (A_KNKK.KNKK_KKBER = KNKLI_data.KNKK_KKBER) AND 
         (A_KNKK.KNKK_KNKLI = KNKLI_data.KNKK_KUNNR)
      
	  LEFT JOIN A_T014 
      ON (A_KNKK.KNKK_KKBER = A_T014.T014_KKBER) 
      
	  LEFT JOIN A_T691T 
      ON A_KNKK.KNKK_KKBER = A_T691T.T691T_KKBER AND
         A_KNKK.KNKK_CTLPC = A_T691T.T691T_CTLPC AND
         A_T691T.T691T_SPRAS = @language1 


--step 5: create KNB1, reconciliation account with intercompany logics

	EXEC sp_DROPTABLE 'B13_04_TT_KNB1_RE_ACC'
		SELECT DISTINCT KNB1_MANDT, KNB1_BUKRS, KNB1_AKONT, KNB1_KUNNR INTO B13_04_TT_KNB1_RE_ACC FROM A_KNB1
		EXEC sp_DROPTABLE 'B13_04_TT_KNB1_RE_ACC_IC'
		SELECT 
			 B13_04_TT_KNB1_RE_ACC.KNB1_MANDT --	AS [Mandant]
			,B13_04_TT_KNB1_RE_ACC.KNB1_BUKRS --	AS [Company code]
			,B13_04_TT_KNB1_RE_ACC.KNB1_AKONT --	AS [Reconciliation account]
			,A_SKAT.SKAT_TXT50 --						AS [Reconciliation account text]
			,AM_T077X.INTERCO_TXT AS [ZF_KNB1_AKONT_INTER_COM] -- Z_Intercompany
		
		INTO B13_04_TT_KNB1_RE_ACC_IC

		FROM B13_04_TT_KNB1_RE_ACC
		
		LEFT JOIN A_T001
		ON  A_T001.T001_BUKRS = B13_04_TT_KNB1_RE_ACC.KNB1_BUKRS
		
		LEFT JOIN (SELECT DISTINCT KNA1_KUNNR, KNA1_MANDT, KNA1_KTOKD FROM A_KNA1) A_KNA1
		ON A_KNA1.KNA1_KUNNR = B13_04_TT_KNB1_RE_ACC.KNB1_KUNNR 

		LEFT JOIN A_SKAT
		ON  A_SKAT.SKAT_SAKNR = B13_04_TT_KNB1_RE_ACC.KNB1_AKONT AND
			A_SKAT.SKAT_KTOPL = A_T001.T001_KTOPL AND
			A_SKAT.SKAT_SPRAS = 'EN'
	
        LEFT JOIN AM_T077X 
		ON AM_T077X.T077X_KTOKD = A_KNA1.KNA1_KTOKD
		 
	  --SHARED LOGIC 

--step 6: create final Simple cube

	  EXEC SP_DROPTABLE 'B13_05_IT_CMD'
      --Enter main select statements below 
      SELECT @id AS GLOBALS_SYSTEM
			,B13_00_TT_KNA1_KNB1.KNB1_MANDT --							AS [Mandant] 
            ,B13_00_TT_KNA1_KNB1.SCOPE_BUSINESS_DMN_L1
			,B13_00_TT_KNA1_KNB1.SCOPE_BUSINESS_DMN_L2
            ,B13_00_TT_KNA1_KNB1.KNB1_BUKRS --							AS [Company code] 
            ,A_T001.T001_BUTXT --									AS [Company name] 
            ,A_T001.T001_LAND1 --									AS [Company country] 
            ,A_T001.T001_KKBER --									AS [Credit control area] 
            ,B00_T014T.T014T_KKBTX --								AS [Credit control area text] 
            ,B13_00_TT_KNA1_KNB1.KNA1_KONZS --							AS [Group key] 
            ,B13_00_TT_KNA1_KNB1.KNB1_KUNNR --							AS [Customer nr] 
            ,B13_00_TT_KNA1_KNB1.KNA1_NAME1 --							AS [Customer name] 
            ,B13_00_TT_KNA1_KNB1.KNA1_LAND1 --							AS [Customer country]  
            ,COALESCE(B00_TKUKT.TKUKT_KUKLA, '') ZF_CUST_CLASS_TKUKT_KUKLA --				AS [Customer class] 
            ,COALESCE(B00_TKUKT.TKUKT_VTEXT, '') ZF_TKUKT_VTEXT_CUST_CLASS_TXT --				AS [Customer class text] 
            ,ISNULL(T005_XEGLD, '') AS ZF_T005_XEGLD_EU_CNTRY --						AS [EU Country] 
            ,B13_00_TT_KNA1_KNB1.KNA1_ORT01 --							AS [City] 
            ,B13_00_TT_KNA1_KNB1.KNA1_STRAS --							AS [Street] 
            ,B13_00_TT_KNA1_KNB1.KNA1_PSTLZ --							AS [Postal code] 
            ,B13_00_TT_KNA1_KNB1.KNA1_SORTL --							AS [Search term] 
            ,B13_00_TT_KNA1_KNB1.KNA1_KTOKD --							AS [Account group] 
            ,B00_T077X.T077X_TXT30 AS T077X_TXT30 --								AS [Account group text] 
            ,B13_00_TT_KNA1_KNB1.KNB1_AKONT --							AS [Reconciliation account] 
            ,B13_00_TT_KNA1_KNB1.KNA1_VBUND --							AS [Trading partner] 
            ,T880_NAME1 --									AS [Trading partner text] 
            ,B13_00_TT_KNA1_KNB1.KNA1_STCEG --							AS [VAT nr] 
            ,B13_00_TT_KNA1_KNB1.KNA1_ERDAT --							AS [Creation date] 
            ,B13_00_TT_KNA1_KNB1.KNB1_ERDAT --							AS [Creation date - company code data] 
            ,B13_00_TT_KNA1_KNB1.KNA1_ERNAM --					AS [Creation user] 
            ,B13_00_TT_KNA1_KNB1.KNB1_ZWELS --							AS [CMD payment method] 
            ,B13_00_TT_KNA1_KNB1.KNB1_ZTERM --							AS [CMD payment term] 
            ,B13_00_TT_KNA1_KNB1.KNA1_XCPDK --							AS [One-time customer] 
            ,B13_00_TT_KNA1_KNB1.KNA1_BRAN1 --							AS [Industry code 1] 
            --,TBR1.VTEXT									AS [Industry code text 1] 
            ,B13_00_TT_KNA1_KNB1.KNA1_BRAN2			--				AS [Industry code 2] 
            --,TBR2.VTEXT									AS [Industry code text 2] 
            ,B13_00_TT_KNA1_KNB1.KNA1_BRAN3		--					AS [Industry code 3] 
            --,TBR3.VTEXT									AS [Industry code text 3] 
            ,B13_00_TT_KNA1_KNB1.KNA1_BRAN4	--						AS [Industry code 4] 
            --,TBR4.VTEXT									AS [Industry code text 4] 
            ,B13_00_TT_KNA1_KNB1.KNA1_BRAN5--							AS [Industry code 5] 
            --,TBR5.VTEXT									AS [Industry code text 5] 
            ,B13_02_TT_KNVP_MSD.ZF_PARVW_SOLD_TO
            ,B13_02_TT_KNVP_MSD.ZF_PARVW_SHIP_TO
            ,B13_02_TT_KNVP_MSD.ZF_PARVW_BILL_TO
            ,B13_02_TT_KNVP_MSD.ZF_PARVW_PAYER
            ,B13_03_TT_KNKK_CR_DATA.KNKK_KNKLI --							AS [Credit account] 
            -- reference to other customer 
            ,B13_03_TT_KNKK_CR_DATA.KNA1_NAME1 AS ZF_KNA1_NAME1_CR_ACC_NAME	---						AS [Credit account name] 
            ,COALESCE(B13_03_TT_KNKK_CR_DATA.KNKK_CTLPC, 'N/A') AS ZF_KNKK_CTLPC_RISK_CAT --			AS [Risk category] 
            ,COALESCE(B13_03_TT_KNKK_CR_DATA.T691T_RTEXT, 'No risk category assigned') AS ZF_KNKK_CTLPC_RISK_CAT_TXT -- AS [Risk category text] 
            
			-- Credit Control Area Currency   
            ,B13_03_TT_KNKK_CR_DATA.T014_WAERS -- AS [Currency (cca)] 
            ,B13_03_TT_KNKK_CR_DATA.CR_T014_KLIMK_LIM_AREA_DEF -- AS [Credit limit - credit control area default (cca)] 
            ,B13_03_TT_KNKK_CR_DATA.CR_KNKK_KLIMK_LIMIT_IND -- AS [Credit limit - individual (cca)] 
            ,B13_03_TT_KNKK_CR_DATA.CR_KNKK_KLIMK_LIMIT_ACC -- AS [Credit limit - credit account (cca)] 
            ,B13_03_TT_KNKK_CR_DATA.ZF_KLIMK_CR_LIMIT -- AS [Z_Calculated credit limit (cca)] 
            ,B13_00_TT_KNA1_KNB1.KNB1_VLIBB ZF_INSURANCE_DEF-- AS [Insurance (cca)] 
			
            -- Custom Currency 
          
            ,@currency GLOBALS_CURRENCY --[Z_Currency (custom)] 
            ,B13_03_TT_KNKK_CR_DATA.CR_T014_KLIMK_LIM_AREA_DEF 
				* ISNULL(TCURX_DOC.TCURX_FACTOR, 1.0) * COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1) AS ZF_CR_TCURX_EXCHNG_LIM_AREA_CUS --AS [Z_Credit limit - credit control area default (custom)] 
            ,B13_03_TT_KNKK_CR_DATA.CR_KNKK_KLIMK_LIMIT_IND 
				* ISNULL(TCURX_DOC.TCURX_FACTOR, 1.0) * COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1) AS ZF_CR_KNKK_KLIMK_LIMIT_IND_CUS --AS [Z_Credit limit - individual (custom)] 
            ,B13_03_TT_KNKK_CR_DATA.CR_KNKK_KLIMK_LIMIT_ACC 
				* ISNULL(TCURX_DOC.TCURX_FACTOR, 1.0) * COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1) AS ZF_CR_TCURX_EXCHNG_LIM_ACC_CUS --AS [Z_Credit limit - credit account (custom)] 
            ,B13_03_TT_KNKK_CR_DATA.ZF_KLIMK_CR_LIMIT 
				* ISNULL(TCURX_DOC.TCURX_FACTOR, 1.0) * COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1) AS ZF_KLIMK_CR_LIMIT_CUS --AS [Z_Calculated credit limit (custom)] 
            ,B13_00_TT_KNA1_KNB1.KNB1_VLIBB 
				* ISNULL(TCURX_DOC.TCURX_FACTOR, 1.0) * COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1) AS ZF_TCURX_EXCHNG_INSURANCE_CUS --AS [Z_Insurance (custom)] 
		
            ,CASE 
               WHEN ([B13_00_TT_KNA1_KNB1].KNA1_LOEVM = 'X' OR [B13_00_TT_KNA1_KNB1].KNB1_LOEVM = 'X') THEN 'X' 
               ELSE ''  
             END AS ZF_KNA1_LOEVM_DELETED 
            ,CASE 
               WHEN ([B13_00_TT_KNA1_KNB1].KNA1_SPERR = 'X' OR [B13_00_TT_KNA1_KNB1].KNB1_SPERR = 'X') THEN 'X' 
               ELSE '' 
             END AS ZF_KNA1_SPERR_BLOCKED 
            ,CASE 
               WHEN ([B13_00_TT_KNA1_KNB1].KNA1_LOEVM = 'X' 
                  OR [B13_00_TT_KNA1_KNB1].KNA1_SPERR = 'X' 
                  OR [B13_00_TT_KNA1_KNB1].KNB1_LOEVM = 'X' 
                  OR [B13_00_TT_KNA1_KNB1].KNB1_SPERR = 'X') THEN 'X' 
               ELSE '' 
             END AS ZF_LOEVM_SPERR_BLOCKED_DELETED 
            -- If customer number not present in B13_01_TT_ACTV_CUST temp table then if not deleted it is not an active customer
            ,CASE 
               WHEN (B13_01_TT_ACTV_CUST.VBAK_KUNNR IS NULL) THEN 
                 CASE 
                   WHEN ([B13_00_TT_KNA1_KNB1].KNA1_LOEVM = 'X' 
                      OR [B13_00_TT_KNA1_KNB1].KNA1_SPERR = 'X' 
                      OR [B13_00_TT_KNA1_KNB1].KNB1_LOEVM = 'X' 
                      OR [B13_00_TT_KNA1_KNB1].KNB1_SPERR = 'X') THEN 'DEL' 
                   ELSE '' 
                 END 
               ELSE 'X' 
             END AS [ZF_KUNNR_IS_ACTIVE] 
            ,ISNULL(B00_KNAS.ZF_CNTRY_VAT_NUM, '') AS [ZF_KNAS_CNTRY_VAT_NUM]  
             
			-- if any of these fields are blank these columns will be 'X' 
            ,CASE 
				WHEN 
					(ISNULL(B13_00_TT_KNA1_KNB1.KNA1_ORT01,'') = '') OR 	--City
					(ISNULL(B13_00_TT_KNA1_KNB1.KNA1_SORTL,'') = '') OR 	--Sort field
					(LEN(B13_00_TT_KNA1_KNB1.KNA1_NAME1) <= 1) 		OR  --Name 1 description
					(ISNULL(B13_00_TT_KNA1_KNB1.KNB1_AKONT,'') = '' AND (B13_02_TT_KNVP_MSD.ZF_PARVW_BILL_TO = 'X' OR B13_02_TT_KNVP_MSD.ZF_PARVW_PAYER = 'X')) OR -- Reconciliation account
					(ISNULL(B13_00_TT_KNA1_KNB1.KNA1_STRAS,'') = '' AND ISNULL(B13_00_TT_KNA1_KNB1.KNA1_PSTLZ,'') = '' ) --House number and street and Postal Code
					THEN 'X' 
				ELSE '' 
			END AS [ZF_KNA1_KNB1_INCOMPLETE_GENERAL_DATA]
            ,CASE 
               WHEN ISNULL(A_KNBK.KNBK_KUNNR, '') = '' THEN 'X' 
               ELSE '' 
            END AS [ZF_KNBK_KUNNR_INCOMPLETE_BANK_DATA] 
      ,''	AS ZF_STRATEGIC_ACC 
      ,''	AS ZF_STRATEGIC_ACC_TEXT
	  ,COALESCE(AM_T077X.INTERCO_TXT, 'Unknown') AS [ZF_KNB1_AKONT_INTER_COM]
	  INTO  B13_05_IT_CMD
      
	  FROM  B13_00_TT_KNA1_KNB1 
      
	  LEFT JOIN A_T005 
      ON (B13_00_TT_KNA1_KNB1.KNA1_LAND1 = T005_LAND1) 

      LEFT JOIN A_T001 
      ON (B13_00_TT_KNA1_KNB1.KNB1_BUKRS = T001_BUKRS) 
      
	  LEFT JOIN B00_T014T 
      ON (A_T001.T001_KKBER = B00_T014T.T014T_KKBER) 
      
	  LEFT JOIN B00_T077X 
      ON (B13_00_TT_KNA1_KNB1.KNA1_KUKLA = B00_T077X.T077X_KTOKD) 
      
	  LEFT JOIN B00_TKUKT 
      ON (B13_00_TT_KNA1_KNB1.KNA1_KUKLA = B00_TKUKT.TKUKT_KUKLA) 
      
	  LEFT JOIN B13_01_TT_ACTV_CUST 
      ON (B13_00_TT_KNA1_KNB1.KNB1_BUKRS = B13_01_TT_ACTV_CUST.TVKO_BUKRS) AND 
         (B13_00_TT_KNA1_KNB1.KNB1_KUNNR = B13_01_TT_ACTV_CUST.VBAK_KUNNR) 

        LEFT JOIN AM_T077X 
		ON AM_T077X.T077X_KTOKD = B13_00_TT_KNA1_KNB1.KNA1_KTOKD

      
	  -- Select customers with incomplete sales data (currency key)  
      -- KNVV can only be joined to B13_00_TT_KNA1_KNB1 as aggregate because KNVV has another dimension 
      -- ! Business Partner roles are aggregated to company code level as well 
	  LEFT JOIN B13_02_TT_KNVP_MSD 
      ON (B13_02_TT_KNVP_MSD.TVKO_BUKRS = B13_00_TT_KNA1_KNB1.KNB1_BUKRS) AND
         (B13_02_TT_KNVP_MSD.KNVP_KUNNR = B13_00_TT_KNA1_KNB1.KNB1_KUNNR) 
      
	  -- Include trading partner description 
      LEFT JOIN A_T880 
      ON  B13_00_TT_KNA1_KNB1.KNA1_VBUND = A_T880.T880_RCOMP 
      
	  -- Incomplete foreign trade trade for customers has to consider that VAT Nr may be configured for multiple countries, which is registered in the table KNAS.
      LEFT JOIN (SELECT DISTINCT KNAS_MANDT, KNAS_KUNNR ,'X' AS ZF_CNTRY_VAT_NUM FROM A_KNAS) AS B00_KNAS 
      ON (B13_00_TT_KNA1_KNB1.KNB1_KUNNR = KNAS_KUNNR)
      
	  -- Bank accounts       
      LEFT JOIN (SELECT DISTINCT KNBK_MANDT, KNBK_KUNNR FROM A_KNBK WHERE ISNULL(KNBK_BANKN, '') <> '') AS A_KNBK 
      ON  KNBK_KUNNR = B13_00_TT_KNA1_KNB1.KNB1_KUNNR 
		 
      -- Credit data 
      LEFT JOIN B13_03_TT_KNKK_CR_DATA 
      ON (B13_00_TT_KNA1_KNB1.KNB1_KUNNR = B13_03_TT_KNKK_CR_DATA.KNKK_KUNNR) AND
         (A_T001.T001_KKBER = B13_03_TT_KNKK_CR_DATA.KNKK_KKBER) 
-- Add currency factor from company currency to USD

		LEFT JOIN B00_IT_TCURF
		ON B13_03_TT_KNKK_CR_DATA.T014_WAERS = B00_IT_TCURF.TCURF_FCURR
		AND B00_IT_TCURF.TCURF_TCURR  = @currency  
		AND B00_IT_TCURF.TCURF_GDATU = (
			SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
			FROM B00_IT_TCURF
			WHERE B13_03_TT_KNKK_CR_DATA.T014_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
					B00_IT_TCURF.TCURF_TCURR  = @currency  AND
					B00_IT_TCURF.TCURF_GDATU <= B13_00_TT_KNA1_KNB1.KNB1_ERDAT
			ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
			)
		-- Add exchange rate from company currency to USD
		LEFT JOIN B00_IT_TCURR
			ON B13_03_TT_KNKK_CR_DATA.T014_WAERS = B00_IT_TCURR.TCURR_FCURR
			AND B00_IT_TCURR.TCURR_TCURR  = @currency  
			AND B00_IT_TCURR.TCURR_GDATU = (
				SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
				FROM B00_IT_TCURR
				WHERE B13_03_TT_KNKK_CR_DATA.T014_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
						B00_IT_TCURR.TCURR_TCURR  = @currency  AND
						B00_IT_TCURR.TCURR_GDATU <= B13_00_TT_KNA1_KNB1.KNB1_ERDAT
				ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
				) 
    
	  LEFT JOIN B00_TCURX TCURX_DOC 
      ON 
         B13_03_TT_KNKK_CR_DATA.T014_WAERS = TCURX_DOC.TCURX_CURRKEY 
	  --LEFT JOIN B13_04_TT_KNB1_RE_ACC_IC
	  --ON  B13_00_TT_KNA1_KNB1.KNB1_BUKRS = B13_04_TT_KNB1_RE_ACC_IC.KNB1_BUKRS AND
		 -- B13_00_TT_KNA1_KNB1.KNB1_AKONT = B13_04_TT_KNB1_RE_ACC_IC.KNB1_AKONT

	--Immediately following each cube select statement, copy the following to log the cube creation
	--Note: make sure to update the two references to cube name in this code
	INSERT INTO [_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
	SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Cube completed','B13_05_IT_CMD',(SELECT COUNT(*) FROM B13_05_IT_CMD)

	--rename the output table
	EXEC sp_RENAME_FIELD 'B13_' , 'B13_05_IT_CMD'
	EXEC SP_REMOVE_TABLES '%_TT_%'


	--Duplicate check 
	SELECT B13_KNB1_MANDT, B13_KNB1_BUKRS, B13_KNB1_KUNNR, COUNT(*) AS [Nr of records] FROM dbo.B13_05_IT_CMD GROUP BY B13_KNB1_MANDT, B13_KNB1_BUKRS, B13_KNB1_KUNNR HAVING COUNT(*) > 1
	
	--Log end of procedure
	INSERT INTO [_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
	SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL

	/* log end of procedure*/
	INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
	SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL
END
GO
