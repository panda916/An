USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE         PROCEDURE [dbo].[script_B04_FIN_GENERAL_LEDGER]

WITH EXECUTE AS CALLER
AS

--DYNAMIC_SCRIPT_START
/* Initiate the log */ 
--Create database log table if it does not exist
IF OBJECT_ID('LOG_SP_EXECUTION', 'U') IS NULL BEGIN CREATE TABLE [DBO].[LOG_SP_EXECUTION] ([DATABASE] NVARCHAR(MAX) NULL,[OBJECT] NVARCHAR(MAX) NULL,[OBJECT_TYPE] NVARCHAR(MAX) NULL,[USER] NVARCHAR(MAX) NULL,[DATE] DATE NULL,[TIME] TIME NULL,[DESCRIPTION] NVARCHAR(MAX) NULL,[TABLE] NVARCHAR(MAX),[ROWS] INT) END
 
--Log start of procedure
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Procedure started',NULL,NULL
 
	/* Initialize parameters from globals table */
    DECLARE  
				@CURRENCY NVARCHAR(3)                 = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'currency')
				,@DATE1 NVARCHAR(MAX)                           = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date1')
				,@DATE2 NVARCHAR(MAX)                           = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date2')
				,@DOWNLOADDATE NVARCHAR(MAX)             = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'downloaddate')
				,@DATEFORMAT VARCHAR(3)             = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'dateformat')
				,@EXCHANGERATETYPE NVARCHAR(MAX)  = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'exchangeratetype')
				,@LANGUAGE1 NVARCHAR(3)                = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language1')
				,@LANGUAGE2 NVARCHAR(3)                = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language2')
				,@LIMIT_RECORDS INT                    = CAST((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS') AS INT)
				,@FISCAL_YEAR_FROM NVARCHAR(MAX)					= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'FISCAL_YEAR_FROM')
				,@FISCAL_YEAR_TO NVARCHAR(MAX)					= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'FISCAL_YEAR_TO')
                 SET DATEFORMAT @DATEFORMAT;
 
/*Test mode*/
 
SET ROWCOUNT @LIMIT_RECORDS
/*Change history comments*/
 
/*
       Title                : [B04_FIN_GLA_UNIV]
       Description   : 
    
       --------------------------------------------------------------
       Update history
       --------------------------------------------------------------
       Date                     |      Who                  |      Description
       DD-MM-YYYY                    Initials                      Initial version
       19-03-2017                      CW						   Update and standardisation for SID
       30-06-2017					   AJ						   Updated scripts with new naming convention
       28-07-2017					   ANH						   Updated scripts to integrate fields necessary for red flags
	   05-09-2017				|	   VL					|	   Update with new logic from S4HANA
	   24-03-2022					   Thuan					   Remove MANDT field in join
	   22-06-2022				|	   Thuan				|	   For Japan only replace OSL to VSL. Other region use OSL.
	   15-08-2024				|		Nam					|		Remove field from BSEG and add net due date from ACDOCA
*/
 
/*
	Step 1A Prepare REGUH, REGUP flag table
*/
 	  EXEC SP_DROPTABLE 'B00_00_TT_REGUH'
	  SELECT DISTINCT REGUH_ZBUKR,REGUH_VBLNR,REGUH_LIFNR INTO B00_00_TT_REGUH FROM A_REGUH
	  EXEC SP_CREATE_INDEX B00_00_TT_REGUH, 'B00_00_TT_REGUH', 'REGUH_ZBUKR, REGUH_VBLNR, REGUH_LIFNR'
	  EXEC SP_DROPTABLE 'B00_00B_TT_REGUP'
	  SELECT DISTINCT REGUP_BUKRS,REGUP_GJAHR,REGUP_BELNR,REGUP_SHKZG INTO B00_00B_TT_REGUP FROM A_REGUP
	  WHERE REGUP_XVORL = 'X'
	  EXEC SP_CREATE_INDEX B00_00B_TT_REGUP, 'B00_00B_TT_REGUP', 'REGUP_BUKRS, REGUP_GJAHR, REGUP_BELNR'
 
/*--Step 1
--This step orders cost centers by validity date in descending order, and adds a row number per
   combination of controlling area, cost centre and validity date
--Rows are being removed due to the following filters (WHERE):
                     CSKT_DATBI (Valid to date) is on or after the @downloaddate (ie that cost center is still valid at extraction)
*/

EXEC SP_REMOVE_TABLES 'B04_%'
 
EXEC sp_droptable    'B04_01_TT_CSKT'
 
           SELECT ROW_NUMBER () OVER (
                                PARTITION BY  B00_CSKT.CSKT_MANDT
                                                      ,B00_CSKT.CSKT_KOKRS
                                                      ,B00_CSKT.CSKT_KOSTL
                                ORDER BY    B00_CSKT.CSKT_DATBI DESC) AS #ROW
                                  ,B00_CSKT.CSKT_MANDT
                                  ,B00_CSKT.CSKT_KOKRS
                                  ,B00_CSKT.CSKT_KOSTL
                                  ,B00_CSKT.CSKT_KTEXT
                                  ,B00_CSKT.CSKT_LTEXT
                                  ,B00_CSKT.CSKT_MCTXT
                                  ,B00_CSKT.CSKT_DATBI
              INTO B04_01_TT_CSKT
              FROM B00_CSKT
              WHERE B00_CSKT.CSKT_DATBI >= @downloaddate
 
 
--Step 2
--Select the most recent information concerning cost centers
-- Only rows for which the most recent date is found per cost center are maintained

EXEC SP_DROPTABLE   'B04_02_TT_CSKT_DATBI' 
SELECT * INTO B04_02_TT_CSKT_DATBI FROM B04_01_TT_CSKT WHERE #ROW = 1
EXEC SP_CREATE_INDEX B04_02_TT_CSKT_DATBI, 'B04_02_TT_CSKT_DATBI_IDX', 'CSKT_MANDT, CSKT_KOSTL'

/*--Step 3
--Create a list of latest information per profit center
*/
	EXEC SP_DROPTABLE 'B04_03_TT_CEPCT'
	SELECT 
		A_CEPCT.*
		,ROW_NUMBER() OVER( PARTITION BY CEPCT_MANDT, CEPCT_PRCTR, CEPCT_KOKRS ORDER BY CEPCT_DATBI DESC) AS ROW_NR
	INTO B04_03_TT_CEPCT
	FROM A_CEPCT
	WHERE (CEPCT_SPRAS = @language1 OR CEPCT_SPRAS = @language2)
	AND CEPCT_DATBI> = @downloaddate

	EXEC SP_DROPTABLE 'B04_04_TT_CEPCT_UNIQUE'
	SELECT * INTO B04_04_TT_CEPCT_UNIQUE FROM B04_03_TT_CEPCT WHERE ROW_NR = 1 
/*--Step 3:
	Step 3.1:
-- Add the header information from the General Ledger (BKPF) to the detailed information from the General Ledger (ACDOCA)
-- Rows are being removed based on the following tables (because INNER JOIN):
                           Only keep lines for which mandate (MANDT) and company code (BUKRS) are found in AM_SCOPE table
-- In this step we add all of the information necessary for creating the list of accounting schemes per journal entry
*/
 
EXEC sp_droptable    'B04_05_IT_BKPF_ACDOCA'
 
		SELECT
			ACDOCA_RCLNT,
			SCOPE_BUSINESS_DMN_L1,
			SCOPE_BUSINESS_DMN_L2,                
			ACDOCA_RBUKRS,               
			ACDOCA_GJAHR,
			ACDOCA_RACCT,
			ACDOCA_KOART,                 
			ACDOCA_AWREF,
			ACDOCA_BELNR,
			ACDOCA_BUZEI, 
			ACDOCA_DOCLN,
			BKPF_GLVOR,
			BKPF_GRPID,
			BKPF_BKTXT,     
			BKPF_XBLNR,
			ACDOCA_SGTXT, 
			ACDOCA_BLDAT,                           
			LEFT(ACDOCA_TIMESTAMP, 8) ACDOCA_CPUDT,                                                             
			RIGHT(ACDOCA_TIMESTAMP,6) ACDOCA_CPUTM,
			ACDOCA_USNAM,                 
			ACDOCA_AWSYS,
			ACDOCA_BUDAT, 
			ACDOCA_AUGDT,
			ACDOCA_AUGBL,
			ACDOCA_BLART,                 
			ACDOCA_LIFNR,
			ACDOCA_EBELN,
			ACDOCA_EBELP,                             
			ACDOCA_KUNNR,
			ACDOCA_ANLN1,
			ACDOCA_ANLN2,
			ACDOCA_KTOSL,                 
			ACDOCA_PRCTR,                 
			ACDOCA_RCNTR,
			ACDOCA_KOKRS,           
			BKPF_TCODE,  
			TSTCT_TTEXT,              
			ACDOCA_DRCRK,
			ACDOCA_RWCUR,                
			ACDOCA_WSL,
			ACDOCA_RHCUR,               
			ACDOCA_HSL,  
			ACDOCA_BSCHL,   
			ACDOCA_NETDT,
			ACDOCA_AWTYP,              
			CONCAT( ACDOCA_AWREF, ACDOCA_AWORG) ACDOCA_AWKEY,
			ACDOCA_PS_POSID,
			ACDOCA_BSTAT,               
			CONCAT(SUBSTRING('00',1, 2 - LEN(ACDOCA_POPER % 16)),CAST((ACDOCA_POPER % 16) AS NVARCHAR)) AS ACDOCA_MONAT,
			ACDOCA_UMSKZ,
			T074T_LTEXT,
			ACDOCA_RRCTY,
			ACDOCA_RLDNR,
			ACDOCA_MATNR,
			ACDOCA_BWKEY,
			ACDOCA_RBUSA,
			ACDOCA_RKCUR,
			ACDOCA_KSL,
			ACDOCA_ROCUR,
			ACDOCA_OSL,
			ACDOCA_AUGGJ,               
			ACDOCA_AUFNR,            
			GL_BANK_ACC_HKONT,          
			SKA1_XBILK,               
			SKA1_GVTYP,
			SKB1_XGKON,
			SKB1_XOPVW,
			SKAT_TXT20,               
			CSKT_KTEXT,
			ACDOCA_ZUONR,
-- AR/AP clearing flag
			'' AS ZF_ACC_IS_AP_CLEARING,
			'' AS ZF_ACC_IS_AR_CLEARING,
			-- Add cost center description       
			CASE
			WHEN ISNULL(CSKT_MCTXT,'') = '' THEN 'Not assigned'
			ELSE CSKT_MCTXT
			END AS ZF_CSKT_MCTXT,
			CEPCT_MCTXT,
			T001_KTOPL,
			T001_BUTXT,
			--Debit/Credit and total with factor
			CONVERT(money,ACDOCA_HSL * ISNULL(TCURX_COC.TCURX_factor,1)) AS ZF_ACDOCA_HSL_S,
            CONVERT(money,ACDOCA_HSL * (CASE WHEN ACDOCA_DRCRK = 'S' THEN 1 ELSE 0 END) *(CASE WHEN ACDOCA_POPER = '000' THEN 0 ELSE 1 END)* ISNULL(TCURX_COC.TCURX_factor,1)) AS ZF_ACDOCA_HSL_DB,
            CONVERT(money,ACDOCA_HSL * (CASE WHEN ACDOCA_DRCRK = 'H' THEN 1 ELSE 0 END) *(CASE WHEN ACDOCA_POPER = '000' THEN 0 ELSE 1 END)* ISNULL(TCURX_COC.TCURX_factor,1)) AS ZF_ACDOCA_HSL_CR,
            ABS(CONVERT(money,ACDOCA_HSL* ISNULL(TCURX_COC.TCURX_factor,1))) AS ZF_ACDOCA_HSL_S_ABS,
			
			-- Add Posting month description
			CASE
				WHEN CAST(ACDOCA_POPER AS INT) IN (13,14,15,16) THEN 'Special Periods'
				WHEN CAST(ACDOCA_POPER AS INT) = 0 THEN 'Open'
				ELSE B00_T009B.T247_KTX
			END AS [BUDAT_MONTH_DESC] 

                    
	   INTO B04_05_IT_BKPF_ACDOCA
       FROM A_BKPF
       RIGHT JOIN B00_ACDOCA --RIGHT JOIN ONLY FOR VIETNAM REGION WITH PARALLEL SYSTEM
       ON	BKPF_GJAHR = ACDOCA_GJAHR AND
			BKPF_BUKRS = ACDOCA_RBUKRS AND
			BKPF_BELNR = ACDOCA_BELNR
 
 
    -- Filter on the mandates and company codes in scope
       -- Add information from the scope table concerning the business domain   
       INNER JOIN AM_SCOPE                                         
       ON	ACDOCA_RBUKRS = SCOPE_CMPNY_CODE  
			  
      
       -- Add information to show if the account is for bank accounts
       LEFT JOIN AM_GL_BANK_ACC                                       
       ON	GL_BANK_ACC_HKONT = ACDOCA_RACCT AND
			GL_BANK_ACC_BUKRS = ACDOCA_RBUKRS


       --Add chart of accounts code per company code
       LEFT JOIN A_T001                                             
       ON	T001_BUKRS = ACDOCA_RBUKRS                   
 
       -- Add chart of accounts and P&L statement account type	
       LEFT JOIN A_SKA1                                            
       ON	SKA1_KTOPL = T001_KTOPL AND               
            SKA1_SAKNR = ACDOCA_RACCT        
			  
	  -- Add Cash receipt account / cash disbursement account from SKB1
	  LEFT JOIN A_SKB1
	  ON	SKB1_BUKRS = ACDOCA_RBUKRS AND
			SKB1_SAKNR = ACDOCA_RACCT
 
		-- Add chart fo accounts description
       LEFT JOIN B00_SKAT                                             
       ON	SKAT_KTOPL = T001_KTOPL AND
			SKAT_SAKNR = ACDOCA_RACCT 

       -- $$ move CSKT join up from B04_04
       LEFT JOIN B04_02_TT_CSKT_DATBI                   
       ON	ACDOCA_KOKRS = CSKT_KOKRS AND
			ACDOCA_RCNTR = CSKT_KOSTL      

		-- Include profit centers descriptions
		LEFT JOIN B04_04_TT_CEPCT_UNIQUE
		ON	ACDOCA_KOKRS = CEPCT_KOKRS AND
			ACDOCA_PRCTR = CEPCT_PRCTR 

		LEFT JOIN B00_TCURX TCURX_COC
		ON ACDOCA_RHCUR = TCURX_COC.TCURX_CURRKEY

       --Add the transaction code description
       LEFT JOIN B00_TSTCT
       ON A_BKPF.BKPF_TCODE = TSTCT_TCODE

	   --Add posting month description
	   LEFT JOIN B00_T009B
	   ON A_T001.T001_PERIV = B00_T009B.T009B_PERIV
	   AND CAST(ACDOCA_POPER AS INT) = CAST(B00_T009B.T009B_POPER AS INT)

	  --Add special g/l indicator desc
	  LEFT JOIN A_T074T
		ON T074T_SPRAS IN ('E', 'EN')
		AND ACDOCA_KOART = T074T_KOART
		AND ACDOCA_UMSKZ = T074T_SHBKZ
	WHERE ACDOCA_GJAHR >= @FISCAL_YEAR_FROM AND ACDOCA_GJAHR <= @FISCAL_YEAR_TO

	/*
		Step 3.1: Create a flag in order to flag documents of bank accounts in A_T012K, A_FEBKO and SKB1 tables
	*/

	EXEC SP_CREATE_INDEX B04_05_IT_BKPF_ACDOCA, 'B04_05_RBUKS_RACCT_INDEX', 'ACDOCA_RBUKRS, ACDOCA_RACCT'
	ALTER TABLE B04_05_IT_BKPF_ACDOCA ADD ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG NVARCHAR(1) DEFAULT '' WITH VALUES;
	UPDATE B04_05_IT_BKPF_ACDOCA
	SET ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG = 'Y'
	WHERE 
	-- G/L account exist in the T012K
	EXISTS(
		SELECT TOP 1 1
		FROM A_T012K
		WHERE B04_05_IT_BKPF_ACDOCA.ACDOCA_RBUKRS = A_T012K.T012K_BUKRS AND
			  B04_05_IT_BKPF_ACDOCA.ACDOCA_RACCT = A_T012K.T012K_HKONT
	)

	-- OR G/L account exists in the FEBKO 
	OR	EXISTS(
				SELECT TOP 1 1
				FROM A_FEBKO
				WHERE B04_05_IT_BKPF_ACDOCA.ACDOCA_RBUKRS = A_FEBKO.FEBKO_BUKRS AND
					  B04_05_IT_BKPF_ACDOCA.ACDOCA_RACCT = A_FEBKO.FEBKO_HKONT
	)
	
	-- OR G/L account which has SKB1_HBKID or SKB1_XGKON not blank
	OR EXISTS (
		SELECT TOP 1 1
		FROM A_SKB1
		WHERE B04_05_IT_BKPF_ACDOCA.ACDOCA_RBUKRS = A_SKB1.SKB1_BUKRS AND
			  B04_05_IT_BKPF_ACDOCA.ACDOCA_RACCT = A_SKB1.SKB1_SAKNR AND
			  (ISNULL(A_SKB1.SKB1_HBKID, '') <> '' OR ISNULL(A_SKB1.SKB1_XGKON, '') <> '')
	)


	UPDATE B04_05_IT_BKPF_ACDOCA SET ZF_ACC_IS_AP_CLEARING='Y'
	WHERE EXISTS
	(
		SELECT TOP 1 1
		FROM AM_AP_CLEARING
		WHERE ACDOCA_RACCT=AM_AP_CLEARING.ZF_ACCOUNTS AND
			  ZF_AP_CLEARING='X'
	)

--Add the flag if the accoutn relate to AR clearing

	UPDATE B04_05_IT_BKPF_ACDOCA SET ZF_ACC_IS_AR_CLEARING='Y'
	WHERE EXISTS
	(
		SELECT TOP 1 1
		FROM AM_AR_CLEARING
		WHERE ACDOCA_RACCT=AM_AR_CLEARING.ZF_ACCOUNTS AND
			  ZF_AR_CLEARING='X'
	)



/*--Step 4
-- Create a temporary table that contains information about electronic bank payments
-- Rows are being removed due to the following filters (WHERE):
                           Accounting document number(FEBEP_BELNR) is not Null or *
-- Rows are being removed based on the following tables (because INNER JOIN):
                           Only keep lines for which Mandant of Electronic statement line items(FEBEP) matches Mandant of Electronic Bank Statement Header Records(FEBKO)
                           Only keep lines for which Shortkey(KUKEY) of Electronic statement line items(FEBEP) matches Short key(KUKEY) of Electronic Bank Statement Header Records(FEBKO)
*/
 
EXEC sp_droptable    'B04_06_TT_FEBKO_EP'
 
       SELECT DISTINCT
              A_FEBKO.FEBKO_MANDT
              ,A_FEBKO.FEBKO_BUKRS
              ,A_FEBEP.FEBEP_GJAHR
              ,A_FEBEP.FEBEP_BELNR
      
       INTO B04_06_TT_FEBKO_EP
       FROM A_FEBKO
       INNER JOIN A_FEBEP
       ON  A_FEBKO.FEBKO_KUKEY = A_FEBEP.FEBEP_KUKEY
      
       WHERE
              A_FEBEP.FEBEP_BELNR NOT LIKE '' AND -- Manual bank payments lead to direct GL entries and will have a document number; otherwise B1DOC and B2DOC will have references of GL documents cleared by EBS
              A_FEBEP.FEBEP_BELNR NOT LIKE '*'
      
/*--Step 5
-- Create a list of indicators based on GL
*/
 
EXEC SP_DROPTABLE    'B04_07_TT_INDIC_PER_JE_NUM'
   
      SELECT
		   B04_05_IT_BKPF_ACDOCA.ACDOCA_RCLNT
          ,B04_05_IT_BKPF_ACDOCA.ACDOCA_RBUKRS 
          ,B04_05_IT_BKPF_ACDOCA.ACDOCA_GJAHR
		  ,B04_05_IT_BKPF_ACDOCA.ACDOCA_BELNR
          ,B04_05_IT_BKPF_ACDOCA.BKPF_BKTXT AS BKPF_BKTXT
          ,CASE
             WHEN (B04_05_IT_BKPF_ACDOCA.BKPF_BKTXT LIKE '%auto%' AND B04_05_IT_BKPF_ACDOCA.BKPF_BKTXT LIKE '%clear%')
                               THEN 'X'
             ELSE ''
           END AS ZF_BKPF_BKTXT_AUTO_CLEAR
         INTO B04_07_TT_INDIC_PER_JE_NUM
         FROM B04_05_IT_BKPF_ACDOCA
         GROUP BY
            ACDOCA_RCLNT, ACDOCA_RBUKRS, ACDOCA_GJAHR, ACDOCA_BELNR, BKPF_BKTXT
 
 
/*--Step 6
-- All of the above information is added to the GL
-- The following hard-coded values are found in this step:
--    Months  (based on BKPF_MONAT) and assuming it is a calendar from 1st April
--    Description of GL account type (ACDOCA_KOART)
--Fields are being added from other SAP tables as mentioned in JOIN clauses below
--Fields are being calculated as mentioned in SELECT clause below*/


 EXEC SP_DROPTABLE 'B04_08_IT_FIN_GL'
            SELECT

                    B04_05_IT_BKPF_ACDOCA.ACDOCA_RCLNT,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_RBUKRS,
					B04_05_IT_BKPF_ACDOCA.ACDOCA_GJAHR,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_AWREF,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_BELNR,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_BUZEI,
					B04_05_IT_BKPF_ACDOCA.ACDOCA_DOCLN,
					B04_05_IT_BKPF_ACDOCA.BKPF_XBLNR,
                    --B04_05_IT_BKPF_ACDOCA.T001_BUTXT,
                    -- Add fiscal year + posting period
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_GJAHR + '-' + B04_05_IT_BKPF_ACDOCA.ACDOCA_MONAT AS ZF_ACDOCA_GJAHR_MONAT,
                    CAST(YEAR(B04_05_IT_BKPF_ACDOCA.ACDOCA_BUDAT) AS VARCHAR(4)) + '-' +
                        RIGHT('0' + CAST(MONTH(B04_05_IT_BKPF_ACDOCA.ACDOCA_BUDAT) AS VARCHAR(2)),2) AS ZF_ACDOCA_BUDAT_YEAR_MNTH,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_KOART,
                    -- Add acount type description
                    CASE
                        WHEN B04_05_IT_BKPF_ACDOCA.ACDOCA_KOART = 'A' THEN 'Assets'
                        WHEN B04_05_IT_BKPF_ACDOCA.ACDOCA_KOART = 'D' THEN 'Customers'
                        WHEN B04_05_IT_BKPF_ACDOCA.ACDOCA_KOART = 'K' THEN 'Vendors'
                        WHEN B04_05_IT_BKPF_ACDOCA.ACDOCA_KOART = 'M' THEN 'Material'
                        WHEN B04_05_IT_BKPF_ACDOCA.ACDOCA_KOART = 'S' THEN 'G/L accounts'
                        ELSE ''
                    END                                                                  AS ZF_ACDOCA_KOART_DESC,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_RACCT SPCAT_GL_ACCNT,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_BSCHL,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_BLART,
                    B04_05_IT_BKPF_ACDOCA.BKPF_BKTXT,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_SGTXT,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_BLDAT,
                    CONVERT(DATE,B04_05_IT_BKPF_ACDOCA.ACDOCA_CPUDT) AS ACDOCA_CPUDT,      
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_CPUTM,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_USNAM,
                    B04_05_IT_BKPF_ACDOCA.BKPF_TCODE,
					B04_05_IT_BKPF_ACDOCA.TSTCT_TTEXT,
					B04_05_IT_BKPF_ACDOCA.T001_KTOPL,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_BUDAT,
					B04_05_IT_BKPF_ACDOCA.BUDAT_MONTH_DESC,
					B04_05_IT_BKPF_ACDOCA.ACDOCA_NETDT, -- Nam: add net due date
					CASE 
						WHEN T009B_POPER IN ('1','2','3') THEN 'Q1'
						WHEN T009B_POPER IN ('4','5','6') THEN 'Q2'
						WHEN T009B_POPER IN ('7','8','9') THEN 'Q3'
						WHEN T009B_POPER IN ('10','11','12') THEN 'Q4'
						ELSE 'unable to classify'
					END ZF_ACDOCA_BUDAT_FQ,
					CASE	
						WHEN CAST(ACDOCA_MONAT AS INT) = 0 THEN 'Open'
						WHEN CAST(ACDOCA_MONAT AS INT) IN (1, 2, 3) THEN 'Q1'
						WHEN CAST(ACDOCA_MONAT AS INT) IN (4, 5, 6) THEN 'Q2'
						WHEN CAST(ACDOCA_MONAT AS INT) IN (7, 8, 9) THEN 'Q3'
						WHEN CAST(ACDOCA_MONAT AS INT) IN (10, 11, 12) THEN 'Q4'
						ELSE 'Special Quater' 
					END AS ZF_ACDOCA_MONAT_FQ,
                    -- Add flag to show if it is posted in the period
                    CASE
                        WHEN B04_05_IT_BKPF_ACDOCA.ACDOCA_BUDAT >= @date1 AND B04_05_IT_BKPF_ACDOCA.ACDOCA_BUDAT <= @date2 THEN 'X'
                        ELSE ''
                    END AS ZF_ACDOCA_BUDAT_IN_PERIOD,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_AUGDT,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_AUGBL,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_BWKEY,
					B04_05_IT_BKPF_ACDOCA.ACDOCA_LIFNR,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_KUNNR,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_MATNR,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_ANLN1,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_ANLN2,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_PS_POSID,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_EBELN,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_EBELP,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_RCNTR,
					B04_05_IT_BKPF_ACDOCA.ACDOCA_AUGGJ,
					B04_05_IT_BKPF_ACDOCA.ACDOCA_RACCT,
					B04_05_IT_BKPF_ACDOCA.ACDOCA_UMSKZ,
					B04_05_IT_BKPF_ACDOCA.T074T_LTEXT,
					B04_05_IT_BKPF_ACDOCA.ACDOCA_RRCTY,
					B04_05_IT_BKPF_ACDOCA.ACDOCA_RLDNR,
					B04_05_IT_BKPF_ACDOCA.ACDOCA_AUFNR,
					B04_05_IT_BKPF_ACDOCA.ACDOCA_RBUSA,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_DRCRK,
                    -- Add Debit/Credit description
                    CASE B04_05_IT_BKPF_ACDOCA.ACDOCA_DRCRK
						WHEN 'S'  THEN 'Debit'
						WHEN 'H'  THEN 'Credit'
						END                                                                        
					AS ZF_ACDOCA_DRCRK_DESC,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_RWCUR                                             AS ACDOCA_RWCUR,
 
                    -- Add value (document currency)
                    CONVERT(money,B04_05_IT_BKPF_ACDOCA.ACDOCA_WSL * ISNULL(TCURX_DOC.TCURX_factor,1)) AS ZF_ACDOCA_WSL_S_DOC, 
 
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_RHCUR,
 
                    -- Add Value(company currency)
                    CONVERT(money,B04_05_IT_BKPF_ACDOCA.ACDOCA_HSL * ISNULL(TCURX_COC.TCURX_factor,1)) AS ZF_ACDOCA_HSL_S,
                    CONVERT(money,B04_05_IT_BKPF_ACDOCA.ACDOCA_HSL * (CASE WHEN B04_05_IT_BKPF_ACDOCA.ACDOCA_DRCRK = 'S' THEN 1 ELSE 0 END) * ISNULL(TCURX_COC.TCURX_factor,1)) AS ZF_ACDOCA_HSL_DB,
                    CONVERT(money,B04_05_IT_BKPF_ACDOCA.ACDOCA_HSL * (CASE WHEN B04_05_IT_BKPF_ACDOCA.ACDOCA_DRCRK = 'H' THEN 1 ELSE 0 END) * ISNULL(TCURX_COC.TCURX_factor,1)) AS ZF_ACDOCA_HSL_CR,
                   
				   
				   ABS(CONVERT(money,B04_05_IT_BKPF_ACDOCA.ACDOCA_HSL* ISNULL(TCURX_COC.TCURX_factor,1))) AS ZF_ACDOCA_HSL_S_ABS,
                    
                    @currency AS AM_GLOBALS_CURRENCY,
                    -- Add Value(custom currency)
                    CONVERT(money,B04_05_IT_BKPF_ACDOCA.ACDOCA_KSL * ISNULL(TCURX_KSL.TCURX_factor,1)) AS ZF_ACDOCA_HSL_S_CUC,
					B04_05_IT_BKPF_ACDOCA.ACDOCA_RKCUR,
					CONVERT(money,B04_05_IT_BKPF_ACDOCA.ACDOCA_KSL * ISNULL(TCURX_KSL.TCURX_factor,1))  ZF_ACDOCA_KSL_S,
					B04_05_IT_BKPF_ACDOCA.ACDOCA_ROCUR,
					CONVERT(money,B04_05_IT_BKPF_ACDOCA.ACDOCA_OSL * ISNULL(TCURX_OSL.TCURX_factor,1))  ZF_ACDOCA_OSL_S,
					B04_05_IT_BKPF_ACDOCA.ACDOCA_AWSYS,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_KTOSL,  
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_AWTYP,
 
                    -- Add Reference document
                    Left(B04_05_IT_BKPF_ACDOCA.ACDOCA_AWKEY, 10)                             AS ZF_ACDOCA_AWKEY_DOC_NUM,
 
                    -- Add Reference year
                    RIGHT(B04_05_IT_BKPF_ACDOCA.ACDOCA_AWKEY,4)                              AS ZF_ACDOCA_AWKEY_YEAR,
                    B04_05_IT_BKPF_ACDOCA.ACDOCA_BSTAT,
                    A_T074U.T074U_MERKP,
					B04_05_IT_BKPF_ACDOCA.ACDOCA_ZUONR,
 
                    -- Add indicator to show if it is an electronic bank payment
                    CASE WHEN
                        B04_06_TT_FEBKO_EP.FEBEP_BELNR IS NULL THEN ''
                        ELSE 'X'
                    END                                                                        AS ZF_FEBEP_ELEC_BANK_PAY,
                    -- Add description of document status
                    CASE
                        WHEN ISNULL(A_T074U.T074U_MERKP,'') = '' THEN
                                CASE ACDOCA_BSTAT
                                        WHEN 'V' THEN 'Parked'
                                        WHEN 'W' THEN 'Parked'
                                        WHEN 'Z' THEN 'Parked'
                                        WHEN 'S' THEN 'Noted'
                                        WHEN ''  THEN 'Normal'
                                        ELSE 'Other non-financial items'
                                END
                        ELSE  'Noted'     
                    END                                                                  AS ZF_ACDOCA_BSTAT_DESC
 
 
                -- Add cost center description
                    ,B04_05_IT_BKPF_ACDOCA.ZF_CSKT_MCTXT
				-- add profit center desc
				    ,B04_05_IT_BKPF_ACDOCA.ACDOCA_PRCTR
				    ,B04_05_IT_BKPF_ACDOCA.CEPCT_MCTXT
				-- Concatenate codes and descriptions
                    ,B04_05_IT_BKPF_ACDOCA.ACDOCA_KOART + ' - '  + CASE
                        WHEN B04_05_IT_BKPF_ACDOCA.ACDOCA_KOART = 'A' THEN 'Assets'
                        WHEN B04_05_IT_BKPF_ACDOCA.ACDOCA_KOART = 'D' THEN 'Customers'
                        WHEN B04_05_IT_BKPF_ACDOCA.ACDOCA_KOART = 'K' THEN 'Vendors'
                        WHEN B04_05_IT_BKPF_ACDOCA.ACDOCA_KOART = 'M' THEN 'Material'
                        WHEN B04_05_IT_BKPF_ACDOCA.ACDOCA_KOART = 'S' THEN 'G/L accounts'
                        ELSE ''
                    END  AS ZF_ACDOCA_KOART_TEXT
                    ,B04_05_IT_BKPF_ACDOCA.ACDOCA_RCNTR + ' - '  + B04_05_IT_BKPF_ACDOCA.ZF_CSKT_MCTXT AS ACDOCA_RCNTR_CSKT_MCTXT 
					,B04_05_IT_BKPF_ACDOCA.ACDOCA_KOKRS
 
       -- Additional fields that are required for manual journal entries consideration
 
               ,ZF_BKPF_BKTXT_AUTO_CLEAR

        -- Additional fields that are interesting for manual journal entry analysis

         ,CASE 
            WHEN DATENAME(DW, ACDOCA_CPUDT) IN ('Saturday', 'Sunday') THEN 'X' 
            ELSE '' 
          END AS ZF_ACDOCA_CPUDT_WE 
         ,CASE 
            WHEN DATEPART(MM, ACDOCA_CPUDT) <> DATEPART(MM, ACDOCA_BUDAT) THEN 'Posted in other month' 
            ELSE 'Posted in same month' 
          END AS ZF_BUDAT_SAME_MONTH_CPUDT
         ,CASE 
            WHEN DATEPART(MM, ACDOCA_CPUDT) <> DATEPART(MM, ACDOCA_BLDAT) THEN 
                           CONVERT (NVARCHAR, DATEDIFF(DD, ACDOCA_CPUDT, ACDOCA_BLDAT)) 
            ELSE 'Posted in same month' 
          END AS ZF_CPUDT_MINUS_BLDAT 
         ,ABS(CONVERT(money,B04_05_IT_BKPF_ACDOCA.ACDOCA_KSL * ISNULL(TCURX_KSL.TCURX_factor,1)))
                AS ZF_ACDOCA_HSL_CUC_ABS
		-- Fields required for debit-credit refresh
		,CASE WHEN
			(ACDOCA_BSTAT = '' AND ISNULL(T074U_MERKP,'') = '')
			AND (BKPF_GLVOR LIKE 'RF%' OR BKPF_GLVOR LIKE 'RG%')
			AND ACDOCA_AWTYP IN ('BKPF', 'BKPFF', 'BKPFI', 'FOTP', '')
			AND ISNULL(BKPF_GRPID, '') = ''
			AND (USR02_USTYP = 'A' OR USR02_USTYP = 'S' OR ISNULL(USR02_USTYP, '') = '')
			AND (BKPF_TCODE LIKE 'F%' OR BKPF_TCODE LIKE 'Y%' OR BKPF_TCODE LIKE 'Z%' OR BKPF_TCODE IN ('ABF1', 'J1IH', 'SBWP', 'SO01'))
			AND BKPF_TCODE NOT IN ('F110', 'F150', 'FN5V', 'FNM1', 'FNM1S', 'FNM3', 'FNV5')
			AND BKPF_TCODE NOT IN ('FB21', 'FB22', 'FBA3', 'FBA8', 'FBCJ', 'FBW2', 'FBW4', 'FBZ4', 'FINT')
			AND ISNULL(B04_06_TT_FEBKO_EP.FEBEP_BELNR, '') = ''
			AND ISNULL(ZF_BKPF_BKTXT_AUTO_CLEAR, '') = '' THEN  'Manual'
			WHEN BKPF_TCODE LIKE 'FBVB' AND ACDOCA_BLART IN ('AT', 'D<', 'D>' , 'DG', 'DH', 'DM', 'DQ', 'DR', 'SA', 'SN')  THEN  'Manual'	
		ELSE 'Regular' END AS ZF_ENTRY_TYPE,
--  2023-08-11 Thuan add more field in B04_09 to calculate accounting scheme.
		ACDOCA_MONAT
-- Add Account type detail based on request from Claire.
		,CASE 
			
				WHEN ACDOCA_KOART <> 'S' THEN ACDOCA_KOART
				WHEN ACDOCA_KOART = 'S' AND  
					(
						ISNULL(A_SKB1.SKB1_HBKID,'') <> '' OR ISNULL(A_SKB1.SKB1_XGKON,'') <> ''
						 OR ZF_ACC_IS_AR_CLEARING
						 ='Y' OR ZF_ACC_IS_AP_CLEARING='Y' --kHOI
					)	THEN 'S: Bank'
				WHEN ACDOCA_KOART = 'S' AND  ( ISNULL(SKA1_GVTYP,'') <> ''  )	
					THEN  
						CASE WHEN LEN(ACDOCA_PRCTR)>0 THEN 'S: P&L : Profit'
							 WHEN LEN(ACDOCA_RCNTR)>0 THEN 'S: P&L : Loss'
							ELSE 'S: P&L ' END

				WHEN ACDOCA_KOART = 'S' AND  
					(
						 ISNULL(SKA1_XBILK,'') <> ''  AND  ( ISNULL(A_SKB1.SKB1_HBKID,'') = '' AND ISNULL(A_SKB1.SKB1_XGKON,'') = '')
					)	THEN 'S: BS other'
				ELSE 'Other cases' 
		END AS ZF_ACDOCA_KOART,
	    T003T_LTEXT,  -- Document type description.
	    V_USERNAME_NAME_TEXT, --  Full Name of user name
		A_KNA1.KNA1_KTOKD, -- Customer group number
		T077X_TXT30, -- Customer group name
		A_LFA1.LFA1_KTOKK,  -- Supplier group number
		T077Y_TXT30, -- Supplier group text
		SKAT_TXT20,  -- GL desc
		SKA1_GVTYP,  -- P&L statement account type
		B04_05_IT_BKPF_ACDOCA.T001_BUTXT,  -- Company code desc
		CONVERT(money,B04_05_IT_BKPF_ACDOCA.ACDOCA_KSL * (CASE WHEN B04_05_IT_BKPF_ACDOCA.ACDOCA_DRCRK = 'S' THEN 1 ELSE 0 END) * ISNULL(TCURX_KSL.TCURX_factor,1)) AS ZF_ACDOCA_HSL_DB_CUC,
        CONVERT(money,B04_05_IT_BKPF_ACDOCA.ACDOCA_KSL * (CASE WHEN B04_05_IT_BKPF_ACDOCA.ACDOCA_DRCRK = 'H' THEN 1 ELSE 0 END) * ISNULL(TCURX_KSL.TCURX_factor,1)) AS ZF_ACDOCA_HSL_CR_CUC,
        TANGO_ACCT, -- Get tango account
		TANGO_ACCT_TXT, -- Get tango account description.   
       ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG,
	--AR/AP clearing
	   ZF_ACC_IS_AR_CLEARING,
	   ZF_ACC_IS_AP_CLEARING,
	   '' AS ZF_RACCT_FOUND_IN_CSKB,
	   IIF(ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG='Y' OR ZF_ACC_IS_AR_CLEARING='Y' OR ZF_ACC_IS_AR_CLEARING='Y','Y','') AS ZF_ACCOUNT_IS_BANK,

	   A_KNA1.KNA1_NAME1 AS ACDOCA_KNA1_NAME1,
	   A_KNA1.KNA1_LIFNR AS ACDOCA_KNA1_LIFNR,
	   A_LFA1_B.LFA1_NAME1 AS ACDOCA_KNA1_LIFNR_NAME1,

	   A_LFA1.LFA1_NAME1 AS ACDOCA_LFA1_NAME1,
	   A_LFA1.LFA1_KUNNR AS ACDOCA_LFA1_KUNNR,
	   A_KNA1_B.KNA1_NAME1 AS ACDOCA_LFA1_KUNNR_NAME1,

		A_ANLT.ANLT_TXT50,
		MARA_MATKL,
		B00_T023T.T023T_WGBEZ

	   INTO B04_08_IT_FIN_GL
        
		FROM B04_05_IT_BKPF_ACDOCA        
		LEFT JOIN A_T001
			ON  A_T001.T001_BUKRS = ACDOCA_RBUKRS
		LEFT JOIN B00_T009B
			ON	A_T001.T001_PERIV = T009B_PERIV
				AND MONTH(ACDOCA_BUDAT) = T009B_BUMON
		LEFT JOIN A_USR02
              ON	(B04_05_IT_BKPF_ACDOCA.ACDOCA_USNAM = A_USR02.USR02_BNAME) 

           -- Add currency factor for house currency
		LEFT JOIN B00_TCURX TCURX_COC
		ON	B04_05_IT_BKPF_ACDOCA.ACDOCA_RHCUR = TCURX_COC.TCURX_CURRKEY

       -- Add currency factor for document currency   
		LEFT JOIN B00_TCURX TCURX_DOC
		ON	B04_05_IT_BKPF_ACDOCA.ACDOCA_RWCUR = TCURX_DOC.TCURX_CURRKEY
		-- Add currency factor for KSL currency   
		LEFT JOIN B00_TCURX TCURX_KSL
		ON	B04_05_IT_BKPF_ACDOCA.ACDOCA_RKCUR = TCURX_KSL.TCURX_CURRKEY

		-- Add currency factor for OSL currency   
		LEFT JOIN B00_TCURX TCURX_OSL
		ON	B04_05_IT_BKPF_ACDOCA.ACDOCA_ROCUR = TCURX_OSL.TCURX_CURRKEY
             
		-- Add account type info and Special GL's
		LEFT JOIN A_T074U
		ON	(B04_05_IT_BKPF_ACDOCA.ACDOCA_KOART = A_T074U.T074U_KOART) AND	
			(B04_05_IT_BKPF_ACDOCA.ACDOCA_UMSKZ = A_T074U.T074U_UMSKZ)

        -- Add information about electronic bank payments    
        LEFT JOIN B04_06_TT_FEBKO_EP
        ON	(B04_05_IT_BKPF_ACDOCA.ACDOCA_RBUKRS = B04_06_TT_FEBKO_EP.FEBKO_BUKRS) AND
            (B04_05_IT_BKPF_ACDOCA.ACDOCA_GJAHR = B04_06_TT_FEBKO_EP.FEBEP_GJAHR) AND
            (B04_05_IT_BKPF_ACDOCA.ACDOCA_BELNR = B04_06_TT_FEBKO_EP.FEBEP_BELNR)

        ---- Add information indicators from GL itself
        LEFT JOIN B04_07_TT_INDIC_PER_JE_NUM
        ON	B04_05_IT_BKPF_ACDOCA.ACDOCA_RBUKRS = B04_07_TT_INDIC_PER_JE_NUM.ACDOCA_RBUKRS AND
			B04_05_IT_BKPF_ACDOCA.ACDOCA_GJAHR = B04_07_TT_INDIC_PER_JE_NUM.ACDOCA_GJAHR AND 
			B04_05_IT_BKPF_ACDOCA.ACDOCA_BELNR = B04_07_TT_INDIC_PER_JE_NUM.ACDOCA_BELNR

		-- Add document type description.
				LEFT JOIN B00_T003T
				ON B04_05_IT_BKPF_ACDOCA.ACDOCA_BLART = T003T_BLART -- Get document type description from B00_T003T : Document type description filtered language key is english
		-- Add user name full text
				LEFT JOIN A_V_USERNAME
				  ON B04_05_IT_BKPF_ACDOCA.ACDOCA_USNAM = A_V_USERNAME.V_USERNAME_BNAME
		-- Get customer group
				LEFT JOIN A_KNA1 ON B04_05_IT_BKPF_ACDOCA.ACDOCA_KUNNR = KNA1_KUNNR
		-- Add Account Group Name
				LEFT JOIN AM_T077X ON KNA1_KTOKD = AM_T077X.T077X_KTOKD AND
				AM_T077X.T077X_SPRAS IN ('E', 'EN')
		-- Get supplier group number
				LEFT JOIN A_LFA1 ON B04_05_IT_BKPF_ACDOCA.ACDOCA_LIFNR = LFA1_LIFNR
		-- Add supplier group name for supplier
				LEFT JOIN AM_T077Y ON A_LFA1.LFA1_KTOKK = AM_T077Y.T077Y_KTOKK AND
				AM_T077Y.T077Y_SPRAS IN ('E', 'EN')
		-- Add tango account text
				LEFT JOIN AM_TANGO_20F_MAPPING ON TANGO_GL_ACCT = B04_05_IT_BKPF_ACDOCA.ACDOCA_RACCT
		LEFT JOIN A_SKB1
			ON  SKB1_BUKRS = B04_05_IT_BKPF_ACDOCA.ACDOCA_RBUKRS 
				AND SKB1_SAKNR = B04_05_IT_BKPF_ACDOCA.ACDOCA_RACCT
		--Add material name and grouP
		LEFT JOIN A_MARA 
			ON MARA_MATNR=ACDOCA_MATNR
		--Add material group name
		LEFT JOIN B00_T023T
			ON MARA_MATKL=T023T_MATKL
		--Add asset descriptop
		LEFT JOIN A_ANLT
			ON ANLT_BUKRS=B04_05_IT_BKPF_ACDOCA.ACDOCA_RBUKRS AND
			   ANLT_ANLN1=B04_05_IT_BKPF_ACDOCA.ACDOCA_ANLN1 AND
			   ANLT_ANLN2=B04_05_IT_BKPF_ACDOCA.ACDOCA_ANLN2

		--Add LFA1_KUNNR name
		LEFT JOIN A_KNA1 AS A_KNA1_B
			ON A_KNA1_B.KNA1_KUNNR=A_LFA1.LFA1_KUNNR
		--Add KNA1_LIFNR name
		LEFT JOIN A_LFA1 AS A_LFA1_B
			ON A_LFA1_B.LFA1_LIFNR=A_KNA1.KNA1_LIFNR
		-- Only keep journal entry lines that are posted and not noted and for which the posting
		-- date is between the dates specified by the user
		WHERE  ISNULL(A_T074U.T074U_MERKP,'') = ''
		AND	   B04_05_IT_BKPF_ACDOCA.ACDOCA_BSTAT = '' AND B04_05_IT_BKPF_ACDOCA.ACDOCA_KOART IN ('A', 'D','K', 'M', 'S')
		AND	   B04_05_IT_BKPF_ACDOCA.ACDOCA_BUZEI <> '000'


UPDATE B04_08_IT_FIN_GL
SET ZF_RACCT_FOUND_IN_CSKB='Y'
WHERE EXISTS
(
	SELECT TOP 1 1
	FROM A_CSKB
	WHERE ACDOCA_KOKRS = A_CSKB.CSKB_KOKRS AND
		  ACDOCA_RACCT = A_CSKB.CSKB_KSTAR AND
		(YEAR(A_CSKB.CSKB_DATBI) = N'9999' OR A_CSKB.CSKB_DATBI >= ACDOCA_BLDAT )
)

-- Step 7 / Run accounting scheme
-- Step 7.1 / Split into credit table to reduce run time 
-- Step 7.1.1 / Create GL credit table

EXEC SP_DROPTABLE    'B04_08_TT_FIN_GL_CREDIT'
SELECT * INTO B04_08_TT_FIN_GL_CREDIT
FROM B04_08_IT_FIN_GL
WHERE ACDOCA_DRCRK = 'H'

-- Step 7.1.2 Create index 

CREATE INDEX ZF_ACDOCA_RCNTR_AND_DESC_INDEX ON B04_08_TT_FIN_GL_CREDIT(ACDOCA_RCNTR, ZF_CSKT_MCTXT)
CREATE INDEX ZF_ACDOCA_PRCTR_AND_DESC_INDEX ON B04_08_TT_FIN_GL_CREDIT(ACDOCA_PRCTR, CEPCT_MCTXT)
CREATE INDEX ZF_ACC_IS_AP_CLEARING_INDEX ON B04_08_TT_FIN_GL_CREDIT(ZF_ACC_IS_AP_CLEARING)
CREATE INDEX ZF_ACC_IS_AR_CLEARING_INDEX ON B04_08_TT_FIN_GL_CREDIT(ZF_ACC_IS_AR_CLEARING)
CREATE INDEX ZF_ACDOCA_KOART_INDEX ON B04_08_TT_FIN_GL_CREDIT(ACDOCA_KOART, ZF_ACDOCA_KOART_DESC )
CREATE INDEX ZF_ACCOUNTS_DESC_COMBINE_INDEX ON B04_08_TT_FIN_GL_CREDIT(ACDOCA_RACCT, SKAT_TXT20)
CREATE INDEX ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_INDEX ON B04_08_TT_FIN_GL_CREDIT(ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG)
CREATE INDEX ZF_SKA1_GVTYP_INDEX ON B04_08_TT_FIN_GL_CREDIT(SKA1_GVTYP)
CREATE INDEX ZF_MARA_MATKL_INDEX ON B04_08_TT_FIN_GL_CREDIT(MARA_MATKL,T023T_WGBEZ)
CREATE INDEX ZF_ANLN1_ANLN2_DEBIT_LIST_INDEX ON B04_08_TT_FIN_GL_CREDIT(ACDOCA_ANLN1,ACDOCA_ANLN2, ANLT_TXT50 )
CREATE INDEX ZF_RACCT_FOUND_IN_CSKB_INDEX ON B04_08_TT_FIN_GL_CREDIT(ZF_RACCT_FOUND_IN_CSKB)
CREATE INDEX ZF_ZF_ACDOCA_KOART1_INDEX ON B04_08_TT_FIN_GL_CREDIT(ZF_ACDOCA_KOART)
CREATE INDEX ZF_ACDOCA_LFA1_KTOKK_INDEX ON B04_08_TT_FIN_GL_CREDIT(LFA1_KTOKK, T077Y_TXT30)
CREATE INDEX ZF_ACDOCA_KUNNR_INDEX ON B04_08_TT_FIN_GL_CREDIT(ACDOCA_KUNNR,ACDOCA_KNA1_NAME1)
CREATE INDEX ZF_ACDOCA_KNA1_KTOKD_INDEX ON B04_08_TT_FIN_GL_CREDIT(KNA1_KTOKD,T077X_TXT30)
CREATE INDEX ZF_ACDOCA_TANGO_ACCT_INDEX ON B04_08_TT_FIN_GL_CREDIT(TANGO_ACCT)
CREATE INDEX ZF_ACDOCA_RACCT_INDEX ON B04_08_TT_FIN_GL_CREDIT(ACDOCA_RACCT)
CREATE INDEX ZF_SKAT_TXT20_INDEX ON B04_08_TT_FIN_GL_CREDIT(SKAT_TXT20)
CREATE INDEX ZF_RBUKRS_GJAHR_BELNR_INDEX ON B04_08_TT_FIN_GL_CREDIT(ACDOCA_RBUKRS, ACDOCA_GJAHR, ACDOCA_BELNR)

-- Step 7.1.3 / Run accounting for GL detail table

EXEC SP_DROPTABLE    'B04_08_TT_ACCOUNTING_CREDIT'

SELECT
     B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS -- Company code
    ,B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR -- Fiscal year
    ,B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR, -- Documnent number
-- Create a list of Cost center Credit
    REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.ACDOCA_RCNTR+':'+B.ZF_CSKT_MCTXT)=1,'_', B.ACDOCA_RCNTR+':'+B.ZF_CSKT_MCTXT),'_')
    FROM B04_08_TT_FIN_GL_CREDIT B
    WHERE 
		(
			B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
		)
    GROUP BY B.ACDOCA_RACCT, B.ACDOCA_RCNTR,B.ZF_CSKT_MCTXT
	ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)'),1,1,''),'_') , '__', '_') ZF_CREDIT_ACDOCA_RCNTR_AND_DESC
-- Create a list of profit center Credit
    ,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.ACDOCA_PRCTR+':'+B.CEPCT_MCTXT)=1 ,'' ,B.ACDOCA_PRCTR+':'+B.CEPCT_MCTXT ),'_')
        FROM B04_08_TT_FIN_GL_CREDIT B
        WHERE 
			(
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS  
				AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
				AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
            )
        GROUP BY B.ACDOCA_RACCT, B.ACDOCA_PRCTR,B.CEPCT_MCTXT
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)'),1,1,''),'_') , '__', '_') ZF_CREDIT_ACDOCA_PRCTR_AND_DESC
-- Create a list of Credit account AP clearing flag
     , REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.ZF_ACC_IS_AP_CLEARING ,'' ),'_')
        FROM B04_08_TT_FIN_GL_CREDIT B
        WHERE 
			(
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS  
				AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
				AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
            )
        GROUP BY B.ACDOCA_RACCT, B.ZF_ACC_IS_AP_CLEARING
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_CREDIT_ACCT_IS_AP_CLEARING
-- Create a list of Credit account AR clearing flag
		,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.ZF_ACC_IS_AR_CLEARING ,'' ),'_')
		FROM B04_08_TT_FIN_GL_CREDIT B
		WHERE 
			(
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS  
				AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
				AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
			)
		GROUP BY B.ACDOCA_RACCT, B.ZF_ACC_IS_AR_CLEARING
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
		FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
		,1,1,''),'_') , '__', '_') ZF_CREDIT_ACCT_IS_AR_CLEARING
--Create a list of Credit account types ZF_ACDOCA_KOART_DESC
        ,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.ACDOCA_KOART+':'+B.ZF_ACDOCA_KOART_DESC)=1 ,'' ,B.ACDOCA_KOART+':'+B.ZF_ACDOCA_KOART_DESC ),'_')
        FROM B04_08_TT_FIN_GL_CREDIT B
        WHERE (B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
            )
        GROUP BY B.ACDOCA_RACCT, B.ACDOCA_KOART, ZF_ACDOCA_KOART_DESC
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_CREDIT_ACCOUNT_TYPES 
		
 --Create a list of Credit account numbers + descriptions
		,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.ACDOCA_RACCT+':'+B.SKAT_TXT20)=1,'_', B.ACDOCA_RACCT+':'+B.SKAT_TXT20 ),'_')
		FROM B04_08_TT_FIN_GL_CREDIT B
		WHERE 
			(
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS  
				AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
				AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR 
			)
		GROUP BY B.ACDOCA_RACCT,B.SKAT_TXT20
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
		FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
		,1,1,''),'_') , '__', '_') ZF_CREDIT_ACCOUNTS_DESC_COMBINE
--Create a list of Credit account numbers
        ,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.ACDOCA_RACCT ,'' ),'_')
        FROM B04_08_TT_FIN_GL_CREDIT B
        WHERE (B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
           )
        GROUP BY B.ACDOCA_RACCT
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_CREDIT_ACCOUNTS

--Add list of Credit account text
        ,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.SKAT_TXT20 ,'' ),'_')
        FROM B04_08_TT_FIN_GL_CREDIT B
        WHERE (B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS
                    AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
                    AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
                    )
        GROUP BY B.ACDOCA_RACCT, B.SKAT_TXT20
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_CREDIT_ACCOUNT_TEXTS

--Create a list of Credit documents of bank account found in A_T012K, A_FEBKO and SKB1
		,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG ,'' ),'_')
        FROM B04_08_TT_FIN_GL_CREDIT B
        WHERE (
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
            )
        GROUP BY B.ACDOCA_RACCT, B.ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_CREDIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST
--Create a list indicator of SKA1_GVTYP for Credit documents
		,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF(IIF(LEN(B.SKA1_GVTYP) > 0, 'Y',''),'' ),'_')
        FROM B04_08_TT_FIN_GL_CREDIT B
        WHERE (
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
          )
        GROUP BY B.ACDOCA_RACCT, B.SKA1_GVTYP
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_CREDIT_SKA1_GVTYP_FLAG_LIST
--Credit material group
		,REPLACE(ISNULL(STUFF((SELECT '_'+ COALESCE(IIF(LEN( B.MARA_MATKL+':'+B.T023T_WGBEZ)=1 ,'' ,B.MARA_MATKL+':'+B.T023T_WGBEZ ),'_')
        FROM B04_08_TT_FIN_GL_CREDIT B
        WHERE (
			B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
           )
        GROUP BY B.ACDOCA_RACCT, B.MARA_MATKL, T023T_WGBEZ
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_ACDOCA_MATNR_MARA_MATKL_CREDIT_LIST
--Credit asset
		,REPLACE(ISNULL(STUFF((SELECT '_'  + COALESCE(IIF(LEN( B.ACDOCA_ANLN1+ ':' + B.ACDOCA_ANLN2+':'+ B.ANLT_TXT50)= 2,'_', B.ACDOCA_ANLN1+ ':' + B.ACDOCA_ANLN2+':'+ B.ANLT_TXT50 ),'_')
        FROM B04_08_TT_FIN_GL_CREDIT B
        WHERE 
			(
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
            )
        GROUP BY B.ACDOCA_RACCT, B.ACDOCA_ANLN1,B.ACDOCA_ANLN2, ANLT_TXT50
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC,  B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_ACDOCA_ANLN1_ANLN2_CREDIT_LIST
--Credit found CSKB flag
		,REPLACE(ISNULL(STUFF((SELECT '_'  + COALESCE(NULLIF( B.ZF_RACCT_FOUND_IN_CSKB ,'' ),'_')
        FROM B04_08_TT_FIN_GL_CREDIT B
        WHERE (
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
            )
        GROUP BY B.ACDOCA_RACCT, B.ZF_RACCT_FOUND_IN_CSKB
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_RACCT_FOUND_IN_CSKB_CREDIT
-- Add some field related to accounting dashboard.

		,MAX(T001_BUTXT) AS T001_BUTXT -- Company code name
		,MAX(ACDOCA_MONAT) AS ACDOCA_MONAT -- Fiscal period
		,MAX(ACDOCA_BLART) AS ACDOCA_BLART -- Document type
		,MAX(T003T_LTEXT) AS T003T_LTEXT -- Document type text
		,MAX(ACDOCA_BUDAT) AS ACDOCA_BUDAT -- Posting date
		,MAX(ACDOCA_BLDAT) AS ACDOCA_BLDAT -- Document date
		,MAX(ACDOCA_CPUDT) AS ACDOCA_CPUDT -- Input date
		,MAX(BKPF_TCODE) AS BKPF_TCODE  -- Transaction code
		,MAX(TSTCT_TTEXT) AS TSTCT_TTEXT -- Transaction code text
		,MAX(ACDOCA_AWTYP) AS ACDOCA_AWTYP -- 
		,MAX(ACDOCA_RHCUR) AS ACDOCA_RHCUR 
		,MAX(ACDOCA_USNAM) AS  ACDOCA_USNAM -- User name
		,MAX(V_USERNAME_NAME_TEXT) AS V_USERNAME_NAME_TEXT -- User text
		,MAX(ZF_ENTRY_TYPE) AS ZF_ENTRY_TYPE -- Entry type

-- Add account type detail (blank, P&L, non-bank) request from Claire
	,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.ZF_ACDOCA_KOART ,'' ),'_')
				FROM B04_08_TT_FIN_GL_CREDIT B
				WHERE (
								B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS
								AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
								AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
					   )
				GROUP BY B.ZF_ACDOCA_KOART, B.ACDOCA_RACCT 
				ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
				FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
			,1,1,''),'_') , '__', '_') ZF_CREDIT_ACDOCA_KOART_CUSTOM_LIST

-- Supplier number and name ACDOCA_LFA1_NAME1
	,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.ACDOCA_LIFNR+':'+B.ACDOCA_LFA1_NAME1)=1 ,'' ,B.ACDOCA_LIFNR+':'+B.ACDOCA_LFA1_NAME1 ),'_')
		FROM B04_08_TT_FIN_GL_CREDIT B
		WHERE (
					B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS
					AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
					AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
			)
		GROUP BY B.ACDOCA_LIFNR, B.ACDOCA_RACCT , ACDOCA_LFA1_NAME1
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
		FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
	,1,1,''),'_') , '__', '_') ZF_CREDIT_ACDOCA_LIFNR_LIST
-- Supplier group and text
				,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.LFA1_KTOKK+':'+B.T077Y_TXT30)=1 ,'' ,B.LFA1_KTOKK+':'+B.T077Y_TXT30 ),'_')
				   FROM B04_08_TT_FIN_GL_CREDIT B
				   WHERE (
							B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS
							AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
							AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
						)
				   GROUP BY B.LFA1_KTOKK,B.ACDOCA_RACCT, T077Y_TXT30
				   ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
				   FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
				,1,1,''),'_') , '__', '_') ZF_CREDIT_LFA1_KTOKK_LIST
-- Customer number and text
		,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.ACDOCA_KUNNR+':'+B.ACDOCA_KNA1_NAME1)=1 ,'' ,B.ACDOCA_KUNNR+':'+B.ACDOCA_KNA1_NAME1 ),'_')
			FROM B04_08_TT_FIN_GL_CREDIT B
			WHERE (B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS
							AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
							AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
							)
			GROUP BY B.ACDOCA_KUNNR,B.ACDOCA_RACCT, ACDOCA_KNA1_NAME1
			ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
			FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
		,1,1,''),'_') , '__', '_') ZF_CREDIT_ACDOCA_KUNNR_LIST
-- Customer group number
			,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.KNA1_KTOKD+':'+B.T077X_TXT30)=1 ,'' ,B.KNA1_KTOKD+':'+B.T077X_TXT30 ),'_')
			   FROM B04_08_TT_FIN_GL_CREDIT B
			   WHERE (
							B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS
							 AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
							 AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
					)
			   GROUP BY B.KNA1_KTOKD,B.ACDOCA_RACCT , T077X_TXT30
			   ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
			   FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
			,1,1,''),'_') , '__', '_') ZF_CREDIT_KNA1_KTOKD_LIST
	
-- Tango account
			,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.TANGO_ACCT ,'' ),'_')
			   FROM B04_08_TT_FIN_GL_CREDIT B
			   WHERE (
						B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS
						 AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
						 AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR
					)
			   GROUP BY B.TANGO_ACCT,B.ACDOCA_RACCT 
			   ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
			   FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
			,1,1,''),'_') , '__', '_') ZF_CREDIT_TANGO_ACCT_LIST,
			SUM(ZF_ACDOCA_HSL_CR) AS  ZF_CREDIT_ACDOCA_HSL_S,  
			SUM(ZF_ACDOCA_HSL_CR_CUC) AS  ZF_CREDIT_ACDOCA_HSL_S_CUC 		
		INTO B04_08_TT_ACCOUNTING_CREDIT
        FROM B04_08_TT_FIN_GL_CREDIT
        GROUP BY
        B04_08_TT_FIN_GL_CREDIT.ACDOCA_RBUKRS
        ,B04_08_TT_FIN_GL_CREDIT.ACDOCA_GJAHR
        ,B04_08_TT_FIN_GL_CREDIT.ACDOCA_BELNR

EXEC SP_DROPTABLE    'B04_08_TT_FIN_GL_CREDIT' -- Remove table after finished to save the time

-- Step 7.2 / Split into debit table to reduce run time 
-- Step 7.1.1 / Create GL debit table

EXEC SP_DROPTABLE 'B04_08_TT_FIN_GL_DEBIT'
SELECT * INTO B04_08_TT_FIN_GL_DEBIT
FROM B04_08_IT_FIN_GL
WHERE ACDOCA_DRCRK = 'S'

-- Step 7.1.2 Create index 

 
CREATE INDEX ZF_ACDOCA_RCNTR_AND_DESC_INDEX ON B04_08_TT_FIN_GL_DEBIT(ACDOCA_RCNTR, ZF_CSKT_MCTXT)
CREATE INDEX ZF_ACDOCA_PRCTR_AND_DESC_INDEX ON B04_08_TT_FIN_GL_DEBIT(ACDOCA_PRCTR, CEPCT_MCTXT)
CREATE INDEX ZF_ACC_IS_AP_CLEARING_INDEX ON B04_08_TT_FIN_GL_DEBIT(ZF_ACC_IS_AP_CLEARING)
CREATE INDEX ZF_ACC_IS_AR_CLEARING_INDEX ON B04_08_TT_FIN_GL_DEBIT(ZF_ACC_IS_AR_CLEARING)
CREATE INDEX ZF_ACDOCA_KOART_INDEX ON B04_08_TT_FIN_GL_DEBIT(ACDOCA_KOART, ZF_ACDOCA_KOART_DESC )
CREATE INDEX ZF_ACCOUNTS_DESC_COMBINE_INDEX ON B04_08_TT_FIN_GL_DEBIT(ACDOCA_RACCT, SKAT_TXT20)
CREATE INDEX ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_INDEX ON B04_08_TT_FIN_GL_DEBIT(ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG)
CREATE INDEX ZF_SKA1_GVTYP_INDEX ON B04_08_TT_FIN_GL_DEBIT(SKA1_GVTYP)
CREATE INDEX ZF_MARA_MATKL_INDEX ON B04_08_TT_FIN_GL_DEBIT(MARA_MATKL,T023T_WGBEZ)
CREATE INDEX ZF_ANLN1_ANLN2_DEBIT_LIST_INDEX ON B04_08_TT_FIN_GL_DEBIT(ACDOCA_ANLN1,ACDOCA_ANLN2, ANLT_TXT50 )
CREATE INDEX ZF_RACCT_FOUND_IN_CSKB_INDEX ON B04_08_TT_FIN_GL_DEBIT(ZF_RACCT_FOUND_IN_CSKB)
CREATE INDEX ZF_ZF_ACDOCA_KOART1_INDEX ON B04_08_TT_FIN_GL_DEBIT(ZF_ACDOCA_KOART)
CREATE INDEX ZF_ACDOCA_LFA1_KTOKK_INDEX ON B04_08_TT_FIN_GL_DEBIT(LFA1_KTOKK, T077Y_TXT30)
CREATE INDEX ZF_ACDOCA_KUNNR_INDEX ON B04_08_TT_FIN_GL_DEBIT(ACDOCA_KUNNR,ACDOCA_KNA1_NAME1)
CREATE INDEX ZF_ACDOCA_KNA1_KTOKD_INDEX ON B04_08_TT_FIN_GL_DEBIT(KNA1_KTOKD,T077X_TXT30)
CREATE INDEX ZF_ACDOCA_TANGO_ACCT_INDEX ON B04_08_TT_FIN_GL_DEBIT(TANGO_ACCT)
CREATE INDEX ZF_ACDOCA_RACCT_INDEX ON B04_08_TT_FIN_GL_DEBIT(ACDOCA_RACCT)
CREATE INDEX ZF_SKAT_TXT20_INDEX ON B04_08_TT_FIN_GL_DEBIT(SKAT_TXT20)
CREATE INDEX ZF_RBUKRS_GJAHR_BELNR_INDEX ON B04_08_TT_FIN_GL_DEBIT(ACDOCA_RBUKRS, ACDOCA_GJAHR, ACDOCA_BELNR)


-- Step 7.2.3 / Run accounting for GL detail table

EXEC SP_DROPTABLE    'B04_08_TT_ACCOUNTING_DEBIT'

 SELECT
     B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS -- Company code
    ,B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR -- Fiscal year
    ,B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR, -- Documnent number
-- Create a list of Cost center debit
    REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.ACDOCA_RCNTR+':'+B.ZF_CSKT_MCTXT)=1,'_', B.ACDOCA_RCNTR+':'+B.ZF_CSKT_MCTXT),'_')
    FROM B04_08_TT_FIN_GL_DEBIT B
    WHERE 
		(
			B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
		)
    GROUP BY B.ACDOCA_RACCT, B.ACDOCA_RCNTR,B.ZF_CSKT_MCTXT
	ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)'),1,1,''),'_') , '__', '_') ZF_DEBIT_ACDOCA_RCNTR_AND_DESC
-- Create a list of profit center debit
    ,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.ACDOCA_PRCTR+':'+B.CEPCT_MCTXT)=1 ,'' ,B.ACDOCA_PRCTR+':'+B.CEPCT_MCTXT ),'_')
        FROM B04_08_TT_FIN_GL_DEBIT B
        WHERE 
			(
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS  
				AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
				AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
            )
        GROUP BY B.ACDOCA_RACCT, B.ACDOCA_PRCTR,B.CEPCT_MCTXT
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)'),1,1,''),'_') , '__', '_') ZF_DEBIT_ACDOCA_PRCTR_AND_DESC
-- Create a list of Debit account AP clearing flag
     , REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.ZF_ACC_IS_AP_CLEARING ,'' ),'_')
        FROM B04_08_TT_FIN_GL_DEBIT B
        WHERE 
			(
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS  
				AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
				AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
            )
        GROUP BY B.ACDOCA_RACCT, B.ZF_ACC_IS_AP_CLEARING
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_DEBIT_ACCT_IS_AP_CLEARING
-- Create a list of Debit account AR clearing flag
		,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.ZF_ACC_IS_AR_CLEARING ,'' ),'_')
		FROM B04_08_TT_FIN_GL_DEBIT B
		WHERE 
			(
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS  
				AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
				AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
			)
		GROUP BY B.ACDOCA_RACCT, B.ZF_ACC_IS_AR_CLEARING
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
		FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
		,1,1,''),'_') , '__', '_') ZF_DEBIT_ACCT_IS_AR_CLEARING
--Create a list of debit account types ZF_ACDOCA_KOART_DESC
        ,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.ACDOCA_KOART+':'+B.ZF_ACDOCA_KOART_DESC)=1 ,'' ,B.ACDOCA_KOART+':'+B.ZF_ACDOCA_KOART_DESC ),'_')
        FROM B04_08_TT_FIN_GL_DEBIT B
        WHERE (B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
            )
        GROUP BY B.ACDOCA_RACCT, B.ACDOCA_KOART, ZF_ACDOCA_KOART_DESC
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_DEBIT_ACCOUNT_TYPES 
		
 --Create a list of debit account numbers + descriptions
		,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.ACDOCA_RACCT+':'+B.SKAT_TXT20)=1,'_', B.ACDOCA_RACCT+':'+B.SKAT_TXT20 ),'_')
		FROM B04_08_TT_FIN_GL_DEBIT B
		WHERE 
			(
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS  
				AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
				AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR 
			)
		GROUP BY B.ACDOCA_RACCT,B.SKAT_TXT20
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
		FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
				,1,1,''),'_') , '__', '_') ZF_DEBIT_ACCOUNTS_DESC_COMBINE
--Create a list of debit account numbers
        ,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.ACDOCA_RACCT ,'' ),'_')
        FROM B04_08_TT_FIN_GL_DEBIT B
        WHERE (B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
           )
        GROUP BY B.ACDOCA_RACCT
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_DEBIT_ACCOUNTS

--Add list of debit account text
        ,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.SKAT_TXT20 ,'' ),'_')
        FROM B04_08_TT_FIN_GL_DEBIT B
        WHERE (B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS
                    AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
                    AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
                   )
        GROUP BY B.ACDOCA_RACCT, B.SKAT_TXT20
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_DEBIT_ACCOUNT_TEXTS

--Create a list of debit documents of bank account found in A_T012K, A_FEBKO and SKB1
		,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG ,'' ),'_')
        FROM B04_08_TT_FIN_GL_DEBIT B
        WHERE (
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
            )
        GROUP BY B.ACDOCA_RACCT, B.ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_DEBIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST
--Create a list indicator of SKA1_GVTYP for debit documents
		,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF(IIF(LEN(B.SKA1_GVTYP) > 0, 'Y',''),'' ),'_')
        FROM B04_08_TT_FIN_GL_DEBIT B
        WHERE (
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
          )
        GROUP BY B.ACDOCA_RACCT, B.SKA1_GVTYP
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_DEBIT_SKA1_GVTYP_FLAG_LIST
--Debit material group
		,REPLACE(ISNULL(STUFF((SELECT '_'+ COALESCE(IIF(LEN( B.MARA_MATKL+':'+B.T023T_WGBEZ)=1 ,'' ,B.MARA_MATKL+':'+B.T023T_WGBEZ ),'_')
        FROM B04_08_TT_FIN_GL_DEBIT B
        WHERE (
			B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
           )
        GROUP BY B.ACDOCA_RACCT, B.MARA_MATKL, T023T_WGBEZ
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_ACDOCA_MATNR_MARA_MATKL_DEBIT_LIST
--Debit asset
		,REPLACE(ISNULL(STUFF((SELECT '_'  + COALESCE(IIF(LEN( B.ACDOCA_ANLN1+ ':' + B.ACDOCA_ANLN2+':'+ B.ANLT_TXT50)= 2,'_', B.ACDOCA_ANLN1+ ':' + B.ACDOCA_ANLN2+':'+ B.ANLT_TXT50 ),'_')
        FROM B04_08_TT_FIN_GL_DEBIT B
        WHERE 
			(
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
            )
        GROUP BY B.ACDOCA_RACCT, B.ACDOCA_ANLN1,B.ACDOCA_ANLN2, ANLT_TXT50
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC,  B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_ACDOCA_ANLN1_ANLN2_DEBIT_LIST
--Debit found CSKB flag
		,REPLACE(ISNULL(STUFF((SELECT '_'  + COALESCE(NULLIF( B.ZF_RACCT_FOUND_IN_CSKB ,'' ),'_')
        FROM B04_08_TT_FIN_GL_DEBIT B
        WHERE (
				B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS  
            AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
            AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
            )
        GROUP BY B.ACDOCA_RACCT, B.ZF_RACCT_FOUND_IN_CSKB
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''),'_') , '__', '_') ZF_RACCT_FOUND_IN_CSKB_DEBIT
-- Add some field related to accounting dashboard.

		,MAX(T001_BUTXT) AS T001_BUTXT -- Company code name
		,MAX(ACDOCA_MONAT) AS ACDOCA_MONAT -- Fiscal period
		,MAX(ACDOCA_BLART) AS ACDOCA_BLART -- Document type
		,MAX(T003T_LTEXT) AS T003T_LTEXT -- Document type text
		,MAX(ACDOCA_BUDAT) AS ACDOCA_BUDAT -- Posting date
		,MAX(ACDOCA_BLDAT) AS ACDOCA_BLDAT -- Document date
		,MAX(ACDOCA_CPUDT) AS ACDOCA_CPUDT -- Input date
		,MAX(BKPF_TCODE) AS BKPF_TCODE  -- Transaction code
		,MAX(TSTCT_TTEXT) AS TSTCT_TTEXT -- Transaction code text
		,MAX(ACDOCA_AWTYP) AS ACDOCA_AWTYP -- 
		,MAX(ACDOCA_RHCUR) AS ACDOCA_RHCUR 
		,MAX(ACDOCA_USNAM) AS  ACDOCA_USNAM -- User name
		,MAX(V_USERNAME_NAME_TEXT) AS V_USERNAME_NAME_TEXT -- User text
		,MAX(ZF_ENTRY_TYPE) AS ZF_ENTRY_TYPE -- Entry type

-- Add account type detail (blank, P&L, non-bank) request from Claire
	,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.ZF_ACDOCA_KOART ,'' ),'_')
				FROM B04_08_TT_FIN_GL_DEBIT B
				WHERE (
								B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS
								AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
								AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
					   )
				GROUP BY B.ZF_ACDOCA_KOART, B.ACDOCA_RACCT 
				ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
				FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
			,1,1,''),'_') , '__', '_') ZF_DEBIT_ACDOCA_KOART_CUSTOM_LIST

-- Supplier number and name ACDOCA_LFA1_NAME1
	,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.ACDOCA_LIFNR+':'+B.ACDOCA_LFA1_NAME1)=1 ,'' ,B.ACDOCA_LIFNR+':'+B.ACDOCA_LFA1_NAME1 ),'_')
		FROM B04_08_TT_FIN_GL_DEBIT B
		WHERE (
					B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS
					AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
					AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
			)
		GROUP BY B.ACDOCA_LIFNR, B.ACDOCA_RACCT , ACDOCA_LFA1_NAME1
		ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
		FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
	,1,1,''),'_') , '__', '_') ZF_DEBIT_ACDOCA_LIFNR_LIST
-- Supplier group and text
				,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.LFA1_KTOKK+':'+B.T077Y_TXT30)=1 ,'' ,B.LFA1_KTOKK+':'+B.T077Y_TXT30 ),'_')
				   FROM B04_08_TT_FIN_GL_DEBIT B
				   WHERE (
							B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS
							AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
							AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
						)
				   GROUP BY B.LFA1_KTOKK,B.ACDOCA_RACCT, T077Y_TXT30
				   ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
				   FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
				,1,1,''),'_') , '__', '_') ZF_DEBIT_LFA1_KTOKK_LIST
-- Customer number and text
		,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.ACDOCA_KUNNR+':'+B.ACDOCA_KNA1_NAME1)=1 ,'' ,B.ACDOCA_KUNNR+':'+B.ACDOCA_KNA1_NAME1 ),'_')
			FROM B04_08_TT_FIN_GL_DEBIT B
			WHERE (B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS
							AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
							AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
							)
			GROUP BY B.ACDOCA_KUNNR,B.ACDOCA_RACCT, ACDOCA_KNA1_NAME1
			ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
			FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
		,1,1,''),'_') , '__', '_') ZF_DEBIT_ACDOCA_KUNNR_LIST
-- Customer group number
			,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.KNA1_KTOKD+':'+B.T077X_TXT30)=1 ,'' ,B.KNA1_KTOKD+':'+B.T077X_TXT30 ),'_')
			   FROM B04_08_TT_FIN_GL_DEBIT B
			   WHERE (
							B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS
							 AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
							 AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
					)
			   GROUP BY B.KNA1_KTOKD,B.ACDOCA_RACCT , T077X_TXT30
			   ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
			   FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
			,1,1,''),'_') , '__', '_') ZF_DEBIT_KNA1_KTOKD_LIST
	
-- Tango account
			,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.TANGO_ACCT ,'' ),'_')
			   FROM B04_08_TT_FIN_GL_DEBIT B
			   WHERE (
						B.ACDOCA_RBUKRS = B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS
						 AND B.ACDOCA_GJAHR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
						 AND B.ACDOCA_BELNR = B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR
					)
			   GROUP BY B.TANGO_ACCT,B.ACDOCA_RACCT 
			   ORDER BY SUM(ABS(B.ZF_ACDOCA_HSL_S)) DESC, B.ACDOCA_RACCT
			   FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
			,1,1,''),'_') , '__', '_') ZF_DEBIT_TANGO_ACCT_LIST,
			SUM(ZF_ACDOCA_HSL_DB) AS ZF_DEBIT_ACDOCA_HSL_S, 
			SUM(ZF_ACDOCA_HSL_DB_CUC) AS ZF_DEBIT_ACDOCA_HSL_S_CUC	
		INTO B04_08_TT_ACCOUNTING_DEBIT
        FROM B04_08_TT_FIN_GL_DEBIT
        GROUP BY
        B04_08_TT_FIN_GL_DEBIT.ACDOCA_RBUKRS
        ,B04_08_TT_FIN_GL_DEBIT.ACDOCA_GJAHR
        ,B04_08_TT_FIN_GL_DEBIT.ACDOCA_BELNR

EXEC SP_DROPTABLE 'B04_08_TT_FIN_GL_DEBIT'

-- Step 7.3 Combine debit and credit 

EXEC SP_DROPTABLE    'B04_09_IT_ACDOCA_BKPF_ACC_SCH'

SELECT 
	A.*, 
	B.ZF_DEBIT_ACDOCA_RCNTR_AND_DESC
	,B.ZF_DEBIT_ACDOCA_PRCTR_AND_DESC
	,B.ZF_DEBIT_ACCT_IS_AP_CLEARING
	,B.ZF_DEBIT_ACCT_IS_AR_CLEARING
	,B.ZF_DEBIT_ACCOUNT_TYPES
	,B.ZF_DEBIT_ACCOUNTS_DESC_COMBINE
	,B.ZF_DEBIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST
	,B.ZF_DEBIT_SKA1_GVTYP_FLAG_LIST
	,B.ZF_ACDOCA_MATNR_MARA_MATKL_DEBIT_LIST
	,B.ZF_ACDOCA_ANLN1_ANLN2_DEBIT_LIST
	,B.ZF_RACCT_FOUND_IN_CSKB_DEBIT
	,B.ZF_DEBIT_ACDOCA_KOART_CUSTOM_LIST
	,B.ZF_DEBIT_ACDOCA_LIFNR_LIST
	,B.ZF_DEBIT_LFA1_KTOKK_LIST
	,B.ZF_DEBIT_ACDOCA_KUNNR_LIST
	,B.ZF_DEBIT_KNA1_KTOKD_LIST
	,B.ZF_DEBIT_TANGO_ACCT_LIST
	,B.ZF_DEBIT_ACDOCA_HSL_S
	,B.ZF_DEBIT_ACDOCA_HSL_S_CUC
	,B.ZF_DEBIT_ACCOUNTS
	,B.ZF_DEBIT_ACCOUNT_TEXTS
INTO B04_09_IT_ACDOCA_BKPF_ACC_SCH
FROM B04_08_TT_ACCOUNTING_CREDIT  A
INNER JOIN 
	B04_08_TT_ACCOUNTING_DEBIT B ON A.ACDOCA_RBUKRS = B.ACDOCA_RBUKRS AND A.ACDOCA_GJAHR = B.ACDOCA_GJAHR AND A.ACDOCA_BELNR = B.ACDOCA_BELNR

-- Create index
CREATE INDEX ACDOCA_BKPF_ACC_SCH_IDX1 ON B04_09_IT_ACDOCA_BKPF_ACC_SCH(ACDOCA_RBUKRS, ACDOCA_GJAHR, ACDOCA_BELNR)



 
-- Step 8/ Create a list to which accounting schemes can be added
 
EXEC sp_droptable 'B04_10_TT_AP_DOCUMENT'

       SELECT
            ACDOCA_RCLNT
            ,ACDOCA_RBUKRS
            ,ACDOCA_GJAHR
            ,ACDOCA_AWREF
			,ACDOCA_AWTYP
			,ACDOCA_BELNR
            ,ACDOCA_BUZEI
			,ACDOCA_DOCLN
            ,ACDOCA_BSCHL
            ,ACDOCA_DRCRK       
            ,ACDOCA_BLART
			,BKPF_XBLNR
			,BKPF_TCODE
			,ACDOCA_LIFNR
            ,ACDOCA_RWCUR
			,ACDOCA_RHCUR
			,ACDOCA_RKCUR
			,ACDOCA_ROCUR
            ,ACDOCA_HSL
			,ACDOCA_KSL
			,ACDOCA_OSL
			,ACDOCA_UMSKZ
			,ACDOCA_AUGDT
			,ACDOCA_AUGBL
			,ACDOCA_ZUONR
 			,ACDOCA_BUDAT
			,ACDOCA_BLDAT
			,LEFT(ACDOCA_TIMESTAMP, 8) ACDOCA_CPUDT                                                          
			,RIGHT(ACDOCA_TIMESTAMP,6) ACDOCA_CPUTM
			,CONCAT(SUBSTRING('00',1, 2 - LEN(ACDOCA_POPER % 16)),CAST((ACDOCA_POPER % 16) AS NVARCHAR)) AS ACDOCA_MONAT
			,ACDOCA_RBUSA
			,ACDOCA_KOKRS
			,ACDOCA_USNAM
			,ACDOCA_WSL
			,ACDOCA_MWSKZ
			,ACDOCA_SGTXT
			,ACDOCA_AUFNR
			,ACDOCA_EBELN
			,ACDOCA_EBELP
			,ACDOCA_RACCT
			,ACDOCA_BSTAT
			,ACDOCA_PS_POSID
			,ACDOCA_RCNTR
			,ACDOCA_PRCTR
			,ACDOCA_AUGGJ
			,ACDOCA_MATNR
			-- Nam: Add net due date
			,ACDOCA_NETDT
			,DATEDIFF(d,LEFT(ACDOCA_TIMESTAMP, 8),ACDOCA_AUGDT) AS ZF_ACDOCA_CPUDT_AGE_DAYS
			,CASE 
				WHEN ACDOCA_AUGBL = '' THEN 'Open'
				ELSE 'Closed'
			END ZF_ACDOCA_OPEN_CLOSED
			-- Add description of debit/credit indicator
			, CASE 
				WHEN ACDOCA_DRCRK='H' THEN 'Credit' 
				ELSE 'Debit' 
			  END AS ZF_ACDOCA_DRCRK_DESC 		
			  -- Add integer value for debit/credit indicator
			, CASE 
				WHEN ACDOCA_DRCRK='H' THEN -1 
				ELSE 1 END 
			  AS ZF_ACDOCA_DRCRK_INTEGER
			  -- Add matching year-month
			,CAST(YEAR(ACDOCA_AUGDT) AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(MONTH(ACDOCA_AUGDT) AS VARCHAR(2)),2) AS ZF_ACDOCA_AUGDT_YEAR_MNTH
 
       INTO B04_10_TT_AP_DOCUMENT
       FROM B00_ACDOCA
	   LEFT JOIN A_BKPF
	   ON	B00_ACDOCA.ACDOCA_RBUKRS = A_BKPF.BKPF_BUKRS
			AND B00_ACDOCA.ACDOCA_GJAHR = A_BKPF.BKPF_GJAHR
			AND B00_ACDOCA.ACDOCA_BELNR = A_BKPF.BKPF_BELNR
	   WHERE ACDOCA_KOART = 'K' AND ACDOCA_BSTAT = '' AND ACDOCA_BUZEI <> '000'
	   AND ACDOCA_UMSKZ = ''
 
	
-- Step 9/ Add the supplier account group and the document type description
--         Add value fields so that we can see the total value per account type
--         Add the accounting schmes
 
 
EXEC SP_DROPTABLE    'B04_11_IT_AP_ACC_SCH'
 
       SELECT B04_10_TT_AP_DOCUMENT.*
	   -- Local currency code
       ,A_T001.T001_WAERS
	   -- Signed amount - values are inversed so that total spend shows as positive on the dashboard
       ,CONVERT(MONEY,ACDOCA_HSL * COALESCE(TCURX_CC.TCURX_FACTOR,1)) AS ZF_ACDOCA_HSL_S
       ,CONVERT(MONEY,B04_10_TT_AP_DOCUMENT.ACDOCA_KSL * COALESCE(TCURX_KSL.TCURX_FACTOR,1) )  AS ZF_ACDOCA_KSL_S
       ,CONVERT(MONEY,B04_10_TT_AP_DOCUMENT.ACDOCA_OSL * COALESCE(TCURX_OSL.TCURX_FACTOR,1) )  AS ZF_ACDOCA_OSL_S
	   -- Custom currency code
       ,@currency      AS GLOBALS_CURRENCY
	   -- Signed amount in custom currency - values are inversed so that total spend shows as positive on the dashboard                                                                                                                                                                                AS AM_GLOBALS_CURRENCY
       ,CONVERT(MONEY,B04_10_TT_AP_DOCUMENT.ACDOCA_KSL * COALESCE(TCURX_KSL.TCURX_FACTOR,1) ) AS ZF_ACDOCA_HSL_S_CUC
	   --Supplier account group
       ,A_LFA1.LFA1_KTOKK
	   ,A_LFA1.LFA1_NAME1
	   ,A_LFA1.LFA1_KUNNR
	   --Supplier account group description
       ,B00_T077Y.T077Y_TXT30
	   -- Document type description
       ,B00_T003T.T003T_LTEXT
	   --Posting key description
	   ,B00_TBSLT.TBSLT_LTEXT
	   --Transaction code description
	   ,A_TSTCT.TSTCT_TTEXT
	   ,IIF(B04_10_TT_AP_DOCUMENT.ACDOCA_AUGBL = B04_10_TT_AP_DOCUMENT.ACDOCA_BELNR, 'Y', '') ZF_DOC_CLEARING_FLAG
	   --Accounting schemes:
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_DEBIT_ACCOUNT_TYPES, '_') ZF_DEBIT_ACCOUNT_TYPES
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_CREDIT_ACCOUNT_TYPES, '_') ZF_CREDIT_ACCOUNT_TYPES
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_DEBIT_ACCOUNTS, '_') ZF_DEBIT_ACCOUNTS
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_CREDIT_ACCOUNTS, '_') ZF_CREDIT_ACCOUNTS
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_DEBIT_ACCOUNT_TEXTS, '_') ZF_DEBIT_ACCOUNT_TEXTS
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_CREDIT_ACCOUNT_TEXTS, '_') ZF_CREDIT_ACCOUNT_TEXTS
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_DEBIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST, '_') ZF_DEBIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_CREDIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST, '_') ZF_CREDIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_DEBIT_SKA1_GVTYP_FLAG_LIST, '_') ZF_DEBIT_SKA1_GVTYP_FLAG_LIST
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_CREDIT_SKA1_GVTYP_FLAG_LIST, '_') ZF_CREDIT_SKA1_GVTYP_FLAG_LIST
--AR/AP clearing
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_DEBIT_ACCT_IS_AP_CLEARING, '_') ZF_DEBIT_ACCT_IS_AP_CLEARING
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_CREDIT_ACCT_IS_AP_CLEARING, '_') ZF_CREDIT_ACCT_IS_AP_CLEARING
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_DEBIT_ACCT_IS_AR_CLEARING, '_') ZF_DEBIT_ACCT_IS_AR_CLEARING
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_CREDIT_ACCT_IS_AR_CLEARING, '_') ZF_CREDIT_ACCT_IS_AR_CLEARING
	   ,ISNULL((SELECT TOP 1 'X' FROM B00_00_TT_REGUH 
									WHERE B04_10_TT_AP_DOCUMENT.ACDOCA_LIFNR = REGUH_LIFNR
									AND REGUH_VBLNR = B04_10_TT_AP_DOCUMENT.ACDOCA_BELNR AND B04_10_TT_AP_DOCUMENT.ACDOCA_RBUKRS  = REGUH_ZBUKR), '') ZF_REGUH_PAYMENT_FLAG
		,ISNULL((SELECT TOP 1 'X' FROM B00_00B_TT_REGUP 
									WHERE B04_10_TT_AP_DOCUMENT.ACDOCA_RBUKRS = REGUP_BUKRS 
									AND B04_10_TT_AP_DOCUMENT.ACDOCA_GJAHR = REGUP_GJAHR 
									AND B04_10_TT_AP_DOCUMENT.ACDOCA_BELNR = REGUP_BELNR), '') ZF_REGUP_INVOICE_FLAG

        -- Cost center infromation needed in AP cube and based on B04_02_TT_CSKT_DATBI
		,COALESCE(CASE 
			WHEN B04_02_TT_CSKT_DATBI.CSKT_LTEXT ='' OR  B04_02_TT_CSKT_DATBI.CSKT_LTEXT IS NULL THEN 'Not assigned'
			ELSE ACDOCA_RCNTR 
		 END,'Not assigned') ZF_ACDOCA_DOC_RCNTR
		-- Cost center description
		,COALESCE(CASE 
			WHEN B04_02_TT_CSKT_DATBI.CSKT_LTEXT ='' OR  B04_02_TT_CSKT_DATBI.CSKT_LTEXT IS NULL THEN 'Not assigned'
			ELSE B04_02_TT_CSKT_DATBI.CSKT_LTEXT 
		 END,'Not assigned') ZF_ACDOCA_CSKT_LTEXT
		,CEPCT_MCTXT

       INTO B04_11_IT_AP_ACC_SCH

       FROM B04_10_TT_AP_DOCUMENT

	   -- Add supplier information
       LEFT JOIN A_LFA1
              ON B04_10_TT_AP_DOCUMENT.ACDOCA_LIFNR = A_LFA1.LFA1_LIFNR
	   -- Add supplier account group text
       LEFT JOIN B00_T077Y
              ON A_LFA1.LFA1_KTOKK = B00_T077Y.T077Y_KTOKK
	   -- Add document type description
       LEFT JOIN B00_T003T
           ON B04_10_TT_AP_DOCUMENT.ACDOCA_BLART = B00_T003T.T003T_BLART
       -- Obtain company description and house currency
       LEFT JOIN A_T001
              ON  B04_10_TT_AP_DOCUMENT.ACDOCA_RBUKRS = A_T001.T001_BUKRS
             
		-- Add currency conversion factor for document currency
		LEFT JOIN B00_TCURX TCURX_DOC 
				ON B04_10_TT_AP_DOCUMENT.ACDOCA_RWCUR = TCURX_DOC.TCURX_CURRKEY
             
		-- Add currency conversion factors for company currency
		LEFT JOIN B00_TCURX TCURX_CC     
				ON 	A_T001.T001_WAERS = TCURX_CC.TCURX_CURRKEY

        -- Add currency conversion factors for group currency
        LEFT JOIN B00_TCURX TCURX_KSL    
				ON 	B04_10_TT_AP_DOCUMENT.ACDOCA_RKCUR = TCURX_KSL.TCURX_CURRKEY

        -- Add currency conversion factors for third currency
        LEFT JOIN B00_TCURX TCURX_OSL
				ON 	B04_10_TT_AP_DOCUMENT.ACDOCA_ROCUR = TCURX_OSL.TCURX_CURRKEY 
 
		-- Add the accounting schemes
		LEFT JOIN B04_09_IT_ACDOCA_BKPF_ACC_SCH
		ON   B04_10_TT_AP_DOCUMENT.ACDOCA_RBUKRS = B04_09_IT_ACDOCA_BKPF_ACC_SCH.ACDOCA_RBUKRS AND
				B04_10_TT_AP_DOCUMENT.ACDOCA_GJAHR = B04_09_IT_ACDOCA_BKPF_ACC_SCH.ACDOCA_GJAHR AND
				B04_10_TT_AP_DOCUMENT.ACDOCA_BELNR = B04_09_IT_ACDOCA_BKPF_ACC_SCH.ACDOCA_BELNR

	    -- Add cost center information 
		LEFT JOIN B04_02_TT_CSKT_DATBI
			ON B04_10_TT_AP_DOCUMENT.ACDOCA_KOKRS = B04_02_TT_CSKT_DATBI.CSKT_KOKRS
			AND B04_10_TT_AP_DOCUMENT.ACDOCA_RCNTR = B04_02_TT_CSKT_DATBI.CSKT_KOSTL
			AND B04_02_TT_CSKT_DATBI.CSKT_DATBI > @downloaddate

		-- Include profit centers descriptions
		LEFT JOIN B04_04_TT_CEPCT_UNIQUE
		ON	B04_10_TT_AP_DOCUMENT.ACDOCA_KOKRS = B04_04_TT_CEPCT_UNIQUE.CEPCT_KOKRS AND
			B04_10_TT_AP_DOCUMENT.ACDOCA_PRCTR = B04_04_TT_CEPCT_UNIQUE.CEPCT_PRCTR

		-- Get posting key description
		LEFT JOIN B00_TBSLT
		ON	B04_10_TT_AP_DOCUMENT.ACDOCA_BSCHL = B00_TBSLT.TBSLT_BSCHL AND
			B04_10_TT_AP_DOCUMENT.ACDOCA_UMSKZ = B00_TBSLT.TBSLT_UMSKZ

		--Get transaction code description
		LEFT JOIN A_TSTCT
		ON	A_TSTCT.TSTCT_SPRSL IN ('E', 'EN') AND
			A_TSTCT.TSTCT_TCODE = B04_10_TT_AP_DOCUMENT.BKPF_TCODE
		
		/* 
			Add a columns to flag the AP documents can be find in the REGUH/REGUP table 
			Default value is N update to Y if the document can be find in the REGUP table
		*/
		ALTER TABLE B04_11_IT_AP_ACC_SCH ADD ZF_EXIST_IN_REGUP_FLAG NVARCHAR(1) DEFAULT 'N' WITH VALUES;
		UPDATE B04_11_IT_AP_ACC_SCH
		SET ZF_EXIST_IN_REGUP_FLAG = 'Y'
		WHERE EXISTS (
			SELECT TOP 1 1
			FROM A_REGUP 
			WHERE B04_11_IT_AP_ACC_SCH.ACDOCA_RBUKRS = A_REGUP.REGUP_BUKRS AND
				  B04_11_IT_AP_ACC_SCH.ACDOCA_GJAHR = A_REGUP.REGUP_GJAHR AND
				  B04_11_IT_AP_ACC_SCH.ACDOCA_BELNR = A_REGUP.REGUP_BELNR AND
				  B04_11_IT_AP_ACC_SCH.ACDOCA_BUZEI = A_REGUP.REGUP_BUZEI
		)

		/* 
			Add a columns to flag the AP documents which credit vendor and debit customer but the customer and vendor is the same person.
		*/
		EXEC SP_DROPTABLE 'B04_12B_TT_FIN_GL_CHECK_LIST'
		SELECT DISTINCT ACDOCA_RBUKRS,
						ACDOCA_GJAHR,
						ACDOCA_BELNR,
						ACDOCA_KUNNR
		INTO B04_12B_TT_FIN_GL_CHECK_LIST
		FROM B04_08_IT_FIN_GL
		WHERE ACDOCA_DRCRK = 'S' AND ACDOCA_KUNNR <> ''
        EXEC SP_CREATE_INDEX B04_12B_TT_FIN_GL_CHECK_LIST, 'B04_12B_IT_FIN_GL_CHECK_LIST_INDEX','ACDOCA_RBUKRS, ACDOCA_GJAHR, ACDOCA_BELNR, ACDOCA_KUNNR'

		ALTER TABLE B04_11_IT_AP_ACC_SCH ADD ZF_LIFNR_KUNNR_IS_SAME_FLAG NVARCHAR(1) DEFAULT 'N' WITH VALUES;
		UPDATE B04_11_IT_AP_ACC_SCH
		SET ZF_LIFNR_KUNNR_IS_SAME_FLAG = 'Y'
		WHERE EXISTS(
			SELECT *
			FROM B04_12B_TT_FIN_GL_CHECK_LIST
			WHERE B04_12B_TT_FIN_GL_CHECK_LIST.ACDOCA_RBUKRS = B04_11_IT_AP_ACC_SCH.ACDOCA_RBUKRS AND
			   B04_12B_TT_FIN_GL_CHECK_LIST.ACDOCA_GJAHR = B04_11_IT_AP_ACC_SCH.ACDOCA_GJAHR AND
			   B04_12B_TT_FIN_GL_CHECK_LIST.ACDOCA_BELNR = B04_11_IT_AP_ACC_SCH.ACDOCA_BELNR AND
			   B04_12B_TT_FIN_GL_CHECK_LIST.ACDOCA_KUNNR = B04_11_IT_AP_ACC_SCH.LFA1_KUNNR AND
			   B04_12B_TT_FIN_GL_CHECK_LIST.ACDOCA_KUNNR <> ''
		)
		AND B04_11_IT_AP_ACC_SCH.ACDOCA_DRCRK = 'H'

EXEC sp_droptable 'B04_12_TT_AR_DOCUMENT'
       SELECT
            ACDOCA_RCLNT
            ,ACDOCA_RBUKRS
            ,ACDOCA_GJAHR
            ,ACDOCA_AWREF
			,ACDOCA_AWTYP
			,ACDOCA_BELNR
            ,ACDOCA_BUZEI
			,ACDOCA_DOCLN
            ,ACDOCA_BSCHL
			,ACDOCA_PRCTR
			,ACDOCA_RCNTR
            ,ACDOCA_DRCRK       
            ,ACDOCA_BLART
			,BKPF_XBLNR
			,BKPF_TCODE
            ,ACDOCA_RWCUR
			,ACDOCA_RHCUR
			,ACDOCA_RKCUR
			,ACDOCA_ROCUR
            ,ACDOCA_HSL
			,ACDOCA_KSL
			,ACDOCA_OSL
			,ACDOCA_UMSKZ
			,ACDOCA_AUGDT
			,ACDOCA_AUGBL
			,ACDOCA_ZUONR
 			,ACDOCA_BUDAT
			,ACDOCA_BLDAT
			,LEFT(ACDOCA_TIMESTAMP, 8) ACDOCA_CPUDT                                                        
			,RIGHT(ACDOCA_TIMESTAMP,6) ACDOCA_CPUTM
			,CONCAT(SUBSTRING('00',1, 2 - LEN(ACDOCA_POPER % 16)),CAST((ACDOCA_POPER % 16) AS NVARCHAR)) AS ACDOCA_MONAT
			,ACDOCA_USNAM
			,ACDOCA_KOKRS
			,ACDOCA_RBUSA
			,ACDOCA_WSL
			,ACDOCA_MWSKZ
			,ACDOCA_SGTXT
			,ACDOCA_AUFNR
			,ACDOCA_RACCT
			,ACDOCA_KUNNR
			,ACDOCA_BSTAT
			,ACDOCA_PS_POSID
			,ACDOCA_AUGGJ
			,ACDOCA_REBZG
			,ACDOCA_MATNR
			,ACDOCA_NETDT -- Nam: add net due date from ACDOCA
			,DATEDIFF(D,LEFT(ACDOCA_TIMESTAMP, 8),ACDOCA_AUGDT) AS ZF_ACDOCA_CPUDT_AGE_DAYS
			,CASE
				WHEN ACDOCA_AUGBL = '' THEN 'Open'
				ELSE 'Closed'
			END AS ZF_ACDOCA_OPEN_CLOSED
			, CASE 
				WHEN ACDOCA_DRCRK ='H' THEN 'Credit' 
				ELSE 'Debit' 
			  END AS ZF_ACDOCA_DRCRK_DESC 		
			, CASE 
				WHEN ACDOCA_DRCRK='H' THEN -1 
				ELSE 1 END 
			  AS ZF_ACDOCA_DRCRK_INTEGER
			,CAST(YEAR(ACDOCA_AUGDT) AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(MONTH(ACDOCA_AUGDT) AS VARCHAR(2)),2) AS ZF_ACDOCA_AUGDT_YEAR_MNTH

			,NULL ZF_ACDOCA_AUGDT_CLR_PER_YR
       INTO B04_12_TT_AR_DOCUMENT
       FROM B00_ACDOCA
	   LEFT JOIN A_BKPF
	   ON B00_ACDOCA.ACDOCA_GJAHR = A_BKPF.BKPF_GJAHR
	   AND B00_ACDOCA.ACDOCA_RBUKRS = A_BKPF.BKPF_BUKRS
	   AND B00_ACDOCA.ACDOCA_BELNR = A_BKPF.BKPF_BELNR
	   WHERE ACDOCA_BSTAT = '' AND ACDOCA_BUZEI <> '000' AND ACDOCA_KOART = 'D'
	   AND ACDOCA_UMSKZ = ''
 
-- Step 10/ Add the supplier account group and the document type description
--         Add value fields so that we can see the total value per account type
--         Add the accounting schmes
 
 
EXEC SP_DROPTABLE    'B04_13_IT_AR_ACC_SCH'
 
       SELECT B04_12_TT_AR_DOCUMENT.*
	   -- Local currency code
       ,A_T001.T001_WAERS
	   -- Signed amount - values are inversed so that total spend shows as positive on the dashboard
       ,CONVERT(MONEY,B04_12_TT_AR_DOCUMENT.ACDOCA_HSL * COALESCE(TCURX_CC.TCURX_FACTOR,1) )  AS ZF_ACDOCA_HSL_S
       ,CONVERT(MONEY,B04_12_TT_AR_DOCUMENT.ACDOCA_KSL * COALESCE(TCURX_KSL.TCURX_FACTOR,1) )  AS ZF_ACDOCA_KSL_S
       ,CONVERT(MONEY,B04_12_TT_AR_DOCUMENT.ACDOCA_OSL * COALESCE(TCURX_OSL.TCURX_FACTOR,1) )  AS ZF_ACDOCA_OSL_S
	   -- Custom currency code
       ,@currency      AS GLOBALS_CURRENCY
	   -- Signed amount in custom currency - values are inversed so that total spend shows as positive on the dashboard                                                                                                                                                                                AS AM_GLOBALS_CURRENCY
       ,CONVERT(MONEY,B04_12_TT_AR_DOCUMENT.ACDOCA_KSL * COALESCE(TCURX_KSL.TCURX_FACTOR,1) )    AS ZF_ACDOCA_HSL_S_CUC
	   -- Document type description
       ,B00_T003T.T003T_LTEXT
	   --Posting key description
	   ,B00_TBSLT.TBSLT_LTEXT
	    --Transaction code description
	   ,A_TSTCT.TSTCT_TTEXT
	   ,IIF(B04_12_TT_AR_DOCUMENT.ACDOCA_AUGBL = B04_12_TT_AR_DOCUMENT.ACDOCA_BELNR, 'Y', '') ZF_DOC_CLEARING_FLAG
	   --Accounting schemes:
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_DEBIT_ACCOUNT_TYPES, '_') ZF_DEBIT_ACCOUNT_TYPES
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_CREDIT_ACCOUNT_TYPES, '_') ZF_CREDIT_ACCOUNT_TYPES
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_DEBIT_ACCOUNTS, '_') ZF_DEBIT_ACCOUNTS
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_CREDIT_ACCOUNTS, '_') ZF_CREDIT_ACCOUNTS
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_DEBIT_ACCOUNT_TEXTS, '_') ZF_DEBIT_ACCOUNT_TEXTS
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_CREDIT_ACCOUNT_TEXTS, '_') ZF_CREDIT_ACCOUNT_TEXTS
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_DEBIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST, '') ZF_DEBIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_CREDIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST, '') ZF_CREDIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_DEBIT_SKA1_GVTYP_FLAG_LIST, '_') ZF_DEBIT_SKA1_GVTYP_FLAG_LIST
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_CREDIT_SKA1_GVTYP_FLAG_LIST, '_') ZF_CREDIT_SKA1_GVTYP_FLAG_LIST
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_DEBIT_ACCT_IS_AP_CLEARING, '_') ZF_DEBIT_ACCT_IS_AP_CLEARING
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_CREDIT_ACCT_IS_AP_CLEARING, '_') ZF_CREDIT_ACCT_IS_AP_CLEARING
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_DEBIT_ACCT_IS_AR_CLEARING, '_') ZF_DEBIT_ACCT_IS_AR_CLEARING
	   ,ISNULL(B04_09_IT_ACDOCA_BKPF_ACC_SCH.ZF_CREDIT_ACCT_IS_AR_CLEARING, '_') ZF_CREDIT_ACCT_IS_AR_CLEARING
		,COALESCE(CASE 
			WHEN B04_02_TT_CSKT_DATBI.CSKT_LTEXT ='' OR  B04_02_TT_CSKT_DATBI.CSKT_LTEXT IS NULL THEN 'Not assigned'
			ELSE ACDOCA_RCNTR 
		 END,'Not assigned') ZF_ACDOCA_RCNTR
		,COALESCE(CASE 
			WHEN B04_02_TT_CSKT_DATBI.CSKT_LTEXT ='' OR  B04_02_TT_CSKT_DATBI.CSKT_LTEXT IS NULL THEN 'Not assigned'
			ELSE B04_02_TT_CSKT_DATBI.CSKT_LTEXT 
		 END,'Not assigned') ZF_CSKT_LTEXT,
		 CEPCT_MCTXT,
		 KNA1_NAME1,
		 KNA1_KTOKD,
		 KNA1_LIFNR,
		 T077X_TXT30
       INTO B04_13_IT_AR_ACC_SCH
       FROM B04_12_TT_AR_DOCUMENT
	   LEFT JOIN A_KNA1 
		   ON KNA1_KUNNR = B04_12_TT_AR_DOCUMENT.ACDOCA_KUNNR

	   LEFT JOIN B00_T077X
              ON A_KNA1.KNA1_KTOKD = B00_T077X.T077X_KTOKD

       LEFT JOIN B00_T003T
           ON B04_12_TT_AR_DOCUMENT.ACDOCA_BLART = B00_T003T.T003T_BLART

       LEFT JOIN A_T001
              ON  B04_12_TT_AR_DOCUMENT.ACDOCA_RBUKRS = A_T001.T001_BUKRS

		LEFT JOIN B00_TCURX TCURX_DOC 
				ON  B04_12_TT_AR_DOCUMENT.ACDOCA_RWCUR = TCURX_DOC.TCURX_CURRKEY

		LEFT JOIN B00_TCURX TCURX_CC     
				ON  A_T001.T001_WAERS = TCURX_CC.TCURX_CURRKEY  
        
        -- Add currency conversion factors for group currency
        LEFT JOIN B00_TCURX TCURX_KSL    
				ON 	B04_12_TT_AR_DOCUMENT.ACDOCA_RKCUR = TCURX_KSL.TCURX_CURRKEY

        -- Add currency conversion factors for third currency
        LEFT JOIN B00_TCURX TCURX_OSL
				ON 	B04_12_TT_AR_DOCUMENT.ACDOCA_ROCUR = TCURX_OSL.TCURX_CURRKEY 
				
		LEFT JOIN B04_09_IT_ACDOCA_BKPF_ACC_SCH
		ON  B04_12_TT_AR_DOCUMENT.ACDOCA_RBUKRS = B04_09_IT_ACDOCA_BKPF_ACC_SCH.ACDOCA_RBUKRS AND
			B04_12_TT_AR_DOCUMENT.ACDOCA_GJAHR = B04_09_IT_ACDOCA_BKPF_ACC_SCH.ACDOCA_GJAHR AND
			B04_12_TT_AR_DOCUMENT.ACDOCA_BELNR = B04_09_IT_ACDOCA_BKPF_ACC_SCH.ACDOCA_BELNR

		LEFT JOIN B04_02_TT_CSKT_DATBI
			ON B04_12_TT_AR_DOCUMENT.ACDOCA_KOKRS = B04_02_TT_CSKT_DATBI.CSKT_KOKRS
			AND B04_12_TT_AR_DOCUMENT.ACDOCA_RCNTR = B04_02_TT_CSKT_DATBI.CSKT_KOSTL
			AND B04_02_TT_CSKT_DATBI.CSKT_DATBI > @downloaddate

		LEFT JOIN B04_04_TT_CEPCT_UNIQUE
		ON	B04_12_TT_AR_DOCUMENT.ACDOCA_KOKRS = B04_04_TT_CEPCT_UNIQUE.CEPCT_KOKRS AND
			B04_12_TT_AR_DOCUMENT.ACDOCA_PRCTR = B04_04_TT_CEPCT_UNIQUE.CEPCT_PRCTR 

		LEFT JOIN B00_TBSLT
		ON	B04_12_TT_AR_DOCUMENT.ACDOCA_BSCHL = B00_TBSLT.TBSLT_BSCHL AND
			B04_12_TT_AR_DOCUMENT.ACDOCA_UMSKZ = B00_TBSLT.TBSLT_UMSKZ

		LEFT JOIN A_TSTCT
		ON	A_TSTCT.TSTCT_SPRSL IN ('E', 'EN') AND
			A_TSTCT.TSTCT_TCODE = B04_12_TT_AR_DOCUMENT.BKPF_TCODE

		/* 
			Add a columns to flag the AR documents which debit customer and credit vendor but the customer and vendor is the same person.
		*/
		EXEC SP_DROPTABLE 'B04_13B_TT_FIN_GL_CHECK_LIST'
		SELECT DISTINCT ACDOCA_RBUKRS,
						ACDOCA_GJAHR,
						ACDOCA_BELNR,
						ACDOCA_LIFNR
		INTO B04_13B_TT_FIN_GL_CHECK_LIST
		FROM B04_08_IT_FIN_GL
		WHERE ACDOCA_DRCRK = 'H' AND ACDOCA_LIFNR <> ''
		EXEC SP_CREATE_INDEX B04_13B_TT_FIN_GL_CHECK_LIST, 'B04_13B_IT_FIN_GL_CHECK_LIST','ACDOCA_RBUKRS, ACDOCA_GJAHR, ACDOCA_BELNR, ACDOCA_LIFNR'

		ALTER TABLE B04_13_IT_AR_ACC_SCH ADD ZF_LIFNR_KUNNR_IS_SAME_FLAG NVARCHAR(1) DEFAULT 'N' WITH VALUES;
		UPDATE B04_13_IT_AR_ACC_SCH
		SET ZF_LIFNR_KUNNR_IS_SAME_FLAG = 'Y'
		WHERE EXISTS(
			SELECT TOP 1 1
			FROM B04_13B_TT_FIN_GL_CHECK_LIST
			WHERE	B04_13B_TT_FIN_GL_CHECK_LIST.ACDOCA_RBUKRS = B04_13_IT_AR_ACC_SCH.ACDOCA_RBUKRS AND
					B04_13B_TT_FIN_GL_CHECK_LIST.ACDOCA_GJAHR = B04_13_IT_AR_ACC_SCH.ACDOCA_GJAHR AND
					B04_13B_TT_FIN_GL_CHECK_LIST.ACDOCA_BELNR = B04_13_IT_AR_ACC_SCH.ACDOCA_BELNR AND
					B04_13B_TT_FIN_GL_CHECK_LIST.ACDOCA_LIFNR = B04_13_IT_AR_ACC_SCH.KNA1_LIFNR AND
					B04_13_IT_AR_ACC_SCH.KNA1_LIFNR <> ''
		)
		AND B04_13_IT_AR_ACC_SCH.ACDOCA_DRCRK = 'S'

			

--/*Drop temporary tables*/
EXEC SP_REMOVE_TABLES '%_TT_%'
EXEC SP_RENAME_FIELD 'B04_', 'B04_05_IT_BKPF_ACDOCA'
EXEC SP_RENAME_FIELD 'B04_GL_', 'B04_08_IT_FIN_GL'
EXEC SP_RENAME_FIELD 'B04_09_', 'B04_09_IT_ACDOCA_BKPF_ACC_SCH'



/* log cube creation*/
 
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','B04_05_IT_FIN_GL',(SELECT COUNT(*) FROM B04_08_IT_FIN_GL)
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','B04_07_IT_ACDOCA_BKPF_ACC_SCH',(SELECT COUNT(*) FROM B04_11_IT_AP_ACC_SCH)
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','B04_10_IT_BSAK_BSIK_AP_ACC_SCH',(SELECT COUNT(*) FROM B04_13_IT_AR_ACC_SCH)
 
/* log end of procedure*/

 
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL
GO
