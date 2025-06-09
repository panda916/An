USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE      PROCEDURE [dbo].[MERGE_script_B04_FIN_GENERAL_LEDGER]
WITH EXECUTE AS CALLER
AS

EXEC SP_REMOVE_TABLES 'B04%'
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
 
 
/*Test mode*/
 
SET ROWCOUNT @LIMIT_RECORDS

 
/*Change history comments*/
 
/*
       Title                : [B04_FIN_GLA_UNIV]
       Description   : 
    
       --------------------------------------------------------------
       Update history
       --------------------------------------------------------------
       Date                     |  Who                  |      Description
       DD-MM-YYYY                       Initials             Initial version
       19-03-2017                       CW                   Update and standardisation for SID
       30-06-2017                       AJ					 Updated scripts with new naming convention
       28-07-2017						ANH					 Updated scripts to integrate fields necessary for red flags
	   22-03-2022						Thuan				 Remove MANDT field in join
	   05-08-2022	                    Khoa	             Add BSEG_MWSKZ in GL cubes
*/
 
 --Step 1A Prepare REGUH, REGUP flag table
 	  EXEC SP_DROPTABLE 'B00_00_TT_REGUH'
	  SELECT DISTINCT REGUH_ZBUKR,REGUH_VBLNR,REGUH_LIFNR INTO B00_00_TT_REGUH FROM A_REGUH
	  EXEC SP_CREATE_INDEX 'REGUH_ZBUKR,REGUH_VBLNR,REGUH_LIFNR', 'B00_00_TT_REGUH'
	  EXEC SP_DROPTABLE 'B00_00B_TT_REGUP'
	  SELECT DISTINCT REGUP_BUKRS,REGUP_GJAHR,REGUP_BELNR,REGUP_SHKZG INTO B00_00B_TT_REGUP FROM A_REGUP
	  WHERE REGUP_XVORL = 'X'
	  EXEC SP_CREATE_INDEX 'REGUP_BUKRS,REGUP_GJAHR,REGUP_BELNR', 'B00_00B_TT_REGUP'


	 
/*--Step 1B
--This step orders cost centers by validity date in descending order, and adds a row number per
   combination of controlling area, cost centre and validity date
--Rows are being removed due to the following filters (WHERE):
                     CSKT_DATBI (Valid to date) is on or after the @downloaddate (ie that cost center is still valid at extraction)
*/

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
EXEC SP_CREATE_INDEX 'CSKT_MANDT, CSKT_KOSTL', 'B04_02_TT_CSKT_DATBI'

/*--Step 3
--Create a list of latest information per profit center
*/
	EXEC SP_DROPTABLE 'B04_03_TT_CEPCT'
	SELECT 
		A_CEPCT.*
		,ROW_NUMBER() OVER( PARTITION BY CEPCT_MANDT, CEPCT_PRCTR, CEPCT_KOKRS ORDER BY CEPCT_DATBI DESC) AS ROW_NR
	INTO B04_03_TT_CEPCT
	FROM A_CEPCT
	WHERE CEPCT_SPRAS = @language1
	AND CEPCT_DATBI> = @downloaddate

	EXEC SP_DROPTABLE 'B04_04_TT_CEPCT_UNIQUE'
	SELECT * INTO B04_04_TT_CEPCT_UNIQUE FROM B04_03_TT_CEPCT WHERE ROW_NR = 1 


/*--Step 3
-- Add the header information from the General Ledger (BKPF) to the detailed information from the General Ledger (BSEG)
-- Rows are being removed based on the following tables (because INNER JOIN):
                           Only keep lines for which mandate (MANDT) and company code (BUKRS) are found in AM_SCOPE table
-- In this step we add all of the information necessary for creating the list of accounting schemes per journal entry
*/
 
EXEC sp_droptable    'B04_05_TT_BKPF_BSEG'
 
		SELECT
			A_BKPF.BKPF_MANDT,
			AM_SCOPE.SCOPE_BUSINESS_DMN_L1,
			AM_SCOPE.SCOPE_BUSINESS_DMN_L2,  
			A_BSEG.BSEG_MWSKZ,
			A_BSEG.BSEG_BUKRS,               
			A_BSEG.BSEG_GJAHR,
			A_BSEG.BSEG_HKONT,             
			A_BSEG.BSEG_KOART,                 
			A_BSEG.BSEG_BELNR,               
			A_BSEG.BSEG_BUZEI,                 
			A_BKPF.BKPF_BKTXT,                
			A_BSEG.BSEG_SGTXT,                             
			A_BKPF.BKPF_BLDAT,                           
			A_BKPF.BKPF_CPUDT,                                                             
			A_BKPF.BKPF_CPUTM,
			A_BKPF.BKPF_AEDAT,
			A_BKPF.BKPF_UPDDT,                  
			A_BKPF.BKPF_USNAM,                 
			A_BKPF.BKPF_AWSYS,                 
			A_BKPF.BKPF_BUDAT,                                         
			A_BSEG.BSEG_AUGDT,                                           
			A_BSEG.BSEG_AUGBL,
			A_BKPF.BKPF_BLART,                 
			A_BSEG.BSEG_LIFNR,
			A_BSEG.BSEG_EBELN,
			A_BSEG.BSEG_EBELP,                             
			A_BSEG.BSEG_KUNNR,
			A_BSEG.BSEG_ANLN1,
			A_BSEG.BSEG_ANLN2,
			A_BSEG.BSEG_KTOSL,                 
			A_BSEG.BSEG_PRCTR,                 
			A_BSEG.BSEG_KOSTL,
			A_BSEG.BSEG_KOKRS,           
			A_BKPF.BKPF_TCODE,  
			B00_TSTCT.TSTCT_TTEXT,              
			A_BSEG.BSEG_XBILK,                 
			A_BSEG.BSEG_GVTYP,                
			A_BSEG.BSEG_XAUTO,                
			A_BSEG.BSEG_XHKOM,                
			A_BSEG.BSEG_XNEGP,               
			A_BSEG.BSEG_SHKZG,
			A_BKPF.BKPF_WAERS,                
			A_BSEG.BSEG_WRBTR,
			A_BKPF.BKPF_HWAER,       
			A_BSEG.BSEG_DMBTR,  
			A_BSEG.BSEG_BSCHL,                 
			A_BKPF.BKPF_GLVOR,                             
			A_BKPF.BKPF_XBLNR,                      
			A_BKPF.BKPF_AWTYP,              
			A_BKPF.BKPF_AWKEY,
			A_BKPF.BKPF_STJAH,                 
			A_BKPF.BKPF_STBLG,                
			A_BKPF.BKPF_STGRD,                 
			A_BSEG.BSEG_PROJK,
			A_BKPF.BKPF_BSTAT,               
			A_BKPF.BKPF_GRPID,
			A_BKPF.BKPF_BVORG,
			A_BKPF.BKPF_DBBLG,
			A_BKPF.BKPF_MONAT,
			A_BSEG.BSEG_UMSKZ,  
			A_BKPF.BKPF_KURSF,
			A_BSEG.BSEG_HWMET,
			A_BSEG.BSEG_MATNR,
			A_BSEG.BSEG_BWKEY,
			A_BSEG.BSEG_GSBER,
			A_BSEG.BSEG_DMBE2,
			A_BSEG.BSEG_DMBE3,
			A_BSEG.BSEG_AUGGJ,               
			A_BSEG.BSEG_ZFBDT,
			A_BSEG.BSEG_AUFNR,
			A_BSEG.BSEG_ZUONR,
			--AM_GL_BANK_ACC.GL_BANK_ACC_HKONT,          
			A_SKA1.SKA1_XBILK,               
			A_SKA1.SKA1_GVTYP,     
			A_SKB1.SKB1_XGKON,
			A_SKB1.SKB1_XOPVW,
			A_SKB1.SKB1_HBKID,
			B00_SKAT.SKAT_TXT20,               
			B04_02_TT_CSKT_DATBI.CSKT_KTEXT, 
			-- Add cost center description       
			CASE
			WHEN ISNULL(B04_02_TT_CSKT_DATBI.CSKT_MCTXT,'') = '' THEN 'Not assigned'
			ELSE B04_02_TT_CSKT_DATBI.CSKT_MCTXT
			END AS ZF_CSKT_MCTXT,	
			B04_04_TT_CEPCT_UNIQUE.CEPCT_MCTXT,
			A_T001.T001_KTOPL,
			A_T001.T001_BUTXT
		INTO B04_05_TT_BKPF_BSEG
      
       FROM A_BKPF
 
	   -- Get detail information from BSEG table.
       INNER JOIN A_BSEG
       ON     A_BKPF.BKPF_GJAHR = A_BSEG.BSEG_GJAHR AND
              A_BKPF.BKPF_BUKRS = A_BSEG.BSEG_BUKRS AND
              A_BKPF.BKPF_BELNR = A_BSEG.BSEG_BELNR
 
 
	   -- Filter on the mandates and company codes in scope
       -- Add information from the scope table concerning the business domain   
       INNER JOIN AM_SCOPE                                         
       ON    BSEG_BUKRS = AM_SCOPE.SCOPE_CMPNY_CODE           
      
       -- Add information to show if the account is for bank accounts
       /*
	   LEFT JOIN AM_GL_BANK_ACC                                       
       ON AM_GL_BANK_ACC.GL_BANK_ACC_HKONT = A_BSEG.BSEG_HKONT AND
			AM_GL_BANK_ACC.GL_BANK_ACC_BUKRS = A_BSEG.BSEG_BUKRS
		*/

       --Add chart of accounts code per company code
       LEFT JOIN A_T001                                             
       ON  A_T001.T001_BUKRS = BSEG_BUKRS                   
 
       -- Add chart of accounts
       LEFT JOIN A_SKA1                                            
       ON   A_SKA1.SKA1_KTOPL = A_T001.T001_KTOPL AND               
              A_SKA1.SKA1_SAKNR = A_BSEG.BSEG_HKONT                   
 
       -- Add chart fo accounts description
       LEFT JOIN B00_SKAT                                             
       ON     B00_SKAT.SKAT_KTOPL = A_T001.T001_KTOPL AND               
              B00_SKAT.SKAT_SAKNR = A_BSEG.BSEG_HKONT

	   -- Add G/L account information in the SKB1
	   LEFT JOIN A_SKB1
	   ON A_SKB1.SKB1_BUKRS = A_BSEG.BSEG_BUKRS AND
		  A_SKB1.SKB1_SAKNR = A_BSEG.BSEG_HKONT
 
       -- $$ move CSKT join up from B04_04
       LEFT JOIN B04_02_TT_CSKT_DATBI                   
       ON A_BSEG.BSEG_KOKRS = B04_02_TT_CSKT_DATBI.CSKT_KOKRS AND 
          A_BSEG.BSEG_KOSTL = B04_02_TT_CSKT_DATBI.CSKT_KOSTL      

		-- Include profit centers descriptions
		LEFT JOIN B04_04_TT_CEPCT_UNIQUE
		ON	A_BSEG.BSEG_KOKRS = B04_04_TT_CEPCT_UNIQUE.CEPCT_KOKRS AND
			A_BSEG.BSEG_PRCTR = B04_04_TT_CEPCT_UNIQUE.CEPCT_PRCTR 

       --Add the transaction code description
       LEFT JOIN B00_TSTCT
       ON A_BKPF.BKPF_TCODE = B00_TSTCT.TSTCT_TCODE
       
	   WHERE NOT((BSEG_BUKRS = 'TR10' OR BSEG_BUKRS = 'TR20') AND BKPF_MONAT = 13)


	   -- Adding single index to speed up STUFF performance -- add back GL_BANK_ACC_HKONT
	   EXEC SP_CREATE_INDEX 'BSEG_BUKRS,BSEG_GJAHR,BSEG_BELNR,BSEG_SHKZG,SKA1_XBILK,SKA1_GVTYP,BSEG_KOART,BSEG_KOSTL,CSKT_KTEXT,CEPCT_MCTXT', 'B04_05_TT_BKPF_BSEG'

/*
	Update script with new automatic AR/AP mapping
	Step 3.1: Add indicator for G/L bank accounts
*/

	-- Add a new flag column for indicator of bank accounts from A_T012K, A_FEBKO and SKB1 tables

	ALTER TABLE B04_05_TT_BKPF_BSEG ADD ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG NVARCHAR(1) DEFAULT '' WITH VALUES;
	
	UPDATE B04_05_TT_BKPF_BSEG
	SET ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG = 'Y'
	WHERE 
	-- G/L account exist in the T012K
	EXISTS(
		SELECT TOP 1 1
		FROM A_T012K
		WHERE B04_05_TT_BKPF_BSEG.BSEG_BUKRS = A_T012K.T012K_BUKRS AND
			  B04_05_TT_BKPF_BSEG.BSEG_HKONT = A_T012K.T012K_HKONT
	)

	-- OR G/L account exists in the FEBKO 
	OR	EXISTS(
				SELECT TOP 1 1
				FROM A_FEBKO
				WHERE B04_05_TT_BKPF_BSEG.BSEG_BUKRS = A_FEBKO.FEBKO_BUKRS AND
					  B04_05_TT_BKPF_BSEG.BSEG_HKONT = A_FEBKO.FEBKO_HKONT
	)
	
	-- OR G/L account which has SKB1_HBKID or SKB1_XGKON not blank
	OR EXISTS (
		SELECT TOP 1 1
		FROM A_SKB1
		WHERE B04_05_TT_BKPF_BSEG.BSEG_BUKRS = A_SKB1.SKB1_BUKRS AND
			  B04_05_TT_BKPF_BSEG.BSEG_HKONT = A_SKB1.SKB1_SAKNR AND
			  (ISNULL(A_SKB1.SKB1_HBKID, '') <> '' OR ISNULL(A_SKB1.SKB1_XGKON, '') <> '')

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
           B04_05_TT_BKPF_BSEG.BKPF_MANDT
          ,B04_05_TT_BKPF_BSEG.BSEG_BUKRS
          ,B04_05_TT_BKPF_BSEG.BSEG_GJAHR
          ,B04_05_TT_BKPF_BSEG.BSEG_BELNR
          ,B04_05_TT_BKPF_BSEG.BKPF_BKTXT
          ,CASE
             WHEN COUNT(DISTINCT(B04_05_TT_BKPF_BSEG.BSEG_HKONT)) = 1 THEN 'X'
             ELSE ''
           END AS ZF_BSEG_HKONT_1_ACCNT_THIS_JE
          ,CASE
             WHEN COUNT(NULLIF('', B04_05_TT_BKPF_BSEG.BSEG_XAUTO)) = Count(B04_05_TT_BKPF_BSEG.BKPF_MANDT) THEN 'X'
             ELSE ''
           END AS ZF_BSEG_XAUTO_ALL_LINES_AUTO
          ,CASE
             WHEN (B04_05_TT_BKPF_BSEG.BKPF_BKTXT LIKE '%auto%' AND B04_05_TT_BKPF_BSEG.BKPF_BKTXT LIKE '%clear%')
                               THEN 'X'
             ELSE ''
           END AS ZF_BKPF_BKTXT_AUTO_CLEAR
      
         INTO B04_07_TT_INDIC_PER_JE_NUM
     
         FROM B04_05_TT_BKPF_BSEG
     
         GROUP BY
            BKPF_MANDT, BSEG_BUKRS, BSEG_GJAHR, BSEG_BELNR, BKPF_BKTXT
 
 
/*--Step 6
-- Step 6.1
-- All of the above information is added to the GL
-- The following hard-coded values are found in this step:
--    Months  (based on BKPF_MONAT) and assuming it is a calendar from 1st April
--    Description of GL account type (BSEG_KOART)
--Fields are being added from other SAP tables as mentioned in JOIN clauses below
--Fields are being calculated as mentioned in SELECT clause below*/
 
EXEC sp_droptable  'B04_11_IT_FIN_GL'
 
            SELECT DISTINCT 
					B04_05_TT_BKPF_BSEG.BSEG_MWSKZ,
                    B04_05_TT_BKPF_BSEG.BKPF_MANDT,
                    B04_05_TT_BKPF_BSEG.BSEG_BUKRS,
					B04_05_TT_BKPF_BSEG.BSEG_GJAHR,
                    B04_05_TT_BKPF_BSEG.BSEG_BELNR,
                    B04_05_TT_BKPF_BSEG.BSEG_BUZEI,
                    --B04_05_TT_BKPF_BSEG.T001_BUTXT,
                    -- Add fiscal year + posting period
                    B04_05_TT_BKPF_BSEG.BSEG_GJAHR + '-' + B04_05_TT_BKPF_BSEG.BKPF_MONAT AS ZF_BKPF_GJAHR_MONAT,
					B04_05_TT_BKPF_BSEG.BKPF_MONAT,
                    CAST(YEAR(B04_05_TT_BKPF_BSEG.BKPF_BUDAT) AS VARCHAR(4)) + '-' +
                        RIGHT('0' + CAST(MONTH(B04_05_TT_BKPF_BSEG.BKPF_BUDAT) AS VARCHAR(2)),2) AS ZF_BKPF_BUDAT_YEAR_MNTH,
                    --B04_05_TT_BKPF_BSEG.T001_KTOPL,
                    B04_05_TT_BKPF_BSEG.BSEG_KOART,
                    -- Add acount type description
                    CASE
                        WHEN B04_05_TT_BKPF_BSEG.BSEG_KOART = 'A' THEN 'Assets'
                        WHEN B04_05_TT_BKPF_BSEG.BSEG_KOART = 'D' THEN 'Customers'
                        WHEN B04_05_TT_BKPF_BSEG.BSEG_KOART = 'K' THEN 'Vendors'
                        WHEN B04_05_TT_BKPF_BSEG.BSEG_KOART = 'M' THEN 'Material'
                        WHEN B04_05_TT_BKPF_BSEG.BSEG_KOART = 'S' THEN 'G/L accounts'
                        ELSE ''
                    END                                                                  AS ZF_BKPF_KOART_DESC,
                    B04_05_TT_BKPF_BSEG.BSEG_HKONT SPCAT_GL_ACCNT,
                    B04_05_TT_BKPF_BSEG.BSEG_BSCHL,
                    B04_05_TT_BKPF_BSEG.BKPF_BLART,
                    B04_05_TT_BKPF_BSEG.BKPF_BKTXT,
                    B04_05_TT_BKPF_BSEG.BSEG_SGTXT,
                    B04_05_TT_BKPF_BSEG.BKPF_BLDAT,
                    B04_05_TT_BKPF_BSEG.BKPF_CPUDT,      
                    B04_05_TT_BKPF_BSEG.BKPF_CPUTM,
                    B04_05_TT_BKPF_BSEG.BKPF_AEDAT,
                    B04_05_TT_BKPF_BSEG.BKPF_UPDDT,
                    B04_05_TT_BKPF_BSEG.BKPF_USNAM,
                    B04_05_TT_BKPF_BSEG.BKPF_TCODE,
                    B04_05_TT_BKPF_BSEG.BKPF_BUDAT,
					CAST(YEAR(BKPF_BUDAT) + ISNULL(ISNULL(B00_T009B_A.T009B_RELJR, B00_T009B_B.T009B_RELJR), 0) AS VARCHAR (4)) ZF_BPKF_FISCAL_YEAR_VARIANT, 
					CASE 
						WHEN BKPF_MONAT IN ('1','2','3','01','02','03') THEN 'Q1'
						WHEN BKPF_MONAT IN ('4','5','6','04','05','06') THEN 'Q2'
						WHEN BKPF_MONAT IN ('7','8','9','07','08','09') THEN 'Q3'
						WHEN BKPF_MONAT IN ('10','11','12') THEN 'Q4'
						ELSE 'unable to classify'
					END + '-' + FORMAT(BKPF_BUDAT, 'MMM-YY') ZF_BKPF_MONAT_DESC
                    -- Add flag to show if it is posted in the period
                    ,
					CASE 
						WHEN BKPF_MONAT IN ('1','2','3','01','02','03') THEN 'Q1'
						WHEN BKPF_MONAT IN ('4','5','6','04','05','06') THEN 'Q2'
						WHEN BKPF_MONAT IN ('7','8','9','07','08','09') THEN 'Q3'
						WHEN BKPF_MONAT IN ('10','11','12') THEN 'Q4'
						ELSE 'unable to classify'
					END ZF_BKPF_BUDAT_FQ
                    -- Add flag to show if it is posted in the period
					,CASE
                        WHEN B04_05_TT_BKPF_BSEG.BKPF_BUDAT >= @date1 AND B04_05_TT_BKPF_BSEG.BKPF_BUDAT <= @date2 THEN 'X'
                        ELSE ''
                    END AS ZF_BKPF_BUDAT_IN_PERIOD,
                    B04_05_TT_BKPF_BSEG.BSEG_AUGDT,
                    B04_05_TT_BKPF_BSEG.BSEG_AUGBL,
                    B04_05_TT_BKPF_BSEG.BSEG_BWKEY,
                    B04_05_TT_BKPF_BSEG.BSEG_LIFNR,
                    B04_05_TT_BKPF_BSEG.BSEG_KUNNR,
                    B04_05_TT_BKPF_BSEG.BSEG_MATNR,
                    B04_05_TT_BKPF_BSEG.BSEG_ANLN1,
                    B04_05_TT_BKPF_BSEG.BSEG_ANLN2,
                    B04_05_TT_BKPF_BSEG.BSEG_PROJK,
                    B04_05_TT_BKPF_BSEG.BSEG_EBELN,
                    B04_05_TT_BKPF_BSEG.BSEG_EBELP,
                    B04_05_TT_BKPF_BSEG.BSEG_KOSTL,
					B04_05_TT_BKPF_BSEG.BSEG_KOKRS,
					B04_05_TT_BKPF_BSEG.BSEG_AUGGJ,
					B04_05_TT_BKPF_BSEG.BSEG_HKONT,
					B04_05_TT_BKPF_BSEG.BSEG_UMSKZ,
					B04_05_TT_BKPF_BSEG.BSEG_AUFNR,
					B04_05_TT_BKPF_BSEG.BSEG_ZUONR,
					B04_05_TT_BKPF_BSEG.BSEG_GSBER,
                    B04_05_TT_BKPF_BSEG.BSEG_XBILK,
                    B04_05_TT_BKPF_BSEG.BSEG_GVTYP,
                    B04_05_TT_BKPF_BSEG.BSEG_XAUTO,
                    B04_05_TT_BKPF_BSEG.BSEG_XHKOM,
                    B04_05_TT_BKPF_BSEG.BSEG_XNEGP,
                    B04_05_TT_BKPF_BSEG.BSEG_SHKZG,
                    -- Add Debit/Credit description
                    CASE B04_05_TT_BKPF_BSEG.BSEG_SHKZG
                    WHEN 'S'  THEN 'Debit'
                    WHEN 'H'  THEN 'Credit'
                    END                                                                        AS ZF_BSEG_SHKZG_DESC,
                    B04_05_TT_BKPF_BSEG.BKPF_WAERS                                             AS BKPF_WAERS,
 
                    -- Add value (document currency)
                    CONVERT(money,B04_05_TT_BKPF_BSEG.BSEG_WRBTR * (CASE WHEN B04_05_TT_BKPF_BSEG.BSEG_SHKZG = 'S' THEN 1 ELSE -1 END) * ISNULL(TCURX_DOC.TCURX_factor,1)) AS ZF_BSEG_WRBTR_S_DOC, 
			
                    B04_05_TT_BKPF_BSEG.BKPF_HWAER,
 
                    -- Add Value(company currency)
                    CONVERT(money,B04_05_TT_BKPF_BSEG.BSEG_DMBTR * (CASE WHEN B04_05_TT_BKPF_BSEG.BSEG_SHKZG = 'S' THEN 1 ELSE -1 END) * ISNULL(TCURX_COC.TCURX_factor,1)) AS ZF_BSEG_DMBTR_S,
                    CONVERT(money,B04_05_TT_BKPF_BSEG.BSEG_DMBTR * (CASE WHEN B04_05_TT_BKPF_BSEG.BSEG_SHKZG = 'S' THEN 1 ELSE 0 END) * ISNULL(TCURX_COC.TCURX_factor,1)) AS ZF_BSEG_DMBTR_DB,
                    CONVERT(money,B04_05_TT_BKPF_BSEG.BSEG_DMBTR * (CASE WHEN B04_05_TT_BKPF_BSEG.BSEG_SHKZG = 'H' THEN 1 ELSE 0 END) * ISNULL(TCURX_COC.TCURX_factor,1)) AS ZF_BSEG_DMBTR_CR,
                    ABS(CONVERT(money,B04_05_TT_BKPF_BSEG.BSEG_DMBTR * (CASE WHEN B04_05_TT_BKPF_BSEG.BSEG_SHKZG = 'S' THEN 1 ELSE -1 END) * ISNULL(TCURX_COC.TCURX_factor,1))) AS ZF_BSEG_DMBTR_S_ABS,
                    
                    @currency AS AM_GLOBALS_CURRENCY,
                    -- Add Value(custom currency)
                    CONVERT(money,B04_05_TT_BKPF_BSEG.BSEG_DMBTR * (CASE WHEN (B04_05_TT_BKPF_BSEG.BSEG_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1) * ISNULL(TCURX_COC.TCURX_factor,1)) AS ZF_BSEG_DMBTR_S_CUC,
					B04_05_TT_BKPF_BSEG.BSEG_DMBE2 * (CASE WHEN (B04_05_TT_BKPF_BSEG.BSEG_SHKZG = 'S') THEN 1 ELSE -1 END) ZF_BSEG_DMBE2_S,
					B04_05_TT_BKPF_BSEG.BSEG_DMBE3 * (CASE WHEN (B04_05_TT_BKPF_BSEG.BSEG_SHKZG = 'S') THEN 1 ELSE -1 END) ZF_BSEG_DMBE3_S,
					B04_05_TT_BKPF_BSEG.BKPF_AWSYS,
                    B04_05_TT_BKPF_BSEG.BSEG_KTOSL,  
                    B04_05_TT_BKPF_BSEG.BKPF_GLVOR,
                    B04_05_TT_BKPF_BSEG.BKPF_XBLNR,
                    B04_05_TT_BKPF_BSEG.BKPF_AWTYP,
 
                    -- Add Reference document
                    Left(B04_05_TT_BKPF_BSEG.BKPF_AWKEY, 10)                             AS ZF_BKPF_AWKEY_DOC_NUM,
 
                    -- Add Reference year
                    RIGHT(B04_05_TT_BKPF_BSEG.BKPF_AWKEY,4)                              AS ZF_BKPF_AWKEY_YEAR,
                    B04_05_TT_BKPF_BSEG.BKPF_STJAH,
                    B04_05_TT_BKPF_BSEG.BKPF_STBLG,
                    B04_05_TT_BKPF_BSEG.BKPF_STGRD, 
                    B04_05_TT_BKPF_BSEG.BKPF_BSTAT,
                    A_T074U.T074U_MERKP,
                    B04_05_TT_BKPF_BSEG.BKPF_GRPID,
                    B04_05_TT_BKPF_BSEG.BKPF_BVORG,
                    B04_05_TT_BKPF_BSEG.BKPF_DBBLG,
                    B04_05_TT_BKPF_BSEG.BSEG_HWMET,
 
                    -- Add indicator to show if it is an electronic bank payment
                    CASE WHEN
                        B04_06_TT_FEBKO_EP.FEBEP_BELNR IS NULL THEN ''
                        ELSE 'X'
                    END                                                                        AS ZF_FEBEP_ELEC_BANK_PAY,
                    -- Add description of document status
                    CASE
                        WHEN ISNULL(A_T074U.T074U_MERKP,'') = '' THEN
                                CASE ISNULL(BKPF_BSTAT, '')
                                        WHEN 'V' THEN 'Parked'
                                        WHEN 'W' THEN 'Parked'
                                        WHEN 'Z' THEN 'Parked'
                                        WHEN 'S' THEN 'Noted'
                                        WHEN ''  THEN 'Normal'
                                        ELSE 'Other non-financial items'
                                END
                        ELSE  'Noted'     
                    END                                                                  AS ZF_BKPF_BSTAT_DESC
 
 
                -- Add cost center description
                    ,B04_05_TT_BKPF_BSEG.ZF_CSKT_MCTXT
				-- add profit center desc
				    ,B04_05_TT_BKPF_BSEG.BSEG_PRCTR
				    ,B04_05_TT_BKPF_BSEG.CEPCT_MCTXT
				-- Concatenate codes and descriptions
                    ,B04_05_TT_BKPF_BSEG.BSEG_KOART + ' - '  + CASE
                        WHEN B04_05_TT_BKPF_BSEG.BSEG_KOART = 'A' THEN 'Assets'
                        WHEN B04_05_TT_BKPF_BSEG.BSEG_KOART = 'D' THEN 'Customers'
                        WHEN B04_05_TT_BKPF_BSEG.BSEG_KOART = 'K' THEN 'Vendors'
                        WHEN B04_05_TT_BKPF_BSEG.BSEG_KOART = 'M' THEN 'Material'
                        WHEN B04_05_TT_BKPF_BSEG.BSEG_KOART = 'S' THEN 'G/L accounts'
                        ELSE ''
                    END  AS ZF_BSEG_KOART_TEXT
                    ,B04_05_TT_BKPF_BSEG.BSEG_KOSTL + ' - '  + B04_05_TT_BKPF_BSEG.ZF_CSKT_MCTXT AS BSEG_KOSTL_CSKT_MCTXT  -- [BSEG_KOSTL] + ' - '  +  [ZF_CSKT_MCTXT] AS [BSEG_KOSTL_CSKT_MCTXT]
					--,B04_05_TT_BKPF_BSEG.BSEG_KOKRS
 
       -- Additional fields that are required for manual journal entries consideration
 
               ,ZF_BKPF_BKTXT_AUTO_CLEAR
               ,ZF_BSEG_HKONT_1_ACCNT_THIS_JE
               ,ZF_BSEG_XAUTO_ALL_LINES_AUTO
 
        -- Additional fields that are interesting for manual journal entry analysis

         ,CASE 
            WHEN DATENAME(DW, BKPF_CPUDT) IN ('Saturday', 'Sunday') THEN 'X' 
            ELSE '' 
          END AS ZF_BKPF_CPUDT_WE 
         ,CASE 
            WHEN DATEPART(MM, BKPF_CPUDT) <> DATEPART(MM, BKPF_BUDAT) THEN 'Posted in other month' 
            ELSE 'Posted in same month' 
          END AS ZF_BUDAT_SAME_MONTH_CPUDT
         ,CASE 
            WHEN DATEPART(MM, BKPF_CPUDT) <> DATEPART(MM, BKPF_BLDAT) THEN 
                           CONVERT (NVARCHAR, DATEDIFF(DD, BKPF_CPUDT, BKPF_BLDAT)) 
            ELSE 'Posted in same month' 
          END AS ZF_CPUDT_MINUS_BLDAT 
         ,(CONVERT(MONEY,B04_05_TT_BKPF_BSEG.BSEG_DMBTR * COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1) * ISNULL(TCURX_COC.TCURX_factor,1)))
                AS ZF_BSEG_DMBTR_CUC_ABS
		-- Fields required for debit-credit refresh
		,B04_05_TT_BKPF_BSEG.BSEG_ZFBDT,
		CASE WHEN
			(BKPF_BSTAT = '' AND ISNULL(T074U_MERKP,'') = '')
			AND (BKPF_GLVOR LIKE 'RF%' OR BKPF_GLVOR LIKE 'RG%')
			AND BKPF_AWTYP IN ('BKPF', 'BKPFF', 'BKPFI', 'FOTP', '')
			AND ISNULL(BKPF_GRPID, '') = ''
			AND (USR02_USTYP = 'A' OR USR02_USTYP = 'S' OR ISNULL(USR02_USTYP, '') = '')
			AND (BKPF_TCODE LIKE 'F%' OR BKPF_TCODE LIKE 'Y%' OR BKPF_TCODE LIKE 'Z%' OR BKPF_TCODE IN ('ABF1', 'J1IH', 'SBWP', 'SO01'))
			AND BKPF_TCODE NOT IN ('F110', 'F150', 'FN5V', 'FNM1', 'FNM1S', 'FNM3', 'FNV5')
			AND BKPF_TCODE NOT IN ('FB21', 'FB22', 'FBA3', 'FBA8', 'FBCJ', 'FBW2', 'FBW4', 'FBZ4', 'FINT')
			AND ISNULL(B04_06_TT_FEBKO_EP.FEBEP_BELNR, '') = ''
			AND ISNULL(ZF_BKPF_BKTXT_AUTO_CLEAR, '') = '' THEN  'Manual'
		   WHEN 
			(BKPF_TCODE LIKE 'FBVB' AND BKPF_BLART IN ('AT', 'D<', 'D>' , 'DG', 'DH', 'DM', 'DQ', 'DR', 'SA', 'SN')) THEN 'Manual' -- Extra logic from SIE team
		ELSE 'Regular' END AS ZF_ENTRY_TYPE,
		'' AS ZF_HKONT_FOUND_IN_CSKB,
      	   A_KNA1.KNA1_NAME1 AS BSEG_KNA1_NAME1,
	   A_KNA1.KNA1_LIFNR AS BSEG_KNA1_LIFNR,
	   A_LFA1_B.LFA1_NAME1 AS BSEG_KNA1_LIFNR_NAME1,

	   A_LFA1.LFA1_NAME1 AS BSEG_LFA1_NAME1,
	   A_LFA1.LFA1_KUNNR AS BSEG_LFA1_KUNNR,
	   A_KNA1_B.KNA1_NAME1 AS BSEG_LFA1_KUNNR_NAME1,
		A_ANLT.ANLT_TXT50,
		MARA_MATKL,
		B00_T023T.T023T_WGBEZ,
		A_KNA1.KNA1_KTOKD, -- Customer group number
		T077X_TXT30, -- Customer group name
		A_LFA1.LFA1_KTOKK,  -- Supplier group number
		T077Y_TXT30 -- Supplier group text

        INTO B04_11_IT_FIN_GL
        
        FROM B04_05_TT_BKPF_BSEG

		-- Get company information from T001 table.
		LEFT JOIN A_T001
			ON  (A_T001.T001_BUKRS = BSEG_BUKRS)

		-- Get fiscal year table
		LEFT JOIN B00_T009B B00_T009B_A
			ON T001_PERIV = B00_T009B_A.T009B_PERIV AND
			   B00_T009B_A.T009B_POPER = 1 AND
			   B00_T009B_A.T009B_BDATJ = YEAR(B04_05_TT_BKPF_BSEG.BKPF_BUDAT)

		LEFT JOIN B00_T009B B00_T009B_B
			ON T001_PERIV = B00_T009B_B.T009B_PERIV AND
			   B00_T009B_B.T009B_POPER = 1 AND
			   B00_T009B_B.T009B_BDATJ = ''

		-- Get customer group
				LEFT JOIN A_KNA1 ON B04_05_TT_BKPF_BSEG.BSEG_KUNNR = KNA1_KUNNR
		-- Add Account Group Name
				LEFT JOIN AM_T077X ON KNA1_KTOKD = AM_T077X.T077X_KTOKD AND
				AM_T077X.T077X_SPRAS IN ('E', 'EN')
		-- Get supplier group number
				LEFT JOIN A_LFA1 ON B04_05_TT_BKPF_BSEG.BSEG_LIFNR = LFA1_LIFNR
		-- Add supplier group name for supplier
				LEFT JOIN AM_T077Y ON A_LFA1.LFA1_KTOKK = AM_T077Y.T077Y_KTOKK AND
				AM_T077Y.T077Y_SPRAS IN ('E', 'EN')

		-- Get user type information from USR02
		LEFT JOIN A_USR02
              ON  (B04_05_TT_BKPF_BSEG.BKPF_USNAM = A_USR02.USR02_BNAME)
  
      	-- Add currency factor from company currency to USD

		LEFT JOIN B00_IT_TCURF
		ON A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR
		AND B00_IT_TCURF.TCURF_TCURR  = @currency  
		AND B00_IT_TCURF.TCURF_GDATU = (
			SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
			FROM B00_IT_TCURF
			WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
					B00_IT_TCURF.TCURF_TCURR  = @currency  AND
					B00_IT_TCURF.TCURF_GDATU <= B04_05_TT_BKPF_BSEG.BKPF_BUDAT
			ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
			)
	-- Add exchange rate from company currency to USD
	LEFT JOIN B00_IT_TCURR
		ON A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR
		AND B00_IT_TCURR.TCURR_TCURR  = @currency  
		AND B00_IT_TCURR.TCURR_GDATU = (
			SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
			FROM B00_IT_TCURR
			WHERE A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
					B00_IT_TCURR.TCURR_TCURR  = @currency  AND
					B00_IT_TCURR.TCURR_GDATU <= B04_05_TT_BKPF_BSEG.BKPF_BUDAT
			ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
			) 
           -- Add currency factor for house currency
		LEFT JOIN B00_TCURX TCURX_COC
		ON B04_05_TT_BKPF_BSEG.BKPF_HWAER = TCURX_COC.TCURX_CURRKEY

       -- Add currency factor for document currency   
		LEFT JOIN B00_TCURX TCURX_DOC
		ON     
				B04_05_TT_BKPF_BSEG.BKPF_WAERS = TCURX_DOC.TCURX_CURRKEY
             
		-- Add account type info and Special GL's
		LEFT JOIN A_T074U
		ON   (B04_05_TT_BKPF_BSEG.BSEG_KOART = A_T074U.T074U_KOART) AND
				(B04_05_TT_BKPF_BSEG.BSEG_UMSKZ = A_T074U.T074U_UMSKZ)

        -- Add information about electronic bank payments    
              LEFT JOIN B04_06_TT_FEBKO_EP
        ON (B04_05_TT_BKPF_BSEG.BSEG_BUKRS = B04_06_TT_FEBKO_EP.FEBKO_BUKRS) AND
            (B04_05_TT_BKPF_BSEG.BSEG_GJAHR = B04_06_TT_FEBKO_EP.FEBEP_GJAHR) AND
            (B04_05_TT_BKPF_BSEG.BSEG_BELNR = B04_06_TT_FEBKO_EP.FEBEP_BELNR)

        ---- Add information indicators from GL itself
        LEFT JOIN B04_07_TT_INDIC_PER_JE_NUM
        ON  B04_05_TT_BKPF_BSEG.BSEG_BUKRS = B04_07_TT_INDIC_PER_JE_NUM.BSEG_BUKRS
            AND B04_05_TT_BKPF_BSEG.BSEG_GJAHR = B04_07_TT_INDIC_PER_JE_NUM.BSEG_GJAHR
            AND B04_05_TT_BKPF_BSEG.BSEG_BELNR = B04_07_TT_INDIC_PER_JE_NUM.BSEG_BELNR

		--Add material name and grouP
		LEFT JOIN A_MARA 
			ON MARA_MATNR=BSEG_MATNR
		--Add material group name
		LEFT JOIN B00_T023T
			ON MARA_MATKL=T023T_MATKL
		--Add asset descriptop
		LEFT JOIN A_ANLT
			ON ANLT_BUKRS=B04_05_TT_BKPF_BSEG.BSEG_BUKRS AND
			   ANLT_ANLN1=B04_05_TT_BKPF_BSEG.BSEG_ANLN1 AND
			   ANLT_ANLN2=B04_05_TT_BKPF_BSEG.BSEG_ANLN2

		--Add LFA1_KUNNR name
		LEFT JOIN A_KNA1 AS A_KNA1_B
			ON A_KNA1_B.KNA1_KUNNR=A_LFA1.LFA1_KUNNR
		--Add KNA1_LIFNR name
		LEFT JOIN A_LFA1 AS A_LFA1_B
			ON A_LFA1_B.LFA1_LIFNR=A_KNA1.KNA1_LIFNR

			-- Only keep journal entry lines that are posted and not noted and for which the posting
			-- date is between the dates specified by the user
			WHERE  ISNULL(B04_05_TT_BKPF_BSEG.BKPF_BSTAT, '')    = ''
			AND           ISNULL(A_T074U.T074U_MERKP,'')           = ''
			AND           B04_05_TT_BKPF_BSEG.BKPF_BUDAT    >= @date1
			AND           B04_05_TT_BKPF_BSEG.BKPF_BUDAT    <= @date2
			  

--UPDATE B04_11_IT_FIN_GL
--SET ZF_HKONT_FOUND_IN_CSKB='Y'
--WHERE EXISTS
--(
--	SELECT TOP 1 1
--	FROM A_CSKB
--	WHERE BSEG_KOKRS = A_CSKB.CSKB_KOKRS AND
--		  BSEG_HKONT = A_CSKB.CSKB_KSTAR AND
--		(YEAR(A_CSKB.CSKB_DATBI) = N'9999' OR A_CSKB.CSKB_DATBI >= BKPF_BLDAT )
--)


-- Step 6.2 Thuan update logic for accounting scheme.
-- Store temp table for accounting .


EXEC SP_DROPTABLE    'B04_11_TT_JE_ACCOUNT_TEMP'

SELECT  
	B04_11_IT_FIN_GL.BSEG_BUKRS,
	B04_11_IT_FIN_GL.BSEG_GJAHR,
	B04_11_IT_FIN_GL.BSEG_BELNR,
	B04_11_IT_FIN_GL.BSEG_KOART,
	B04_11_IT_FIN_GL.BSEG_SHKZG,
	B04_05_TT_BKPF_BSEG.ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG,
	B04_05_TT_BKPF_BSEG.SKA1_GVTYP,
	B04_11_IT_FIN_GL.BSEG_HKONT,
	B04_05_TT_BKPF_BSEG.SKAT_TXT20,
	B04_05_TT_BKPF_BSEG.T001_BUTXT, 
	B04_11_IT_FIN_GL.BKPF_MONAT,
	B04_11_IT_FIN_GL.BKPF_BLART,
	T003T_LTEXT,
	B04_11_IT_FIN_GL.BKPF_BUDAT,
	B04_11_IT_FIN_GL.BKPF_BLDAT,
	B04_11_IT_FIN_GL.BKPF_CPUDT,
	B04_11_IT_FIN_GL.BKPF_TCODE,
	TSTCT_TTEXT,
	B04_11_IT_FIN_GL.BKPF_AWTYP,
	T001_WAERS,
	B04_11_IT_FIN_GL.BKPF_USNAM,
	B04_11_IT_FIN_GL.ZF_ENTRY_TYPE,
	TANGO_ACCT, -- Get tango account
	TANGO_ACCT_TXT -- Get tango account description.              
	,CASE 
			
			WHEN B04_11_IT_FIN_GL.BSEG_KOART <> 'S' THEN B04_11_IT_FIN_GL.BSEG_KOART
			WHEN B04_11_IT_FIN_GL.BSEG_KOART = 'S' AND  
				(
					ISNULL(SKB1_HBKID,'') <> '' OR ISNULL(SKB1_XGKON,'') <> ''

				)	THEN 'S: Bank'
			WHEN B04_11_IT_FIN_GL.BSEG_KOART = 'S'  AND  ( ISNULL(SKA1_GVTYP,'') <> ''  )	
					THEN  
						CASE WHEN LEN(B04_11_IT_FIN_GL.BSEG_PRCTR)>0 THEN 'S: P&L : Profit'
							 WHEN LEN(B04_11_IT_FIN_GL.BSEG_KOSTL)>0 THEN 'S: P&L : Loss'
							ELSE 'S: P&L ' END
			WHEN B04_11_IT_FIN_GL.BSEG_KOART = 'S' AND  
				(
					 ISNULL(SKA1_XBILK,'') <> ''  AND  ( ISNULL(SKB1_HBKID,'') = '' AND ISNULL(SKB1_XGKON,'') = '')
				)	THEN 'S: BS Other'
	 ELSE 'Other cases' 
	 END AS ZF_BSEG_KOART,

	  ZF_BSEG_DMBTR_S * (CASE WHEN B04_05_TT_BKPF_BSEG.BSEG_SHKZG = 'S' THEN 1 ELSE 0 END) AS ZF_BSEG_DMBTR_S_DB,
	  ZF_BSEG_DMBTR_S * (CASE WHEN B04_05_TT_BKPF_BSEG.BSEG_SHKZG = 'H' THEN 1 ELSE 0 END) AS ZF_BSEG_DMBTR_S_CR,
	  ZF_BSEG_DMBTR_S,
	  ZF_BSEG_DMBTR_S_CUC * (CASE WHEN B04_05_TT_BKPF_BSEG.BSEG_SHKZG = 'S' THEN 1 ELSE 0 END) AS ZF_BSEG_DMBTR_S_CUC_DB,
	  ZF_BSEG_DMBTR_S_CUC * (CASE WHEN B04_05_TT_BKPF_BSEG.BSEG_SHKZG = 'H' THEN 1 ELSE 0 END) AS ZF_BSEG_DMBTR_S_CUC_CR,
	  V_USERNAME_NAME_TEXT,
	  --ZF_ENTRY_TYPE,
	  ZF_BKPF_KOART_DESC,
	  B04_11_IT_FIN_GL.BSEG_LIFNR,
	  B04_11_IT_FIN_GL.LFA1_KTOKK,
	   --Supplier account group description
      B00_T077Y.T077Y_TXT30,
	  B04_11_IT_FIN_GL.BSEG_KUNNR,
	  B04_11_IT_FIN_GL.KNA1_KTOKD,
	  B04_11_IT_FIN_GL.T077X_TXT30,
--	 , ZF_HKONT_FOUND_IN_CSKB
		BSEG_KNA1_NAME1,
		BSEG_LFA1_NAME1,
		MARA_MATKL,
		T023T_WGBEZ,
		B04_11_IT_FIN_GL.BSEG_ANLN1,
		B04_11_IT_FIN_GL.BSEG_ANLN2,
		ANLT_TXT50,
		BSEG_LFA1_KUNNR,
		BSEG_LFA1_KUNNR_NAME1,
		BSEG_KNA1_LIFNR,
		BSEG_KNA1_LIFNR_NAME1,
		B04_05_TT_BKPF_BSEG.BSEG_KOSTL,
		B04_05_TT_BKPF_BSEG.ZF_CSKT_MCTXT,
		B04_05_TT_BKPF_BSEG.BSEG_PRCTR,
		B04_05_TT_BKPF_BSEG.CEPCT_MCTXT
INTO B04_11_TT_JE_ACCOUNT_TEMP
FROM B04_11_IT_FIN_GL
LEFT JOIN B04_05_TT_BKPF_BSEG 
	ON B04_11_IT_FIN_GL.BSEG_BELNR = B04_05_TT_BKPF_BSEG.BSEG_BELNR
	AND B04_11_IT_FIN_GL.BSEG_BUKRS = B04_05_TT_BKPF_BSEG.BSEG_BUKRS
	AND B04_11_IT_FIN_GL.BSEG_GJAHR = B04_05_TT_BKPF_BSEG.BSEG_GJAHR
	AND B04_11_IT_FIN_GL.BSEG_BUZEI	 = B04_05_TT_BKPF_BSEG.BSEG_BUZEI

-- Add document type description
LEFT JOIN B00_T003T
    ON B04_11_IT_FIN_GL.BKPF_BLART = B00_T003T.T003T_BLART

-- Obtain company description and house currency
LEFT JOIN A_T001
        ON  B04_11_IT_FIN_GL.BSEG_BUKRS = A_T001.T001_BUKRS
LEFT JOIN A_V_USERNAME
          ON B04_11_IT_FIN_GL.BKPF_USNAM = A_V_USERNAME.V_USERNAME_BNAME
LEFT JOIN AM_TANGO
		ON RIGHT(CONCAT('0000000000',B04_11_IT_FIN_GL.BSEG_HKONT), 10) = RIGHT(CONCAT('0000000000',TANGO_GL_ACCT), 10)
-- Add supplier information
LEFT JOIN A_LFA1
        ON B04_11_IT_FIN_GL.BSEG_LIFNR = A_LFA1.LFA1_LIFNR
-- Add supplier account group text
LEFT JOIN B00_T077Y
        ON A_LFA1.LFA1_KTOKK = B00_T077Y.T077Y_KTOKK
--Get supplier information from the supplier master data table
LEFT JOIN A_KNA1 
	ON KNA1_KUNNR = B04_11_IT_FIN_GL.BSEG_KUNNR
-- Add customer account group
LEFT JOIN B00_T077X
    ON A_KNA1.KNA1_KTOKD = B00_T077X.T077X_KTOKD



	 
-- Step 6.2.1: Split into debit table to reduce run time 


EXEC SP_DROPTABLE 'B04_11_TT_JE_ACCOUNT_TEMP_CREDIT'
SELECT * INTO B04_11_TT_JE_ACCOUNT_TEMP_CREDIT
FROM B04_11_TT_JE_ACCOUNT_TEMP
WHERE BSEG_SHKZG = 'H'

-- Step 6.2.2: Create index 

CREATE INDEX ZF_BSEG_RCNTR_AND_DESC_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(BSEG_KOSTL, ZF_CSKT_MCTXT)
CREATE INDEX ZF_BSEG_PRCTR_AND_DESC_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(BSEG_PRCTR, CEPCT_MCTXT)
CREATE INDEX ZF_BSEG_KOART_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(BSEG_KOART, ZF_BKPF_KOART_DESC )
CREATE INDEX ZF_ACCOUNTS_DESC_COMBINE_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(BSEG_HKONT, SKAT_TXT20)
CREATE INDEX ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG)
CREATE INDEX ZF_SKA1_GVTYP_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(SKA1_GVTYP)
CREATE INDEX ZF_MARA_MATKL_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(MARA_MATKL,T023T_WGBEZ)
CREATE INDEX ZF_ANLN1_ANLN2_CREDIT_LIST_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(BSEG_ANLN1,BSEG_ANLN2, ANLT_TXT50 )
CREATE INDEX ZF_ZF_BSEG_KOART1_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(ZF_BKPF_KOART_DESC)
CREATE INDEX ZF_BSEG_LFA1_KTOKK_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(LFA1_KTOKK, T077Y_TXT30)
CREATE INDEX ZF_BSEG_LIFNR_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(BSEG_LIFNR,BSEG_LFA1_NAME1)
CREATE INDEX ZF_BSEG_KUNNR_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(BSEG_KUNNR,BSEG_KNA1_NAME1)
CREATE INDEX ZF_BSEG_KNA1_KTOKD_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(KNA1_KTOKD,T077X_TXT30)
CREATE INDEX ZF_BSEG_TANGO_ACCT_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(TANGO_ACCT)
CREATE INDEX ZF_BSEG_RACCT_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(BSEG_HKONT)
CREATE INDEX ZF_SKAT_TXT20_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(SKAT_TXT20)
CREATE INDEX ZF_BUKRS_GJAHR_BELNR_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_CREDIT(BSEG_BUKRS, BSEG_GJAHR, BSEG_BELNR)

-- Step 6.2.3: Run accounting for GL detail table

EXEC SP_DROPTABLE    'B04_11_TT_BSEG_BKPF_ACC_SCH_CREDIT'

SELECT 
	BSEG_BELNR,
	BSEG_GJAHR, 
	BSEG_BUKRS,
 
	-- Create a list of Cost center credit
    REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.BSEG_KOSTL+':'+B.ZF_CSKT_MCTXT)=1 ,'_' ,B.BSEG_KOSTL+':'+B.ZF_CSKT_MCTXT),'_')
        FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
        WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS  
            AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
            AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
            )
        GROUP BY B.BSEG_HKONT, B.BSEG_KOSTL,B.ZF_CSKT_MCTXT
		ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''), '_') , '__', '_') ZF_CREDIT_BSEG_KOSTL_AND_DESC

	-- Create a list of profit center credit
    ,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.BSEG_PRCTR+':'+B.CEPCT_MCTXT)=1 ,'_' ,B.BSEG_PRCTR+':'+B.CEPCT_MCTXT),'_')
        FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
        WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS  
            AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
            AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
            )
        GROUP BY B.BSEG_HKONT, B.BSEG_PRCTR,B.CEPCT_MCTXT
		ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''), '_') , '__', '_') ZF_CREDIT_BSEG_PRCTR_AND_DESC,

--Create a list of credit account types BSEG_KOART

    REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.BSEG_KOART+':'+B.ZF_BKPF_KOART_DESC)=1 ,'' ,B.BSEG_KOART+':'+B.ZF_BKPF_KOART_DESC ),'_')
		FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
		WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS  
			AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
			AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
			)
		GROUP BY B.BSEG_HKONT, B.BSEG_KOART, B.ZF_BKPF_KOART_DESC
		ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
		FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
		,1,1,''), '_') , '__', '_') ZF_CREDIT_ACCOUNT_TYPES,

 --Create a list for indicator of G/L bank accounts from T012K, FEBKO, and SKB1 for credit

    REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG ,'' ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_CREDIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST,

--Create a list indicator of SKA1_GVTYP for credit
	REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF(  IIF(LEN(B.SKA1_GVTYP) > 0, 'Y','')  ,'' ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.SKA1_GVTYP
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_CREDIT_SKA1_GVTYP_FLAG_LIST,

--Create a list indicator of BSEG_HKONT for credit
	REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF(   B.BSEG_HKONT ,'' ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_CREDIT_HKONT_LIST,

--Create a list indicator of BSEG_HKONT for credit
	REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF(    B.SKAT_TXT20 ,'' ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.SKAT_TXT20
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_CREDIT_SKAT_TXT20_LIST,

 --Create a list of credit account numbers + descriptions

 	REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.BSEG_HKONT +':'+B.SKAT_TXT20)=1,'_' , B.BSEG_HKONT +':'+B.SKAT_TXT20),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.SKAT_TXT20
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_CREDIT_HKONT_TXT20_LIST

-- Customer number and text
	,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.BSEG_KUNNR+':'+B.BSEG_KNA1_NAME1)=1 ,'' ,B.BSEG_KUNNR+':'+B.BSEG_KNA1_NAME1 ),'_')
	FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
	WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS
					AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
					AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
					AND B.BSEG_HKONT  <> '')
	GROUP BY B.BSEG_HKONT, B.BSEG_KUNNR, B.BSEG_KNA1_NAME1 
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
	FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
,1,1,''), '_') , '__', '_') ZF_CREDIT_BSEG_KUNNR_LIST

	--Credit supplier number and name BSEG_LFA1_NAME1
	,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.BSEG_LIFNR+':'+B.BSEG_LFA1_NAME1)=1 ,'' ,B.BSEG_LIFNR+':'+B.BSEG_LFA1_NAME1 ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.BSEG_LIFNR, B.BSEG_LFA1_NAME1
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_CREDIT_BSEG_LIFNR_LIST

	--Credit material group
	,REPLACE(ISNULL(STUFF((SELECT '_'+ COALESCE(IIF(LEN( B.MARA_MATKL+':'+B.T023T_WGBEZ)=1 ,'' ,B.MARA_MATKL+':'+B.T023T_WGBEZ ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.MARA_MATKL,B.T023T_WGBEZ
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_BSEG_MATNR_MARA_MATKL_CREDIT_LIST				

	--Credit asset
	,REPLACE(ISNULL(STUFF((SELECT '_'  + COALESCE(IIF(LEN( B.BSEG_ANLN1+ ':' + B.BSEG_ANLN2+':'+ B.ANLT_TXT50)= 2,'_', B.BSEG_ANLN1+ ':' + B.BSEG_ANLN2+':'+ B.ANLT_TXT50 ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.BSEG_ANLN1,B.BSEG_ANLN2, B.ANLT_TXT50
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC,  B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_BSEG_ANLN1_ANLN2_CREDIT_LIST
				
-- Add some field related to accounting dashboard.

	,MAX(T001_BUTXT) AS T001_BUTXT
	,MAX(BKPF_MONAT) AS BKPF_MONAT
	,MAX(BKPF_BLART) AS BKPF_BLART
	,MAX(T003T_LTEXT) AS T003T_LTEXT
	,MAX(BKPF_BUDAT) AS BKPF_BUDAT
	,MAX(BKPF_BLDAT) AS BKPF_BLDAT
	,MAX(BKPF_CPUDT) AS BKPF_CPUDT
	,MAX(BKPF_TCODE) AS BKPF_TCODE
	,MAX(TSTCT_TTEXT) AS TSTCT_TTEXT
	,MAX(BKPF_AWTYP) AS BKPF_AWTYP
	,MAX(T001_WAERS) AS T001_WAERS
	,MAX(BKPF_USNAM) AS  BKPF_USNAM
	,MAX(V_USERNAME_NAME_TEXT) AS V_USERNAME_NAME_TEXT
	,MAX(ZF_ENTRY_TYPE) AS ZF_ENTRY_TYPE,

-- Add account type detail (blank, P&L, non-bank) request from Claire credit

	REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF(    B.ZF_BSEG_KOART ,'' ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.ZF_BSEG_KOART
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_CREDIT_BSEG_KOART_CUSTOM_LIST,

-- Supplier group and text
	REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.LFA1_KTOKK+':'+B.T077Y_TXT30)=1 ,'' ,B.LFA1_KTOKK+':'+B.T077Y_TXT30 ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.LFA1_KTOKK, B.T077Y_TXT30
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_CREDIT_LFA1_KTOKK_LIST,

-- Customer group  credit
	REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.KNA1_KTOKD+':'+B.T077X_TXT30)=1 ,'' ,B.KNA1_KTOKD+':'+B.T077X_TXT30 ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.KNA1_KTOKD, B.T077X_TXT30
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_CREDIT_KNA1_KTOKD_LIST,

-- TANGO_ACCT credit
	REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF(    B.TANGO_ACCT ,'' ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_CREDIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.TANGO_ACCT
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_CREDIT_TANGO_ACCT_LIST,

	SUM(ZF_BSEG_DMBTR_S_CR) AS ZF_BSEG_DMBTR_S_CR, 
	SUM(ZF_BSEG_DMBTR_S_CUC_CR) AS  ZF_BSEG_DMBTR_S_CUC_CR
INTO B04_11_TT_BSEG_BKPF_ACC_SCH_CREDIT
FROM B04_11_TT_JE_ACCOUNT_TEMP_CREDIT
GROUP BY BSEG_BELNR, BSEG_GJAHR, BSEG_BUKRS


-- Step 6.2.4: Split into credit table to reduce run time 

EXEC SP_DROPTABLE 'B04_11_TT_JE_ACCOUNT_TEMP_DEBIT'
SELECT   * INTO B04_11_TT_JE_ACCOUNT_TEMP_DEBIT
FROM B04_11_TT_JE_ACCOUNT_TEMP
WHERE BSEG_SHKZG = 'S'

-- Step 6.2.5: Create index

CREATE INDEX ZF_BSEG_RCNTR_AND_DESC_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(BSEG_KOSTL, ZF_CSKT_MCTXT)
CREATE INDEX ZF_BSEG_PRCTR_AND_DESC_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(BSEG_PRCTR, CEPCT_MCTXT)
CREATE INDEX ZF_BSEG_KOART_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(BSEG_KOART, ZF_BKPF_KOART_DESC )
CREATE INDEX ZF_ACCOUNTS_DESC_COMBINE_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(BSEG_HKONT, SKAT_TXT20)
CREATE INDEX ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG)
CREATE INDEX ZF_SKA1_GVTYP_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(SKA1_GVTYP)
CREATE INDEX ZF_MARA_MATKL_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(MARA_MATKL,T023T_WGBEZ)
CREATE INDEX ZF_ANLN1_ANLN2_DEBIT_LIST_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(BSEG_ANLN1,BSEG_ANLN2, ANLT_TXT50 )
CREATE INDEX ZF_ZF_BSEG_KOART1_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(ZF_BKPF_KOART_DESC)
CREATE INDEX ZF_BSEG_LFA1_KTOKK_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(LFA1_KTOKK, T077Y_TXT30)
CREATE INDEX ZF_BSEG_LIFNR_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(BSEG_LIFNR,BSEG_LFA1_NAME1)
CREATE INDEX ZF_BSEG_KUNNR_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(BSEG_KUNNR,BSEG_KNA1_NAME1)
CREATE INDEX ZF_BSEG_KNA1_KTOKD_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(KNA1_KTOKD,T077X_TXT30)
CREATE INDEX ZF_BSEG_TANGO_ACCT_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(TANGO_ACCT)
CREATE INDEX ZF_BSEG_RACCT_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(BSEG_HKONT)
CREATE INDEX ZF_SKAT_TXT20_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(SKAT_TXT20)
CREATE INDEX ZF_BUKRS_GJAHR_BELNR_INDEX ON B04_11_TT_JE_ACCOUNT_TEMP_DEBIT(BSEG_BUKRS, BSEG_GJAHR, BSEG_BELNR)


-- Step 6.2.6: Run accounting for GL detail table

EXEC SP_DROPTABLE    'B04_11_TT_BSEG_BKPF_ACC_SCH_DEBIT'

SELECT 
	BSEG_BELNR,
	BSEG_GJAHR, 
	BSEG_BUKRS,
 
	-- Create a list of Cost center debit
    REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.BSEG_KOSTL+':'+B.ZF_CSKT_MCTXT)=1 ,'_' ,B.BSEG_KOSTL+':'+B.ZF_CSKT_MCTXT),'_')
        FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
        WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS  
            AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
            AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
            )
        GROUP BY B.BSEG_HKONT, B.BSEG_KOSTL,B.ZF_CSKT_MCTXT
		ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''), '_') , '__', '_') ZF_DEBIT_BSEG_KOSTL_AND_DESC

	-- Create a list of profit center debit
    ,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.BSEG_PRCTR+':'+B.CEPCT_MCTXT)=1 ,'_' ,B.BSEG_PRCTR+':'+B.CEPCT_MCTXT),'_')
        FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
        WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS  
            AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
            AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
            )
        GROUP BY B.BSEG_HKONT, B.BSEG_PRCTR,B.CEPCT_MCTXT
		ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
        FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
        ,1,1,''), '_') , '__', '_') ZF_DEBIT_BSEG_PRCTR_AND_DESC,

--Create a list of Debit account types BSEG_KOART

    REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.BSEG_KOART+':'+B.ZF_BKPF_KOART_DESC)=1 ,'' ,B.BSEG_KOART+':'+B.ZF_BKPF_KOART_DESC ),'_')
		FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
		WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS  
			AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
			AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
			)
		GROUP BY B.BSEG_HKONT, B.BSEG_KOART, B.ZF_BKPF_KOART_DESC
		ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
		FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
		,1,1,''), '_') , '__', '_') ZF_DEBIT_ACCOUNT_TYPES,

 --Create a list for indicator of G/L bank accounts from T012K, FEBKO, and SKB1 for debit

    REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF( B.ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG ,'' ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.ZF_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_DEBIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST,

--Create a list indicator of SKA1_GVTYP for debit
	REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF(  IIF(LEN(B.SKA1_GVTYP) > 0, 'Y','')  ,'' ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.SKA1_GVTYP
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_DEBIT_SKA1_GVTYP_FLAG_LIST,

--Create a list indicator of BSEG_HKONT for debit
	REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF(   B.BSEG_HKONT ,'' ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_DEBIT_HKONT_LIST,

--Create a list indicator of BSEG_HKONT for debit
	REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF(    B.SKAT_TXT20 ,'' ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.SKAT_TXT20
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_DEBIT_SKAT_TXT20_LIST,

 --Create a list of debit account numbers + descriptions

 	REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.BSEG_HKONT +':'+B.SKAT_TXT20)=1,'_' , B.BSEG_HKONT +':'+B.SKAT_TXT20),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.SKAT_TXT20
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_DEBIT_HKONT_TXT20_LIST

-- Customer number and text
	,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.BSEG_KUNNR+':'+B.BSEG_KNA1_NAME1)=1 ,'' ,B.BSEG_KUNNR+':'+B.BSEG_KNA1_NAME1 ),'_')
	FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
	WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS
					AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
					AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
					AND B.BSEG_HKONT  <> '')
	GROUP BY B.BSEG_HKONT, B.BSEG_KUNNR, B.BSEG_KNA1_NAME1 
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
	FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
,1,1,''), '_') , '__', '_') ZF_DEBIT_BSEG_KUNNR_LIST

	--Debit supplier number and name BSEG_LFA1_NAME1
	,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.BSEG_LIFNR+':'+B.BSEG_LFA1_NAME1)=1 ,'' ,B.BSEG_LIFNR+':'+B.BSEG_LFA1_NAME1 ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.BSEG_LIFNR, B.BSEG_LFA1_NAME1
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_DEBIT_BSEG_LIFNR_LIST

	--Debit material group
	,REPLACE(ISNULL(STUFF((SELECT '_'+ COALESCE(IIF(LEN( B.MARA_MATKL+':'+B.T023T_WGBEZ)=1 ,'' ,B.MARA_MATKL+':'+B.T023T_WGBEZ ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.MARA_MATKL,B.T023T_WGBEZ
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_BSEG_MATNR_MARA_MATKL_DEBIT_LIST				

	--Debit asset
	,REPLACE(ISNULL(STUFF((SELECT '_'  + COALESCE(IIF(LEN( B.BSEG_ANLN1+ ':' + B.BSEG_ANLN2+':'+ B.ANLT_TXT50)= 2,'_', B.BSEG_ANLN1+ ':' + B.BSEG_ANLN2+':'+ B.ANLT_TXT50 ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.BSEG_ANLN1,B.BSEG_ANLN2, B.ANLT_TXT50
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC,  B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_BSEG_ANLN1_ANLN2_DEBIT_LIST
				

-- Add account type detail (blank, P&L, non-bank) request from Claire DEBIT

	,REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF(    B.ZF_BSEG_KOART ,'' ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.ZF_BSEG_KOART
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_DEBIT_BSEG_KOART_CUSTOM_LIST,

-- Supplier group and text
	REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.LFA1_KTOKK+':'+B.T077Y_TXT30)=1 ,'' ,B.LFA1_KTOKK+':'+B.T077Y_TXT30 ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.LFA1_KTOKK, B.T077Y_TXT30
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_DEBIT_LFA1_KTOKK_LIST,

-- Customer group  debit
	REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(IIF(LEN( B.KNA1_KTOKD+':'+B.T077X_TXT30)=1 ,'' ,B.KNA1_KTOKD+':'+B.T077X_TXT30 ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.KNA1_KTOKD, B.T077X_TXT30
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_DEBIT_KNA1_KTOKD_LIST,

-- TANGO_ACCT debit
	REPLACE(ISNULL(STUFF((SELECT '_' + COALESCE(NULLIF(    B.TANGO_ACCT ,'' ),'_')
    FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT B
    WHERE (B.BSEG_BUKRS = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BUKRS  
        AND B.BSEG_GJAHR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_GJAHR
        AND B.BSEG_BELNR = B04_11_TT_JE_ACCOUNT_TEMP_DEBIT.BSEG_BELNR
        )
    GROUP BY B.BSEG_HKONT, B.TANGO_ACCT
	ORDER BY SUM(ABS(B.ZF_BSEG_DMBTR_S)) DESC, B.BSEG_HKONT
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
    ,1,1,''), '_') , '__', '_') ZF_DEBIT_TANGO_ACCT_LIST,

	SUM(ZF_BSEG_DMBTR_S_DB) AS ZF_BSEG_DMBTR_S_DB, 
	SUM(ZF_BSEG_DMBTR_S_CUC_DB) AS  ZF_BSEG_DMBTR_S_CUC_DB
INTO B04_11_TT_BSEG_BKPF_ACC_SCH_DEBIT
FROM B04_11_TT_JE_ACCOUNT_TEMP_DEBIT
GROUP BY BSEG_BELNR, BSEG_GJAHR, BSEG_BUKRS




-- Step 6.2.7:  Combine debit and credit 


EXEC SP_DROPTABLE    'B04_07_IT_BSEG_BKPF_ACC_SCH'

SELECT 
	A.*, 
	B.ZF_DEBIT_BSEG_KOSTL_AND_DESC
	,B.ZF_DEBIT_BSEG_PRCTR_AND_DESC
	,B.ZF_DEBIT_ACCOUNT_TYPES
	,B.ZF_DEBIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST
	,B.ZF_DEBIT_SKA1_GVTYP_FLAG_LIST
	,B.ZF_DEBIT_HKONT_LIST
	,B.ZF_DEBIT_SKAT_TXT20_LIST
	,B.ZF_DEBIT_HKONT_TXT20_LIST
	,B.ZF_DEBIT_BSEG_KUNNR_LIST
	,B.ZF_DEBIT_BSEG_LIFNR_LIST
	,B.ZF_BSEG_MATNR_MARA_MATKL_DEBIT_LIST
	,B.ZF_BSEG_ANLN1_ANLN2_DEBIT_LIST
	,B.ZF_DEBIT_BSEG_KOART_CUSTOM_LIST
	,B.ZF_DEBIT_LFA1_KTOKK_LIST
	,B.ZF_DEBIT_KNA1_KTOKD_LIST
	,B.ZF_DEBIT_TANGO_ACCT_LIST
	,B.ZF_BSEG_DMBTR_S_DB
	,B.ZF_BSEG_DMBTR_S_CUC_DB

INTO B04_07_IT_BSEG_BKPF_ACC_SCH
FROM B04_11_TT_BSEG_BKPF_ACC_SCH_CREDIT  A
INNER JOIN 
	B04_11_TT_BSEG_BKPF_ACC_SCH_DEBIT B ON A.BSEG_BUKRS = B.BSEG_BUKRS AND A.BSEG_GJAHR = B.BSEG_GJAHR AND A.BSEG_BELNR = B.BSEG_BELNR

-- Create index
CREATE INDEX BSEG_BKPF_ACC_SCH_IDX1 ON B04_07_IT_BSEG_BKPF_ACC_SCH(BSEG_BUKRS, BSEG_GJAHR, BSEG_BELNR)



DROP TABLE B04_11_TT_JE_ACCOUNT_TEMP
EXEC SP_RENAME_FIELD 'B04_', 'B04_11_IT_FIN_GL' 
 
---------------------------------------------------------------------------------------------
------The following steps are done in order to add the list of journal entry schemes to P2P
------The same model can be followed for O2C
------The accounting schemes are analysed and updated in B07 and B07B - where they are
------classifed as invoices or payments, before running PTP and O2C
---------------------------------------------------------------------------------------------
 
---- Step 8/ Append BSAK and BSIK tables and create a list to which accounting schemes can be added
 
EXEC sp_droptable 'B04_08_TT_BSIK_BSAK'
 
  -- Closed items   
       SELECT
            -- Key that will enable to join to BSEG and back to BSAK
            A_BSAK.BSAK_MANDT AS BSAIK_MANDT
            ,A_BSAK.BSAK_BUKRS AS BSAIK_BUKRS
            ,A_BSAK.BSAK_GJAHR AS BSAIK_GJAHR
            ,A_BSAK.BSAK_BELNR AS BSAIK_BELNR
            ,A_BSAK.BSAK_BUZEI AS BSAIK_BUZEI
            -- Posting key information that is useful for determining if it is an invoice or payment
            ,A_BSAK.BSAK_BSCHL AS BSAIK_BSCHL
            -- debit credit indicator that is useful for determining if it is an invoice or payment
            ,A_BSAK.BSAK_SHKZG AS BSAIK_SHKZG       
            -- Document type that is useful for determining if is an invoice or a payment
            ,A_BSAK.BSAK_BLART AS BSAIK_BLART
            -- Supplier number in order to be able to add the supplier account group text
            -- which will be useful in order to know if it is for interco, employee or regular supplier
            ,A_BSAK.BSAK_LIFNR AS BSAIK_LIFNR
            -- Information for calculation of value fields as below
            ,A_BSAK.BSAK_WAERS AS BSAIK_WAERS
            ,A_BSAK.BSAK_DMBTR AS BSAIK_DMBTR
			,A_BSAK.BSAK_DMBE2 AS BSAIK_DMBE2
			,A_BSAK.BSAK_DMBE3 AS BSAIK_DMBE3
			  -- Other fields needed for AP cube:
			,A_BSAK.BSAK_UMSKS As BSAIK_UMSKS
			,A_BSAK.BSAK_UMSKZ As BSAIK_UMSKZ
			,A_BSAK.BSAK_AUGDT As BSAIK_AUGDT
			,A_BSAK.BSAK_AUGBL As BSAIK_AUGBL
			,A_BSAK.BSAK_ZUONR As BSAIK_ZUONR
 			,A_BSAK.BSAK_BUDAT As BSAIK_BUDAT
			,A_BSAK.BSAK_BLDAT As BSAIK_BLDAT
			,A_BSAK.BSAK_CPUDT As BSAIK_CPUDT
			,A_BSAK.BSAK_XBLNR As BSAIK_XBLNR
			,A_BSAK.BSAK_MONAT As BSAIK_MONAT
			,A_BSAK.BSAK_ZUMSK As BSAIK_ZUMSK
			,A_BSAK.BSAK_GSBER As BSAIK_GSBER
			,A_BSAK.BSAK_WRBTR As BSAIK_WRBTR
			,A_BSAK.BSAK_MWSKZ As BSAIK_MWSKZ
			,A_BSAK.BSAK_MWSTS As BSAIK_MWSTS
			,A_BSAK.BSAK_WMWST As BSAIK_WMWST
			,A_BSAK.BSAK_SGTXT As BSAIK_SGTXT
			,A_BSAK.BSAK_AUFNR As BSAIK_AUFNR
			,A_BSAK.BSAK_EBELN As BSAIK_EBELN
			,A_BSAK.BSAK_EBELP As BSAIK_EBELP
			,A_BSAK.BSAK_HKONT As BSAIK_HKONT
			,A_BSAK.BSAK_ZFBDT As BSAIK_ZFBDT
			,A_BSAK.BSAK_ZTERM As BSAIK_ZTERM
			,A_BSAK.BSAK_ZBD1T As BSAIK_ZBD1T
			,A_BSAK.BSAK_ZBD2T As BSAIK_ZBD2T
			,A_BSAK.BSAK_ZBD3T As BSAIK_ZBD3T
			,A_BSAK.BSAK_ZBD1P As BSAIK_ZBD1P
			,A_BSAK.BSAK_ZBD2P As BSAIK_ZBD2P
			,A_BSAK.BSAK_SKFBT As BSAIK_SKFBT
			,A_BSAK.BSAK_SKNTO As BSAIK_SKNTO
			,A_BSAK.BSAK_WSKTO As BSAIK_WSKTO
			,A_BSAK.BSAK_ZLSCH As BSAIK_ZLSCH
			,A_BSAK.BSAK_ZLSPR As BSAIK_ZLSPR
			,A_BSAK.BSAK_BSTAT As BSAIK_BSTAT
			,A_BSAK.BSAK_PROJK As BSAIK_PROJK
			,A_BSAK.BSAK_XRAGL As BSAIK_XRAGL
			,A_BSAK.BSAK_KOSTL As BSAIK_KOSTL
			,A_BSAK.BSAK_XNEGP As BSAIK_XNEGP
			,A_BSAK.BSAK_PRCTR As BSAIK_PRCTR
			,A_BSAK.BSAK_AUGGJ As BSAIK_AUGGJ
			,A_BSAK.BSAK_XANET AS BSAIK_XANET
			-- Add difference in number of days between input date and matching date
			,DATEDIFF(d,A_BSAK.BSAK_CPUDT,A_BSAK.BSAK_AUGDT) AS ZF_BSAIK_CPUDT_AGE_DAYS
			-- Add indicator to show if the document is open or closed based on table name
			,'Closed' AS ZF_BSAIK_OPEN_CLOSED
			-- Add description of debit/credit indicator
			, CASE 
				WHEN BSAK_SHKZG='H' THEN 'Credit' 
				ELSE 'Debit' 
			  END AS ZF_BSAIK_SHKZG_DESC 		
			  -- Add integer value for debit/credit indicator
			, CASE 
				WHEN BSAK_SHKZG='H' THEN -1 
				ELSE 1 END 
			  AS ZF_BSAIK_SHKZG_INTEGER
			  -- Add matching year-month
			,CAST(YEAR(BSAK_AUGDT) AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(MONTH(BSAK_AUGDT) AS VARCHAR(2)),2) AS ZF_BSAK_AUGDT_YEAR_MNTH
			--Add actual discount amount
			,CASE 
				WHEN BSAK_SKFBT = 0  THEN 0 
				ELSE ABS(ROUND(BSAK_WSKTO/BSAK_SKFBT,3) * 100)
			END AS ZF_BSAIK_WSKTO_SKBFT

 
       INTO B04_08_TT_BSIK_BSAK
       FROM A_BSAK
	   WHERE NOT ((BSAK_BUKRS = 'TR10' OR BSAK_BUKRS = 'TR20') AND BSAK_MONAT = 13) 
	   	   	 AND           BSAK_BUDAT    >= @date1
			 AND            BSAK_BUDAT    <= @date2
  -- Open items
   INSERT INTO B04_08_TT_BSIK_BSAK
       SELECT
              -- Key that will enable to join to BSEG and back to BSAK/BSIK
              A_BSIK.BSIK_MANDT AS BSAIK_MANDT
              ,A_BSIK.BSIK_BUKRS AS BSAIK_BUKRS
              ,A_BSIK.BSIK_GJAHR AS BSAIK_GJAHR
              ,A_BSIK.BSIK_BELNR AS BSAIK_BELNR
              ,A_BSIK.BSIK_BUZEI AS BSAIK_BUZEI
              -- Posting key information that is useful for determining if it is an invoice or payment
              ,A_BSIK.BSIK_BSCHL AS BSAIK_BSCHL
              -- Debit credit indicator that is useful for determining if it is an invoice or payment
              ,A_BSIK.BSIK_SHKZG AS BSAIK_SHKZG
              -- Document type that is useful for determining if is an invoice or a payment
              ,A_BSIK.BSIK_BLART AS BSAIK_BLART
              -- Supplier number in order to be able to add the supplier account group text
              -- which will be useful in order to know if it is for interco, employee or regular supplier
              ,A_BSIK.BSIK_LIFNR AS BSAIK_LIFNR
              -- Information for calculation of value fields as below
              ,A_BSIK.BSIK_WAERS AS BSAIK_WAERS
              ,A_BSIK.BSIK_DMBTR AS BSAIK_DMBTR
			  ,A_BSIK.BSIK_DMBE2 AS BSAIK_DMBE2
			  ,A_BSIK.BSIK_DMBE3 AS BSAIK_DMBE3
			  -- Other fields needed for AP cube:
			,A_BSIK.BSIK_UMSKS As BSAIK_UMSKS
			,A_BSIK.BSIK_UMSKZ As BSAIK_UMSKZ
			,A_BSIK.BSIK_AUGDT As BSAIK_AUGDT
			,A_BSIK.BSIK_AUGBL As BSAIK_AUGBL
			,A_BSIK.BSIK_ZUONR As BSAIK_ZUONR
 			,A_BSIK.BSIK_BUDAT As BSAIK_BUDAT
			,A_BSIK.BSIK_BLDAT As BSAIK_BLDAT
			,A_BSIK.BSIK_CPUDT As BSAIK_CPUDT
			,A_BSIK.BSIK_XBLNR As BSAIK_XBLNR
			,A_BSIK.BSIK_MONAT As BSAIK_MONAT
			,A_BSIK.BSIK_ZUMSK As BSAIK_ZUMSK
			,A_BSIK.BSIK_GSBER As BSAIK_GSBER
			,A_BSIK.BSIK_WRBTR As BSAIK_WRBTR
			,A_BSIK.BSIK_MWSKZ As BSAIK_MWSKZ
			,A_BSIK.BSIK_MWSTS As BSAIK_MWSTS
			,A_BSIK.BSIK_WMWST As BSAIK_WMWST
			,A_BSIK.BSIK_SGTXT As BSAIK_SGTXT
			,A_BSIK.BSIK_AUFNR As BSAIK_AUFNR
			,A_BSIK.BSIK_EBELN As BSAIK_EBELN
			,A_BSIK.BSIK_EBELP As BSAIK_EBELP
			,A_BSIK.BSIK_HKONT As BSAIK_HKONT
			,A_BSIK.BSIK_ZFBDT As BSAIK_ZFBDT
			,A_BSIK.BSIK_ZTERM As BSAIK_ZTERM
			,A_BSIK.BSIK_ZBD1T As BSAIK_ZBD1T
			,A_BSIK.BSIK_ZBD2T As BSAIK_ZBD2T
			,A_BSIK.BSIK_ZBD3T As BSAIK_ZBD3T
			,A_BSIK.BSIK_ZBD1P As BSAIK_ZBD1P
			,A_BSIK.BSIK_ZBD2P As BSAIK_ZBD2P
			,A_BSIK.BSIK_SKFBT As BSAIK_SKFBT
			,A_BSIK.BSIK_SKNTO As BSAIK_SKNTO
			,A_BSIK.BSIK_WSKTO As BSAIK_WSKTO
			,A_BSIK.BSIK_ZLSCH As BSAIK_ZLSCH
			,A_BSIK.BSIK_ZLSPR As BSAIK_ZLSPR
			,A_BSIK.BSIK_BSTAT As BSAIK_BSTAT
			,A_BSIK.BSIK_PROJK As BSAIK_PROJK
			,A_BSIK.BSIK_XRAGL As BSAIK_XRAGL
			,A_BSIK.BSIK_KOSTL As BSAIK_KOSTL
			,A_BSIK.BSIK_XNEGP As BSAIK_XNEGP
			,A_BSIK.BSIK_PRCTR As BSAIK_PRCTR
			,A_BSIK.BSIK_AUGGJ As BSAIK_AUGGJ
			,A_BSIK.BSIK_XANET AS BSAIK_XANET
			-- Add difference in number of days between input date and matching date
			,DATEDIFF(d,A_BSIK.BSIK_CPUDT,A_BSIK.BSIK_AUGDT) AS ZF_BSAIK_CPUDT_AGE_DAYS
			-- Add indicator to show if the document is open or closed based on table name
			,'Open' AS ZF_BSAIK_OPEN_CLOSED
			-- Add description of debit/credit indicator
			, CASE 
				WHEN BSIK_SHKZG='H' THEN 'Credit' 
				ELSE 'Debit' 
			  END AS ZF_BSAIK_SHKZG_DESC 		
			  -- Add integer value for debit/credit indicator
			, CASE 
				WHEN BSIK_SHKZG='H' THEN -1 
				ELSE 1 END 
			  AS ZF_BSAIK_SHKZG_INTEGER
			  -- Add matching year-month
			,CAST(YEAR(BSIK_AUGDT) AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(MONTH(BSIK_AUGDT) AS VARCHAR(2)),2) AS ZF_BSIK_AUGDT_YEAR_MNTH
			--Add actual discount amount
			,CASE 
				WHEN BSIK_SKFBT = 0  THEN 0 
				ELSE ABS(ROUND(BSIK_WSKTO/BSIK_SKFBT,3) * 100)
			END AS ZF_BSAIK_WSKTO_SKBFT
 
       FROM A_BSIK
       WHERE NOT ((BSIK_BUKRS = 'TR10' OR BSIK_BUKRS = 'TR20') AND BSIK_MONAT = 13)
	   AND BSIK_BUDAT <= @date2


	
-- Step 9/ Add the supplier account group and the document type description
--         Add value fields so that we can see the total value per account type
--         Add the accounting schmes

EXEC SP_DROPTABLE    'B04_10_IT_BSAK_BSIK_AP_ACC_SCH'
 
       SELECT B04_08_TT_BSIK_BSAK.*
	   -- Header information
	   ,A_BKPF.BKPF_AWTYP
	   ,B00_TBSLT.TBSLT_LTEXT
	   ,A_T074T.T074T_LTEXT

	   -- Local currency code
       ,A_T001.T001_WAERS
	   ,IIF(BSAIK_AUGBL = BSAIK_BELNR, 1, 0) ZF_DOC_CLEARING_FLAG
	   -- Signed amount - values are inversed so that total spend shows as positive on the dashboard
       ,CONVERT(MONEY,BSAIK_DMBTR * COALESCE(TCURX_CC.TCURX_FACTOR,1) * IIF(BSAIK_SHKZG = 'H',-1,1)) AS ZF_BSAIK_DMBTR_S
	   -- Custom currency code
       ,@currency      AS GLOBALS_CURRENCY
	   -- Signed amount in custom currency - values are inversed so that total spend shows as positive on the dashboard                                                                                                                                                                                AS AM_GLOBALS_CURRENCY
       ,CONVERT(MONEY,BSAIK_DMBTR * COALESCE(TCURX_CC.TCURX_FACTOR,1) * IIF(BSAIK_SHKZG = 'H', -1,1)  * COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1)) AS ZF_BSAIK_DMBTR_S_CUC	   ,BSAIK_DMBE2 * IIF(BSAIK_SHKZG = 'H',-1,1) AS ZF_BSAIK_DMBE2_S
	   ,BSAIK_DMBE3 * IIF(BSAIK_SHKZG = 'H',-1,1) AS ZF_BSAIK_DMBE3_S
	   --Supplier account group
       ,A_LFA1.LFA1_KTOKK
	   ,A_LFA1.LFA1_NAME1
	   ,A_LFA1.LFA1_KUNNR
	   --Supplier account group description
       ,B00_T077Y.T077Y_TXT30
	   -- Document type description
       ,B00_T003T.T003T_LTEXT
	   --Accounting schemes:
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.BKPF_TCODE, '_') BKPF_TCODE
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_DEBIT_ACCOUNT_TYPES, '_') ZF_DEBIT_ACCOUNT_TYPES
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_CREDIT_ACCOUNT_TYPES, '_') ZF_CREDIT_ACCOUNT_TYPES
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_DEBIT_HKONT_LIST, '_') ZF_DEBIT_HKONT_LIST
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_CREDIT_HKONT_LIST, '_') ZF_CREDIT_HKONT_LIST
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_DEBIT_SKAT_TXT20_LIST, '_') ZF_DEBIT_SKAT_TXT20_LIST
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_CREDIT_SKAT_TXT20_LIST, '_') ZF_CREDIT_SKAT_TXT20_LIST
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_DEBIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST, '_') AS ZF_DEBIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_CREDIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST, '_') AS ZF_CREDIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_CREDIT_SKA1_GVTYP_FLAG_LIST, '_') AS ZF_CREDIT_SKA1_GVTYP_FLAG_LIST
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_DEBIT_SKA1_GVTYP_FLAG_LIST, '_') AS ZF_DEBIT_SKA1_GVTYP_FLAG_LIST
        -- Cost center infromation needed in AP cube and based on B04_02_TT_CSKT_DATBI
		,COALESCE(CASE 
			WHEN B04_02_TT_CSKT_DATBI.CSKT_LTEXT ='' OR  B04_02_TT_CSKT_DATBI.CSKT_LTEXT IS NULL THEN 'Not assigned'
			ELSE BSAIK_KOSTL 
		 END,'Not assigned') ZF_BSAIK_KOSTL
		-- Cost center description
		,COALESCE(CASE 
			WHEN B04_02_TT_CSKT_DATBI.CSKT_LTEXT ='' OR  B04_02_TT_CSKT_DATBI.CSKT_LTEXT IS NULL THEN 'Not assigned'
			ELSE B04_02_TT_CSKT_DATBI.CSKT_LTEXT 
		 END,'Not assigned') ZF_CSKT_LTEXT
		,CEPCT_MCTXT
		,ISNULL((SELECT TOP 1 'X' FROM B00_00_TT_REGUH 
									WHERE BSAIK_LIFNR = REGUH_LIFNR
									AND REGUH_VBLNR = BSAIK_BELNR AND BSAIK_BUKRS  = REGUH_ZBUKR), '') ZF_REGUH_PAYMENT_FLAG
		,ISNULL((SELECT TOP 1 'X' FROM B00_00B_TT_REGUP 
									WHERE BSAIK_BUKRS = REGUP_BUKRS 
									AND BSAIK_GJAHR = REGUP_GJAHR 
									AND BSAIK_BELNR = REGUP_BELNR), '') ZF_REGUP_INVOICE_FLAG
       INTO B04_10_IT_BSAK_BSIK_AP_ACC_SCH

       FROM B04_08_TT_BSIK_BSAK

	   -- Add some header information from BKPF tables
	   LEFT JOIN A_BKPF
			ON B04_08_TT_BSIK_BSAK.BSAIK_BUKRS = A_BKPF.BKPF_BUKRS AND
				B04_08_TT_BSIK_BSAK.BSAIK_GJAHR = A_BKPF.BKPF_GJAHR AND
				B04_08_TT_BSIK_BSAK.BSAIK_BELNR = A_BKPF.BKPF_BELNR 
	   -- Thuan update 2024-01-09 to get BSEG_KOKRS from BSEG table
	   LEFT JOIN A_BSEG
			ON B04_08_TT_BSIK_BSAK.BSAIK_BUKRS = A_BSEG.BSEG_BUKRS AND
				B04_08_TT_BSIK_BSAK.BSAIK_GJAHR = A_BSEG.BSEG_GJAHR AND
				B04_08_TT_BSIK_BSAK.BSAIK_BELNR = A_BSEG.BSEG_BELNR AND 
				B04_08_TT_BSIK_BSAK.BSAIK_BUZEI = A_BSEG.BSEG_BUZEI

	   -- Add supplier information
       LEFT JOIN A_LFA1
              ON B04_08_TT_BSIK_BSAK.BSAIK_LIFNR = A_LFA1.LFA1_LIFNR
	   -- Add supplier account group text
       LEFT JOIN B00_T077Y
              ON A_LFA1.LFA1_KTOKK = B00_T077Y.T077Y_KTOKK
	   -- Add document type description
       LEFT JOIN B00_T003T
           ON B04_08_TT_BSIK_BSAK.BSAIK_BLART = B00_T003T.T003T_BLART
       -- Obtain company description and house currency
       LEFT JOIN A_T001
              ON  BSAIK_BUKRS = A_T001.T001_BUKRS
       -- Add currency factor from company currency to USD

		LEFT JOIN B00_IT_TCURF
		ON A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR
		AND B00_IT_TCURF.TCURF_TCURR  = @currency  
		AND B00_IT_TCURF.TCURF_GDATU = (
			SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
			FROM B00_IT_TCURF
			WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
					B00_IT_TCURF.TCURF_TCURR  = @currency  AND
					B00_IT_TCURF.TCURF_GDATU <= B04_08_TT_BSIK_BSAK.BSAIK_BUDAT
			ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
			)
		-- Add exchange rate from company currency to USD
		LEFT JOIN B00_IT_TCURR
			ON A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR
			AND B00_IT_TCURR.TCURR_TCURR  = @currency  
			AND B00_IT_TCURR.TCURR_GDATU = (
				SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
				FROM B00_IT_TCURR
				WHERE A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
						B00_IT_TCURR.TCURR_TCURR  = @currency  AND
						B00_IT_TCURR.TCURR_GDATU <= B04_08_TT_BSIK_BSAK.BSAIK_BUDAT
				ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
				) 
             
		-- Add currency conversion factor for document currency
		LEFT JOIN B00_TCURX TCURX_DOC 
				ON 
				BSAIK_WAERS = TCURX_DOC.TCURX_CURRKEY
             
		-- Add currency conversion factors for company currency
		LEFT JOIN B00_TCURX TCURX_CC     
				ON 
				A_T001.T001_WAERS = TCURX_CC.TCURX_CURRKEY         
 
		-- Add the accounting schemes
		LEFT JOIN B04_07_IT_BSEG_BKPF_ACC_SCH
		ON   BSAIK_BUKRS = B04_07_IT_BSEG_BKPF_ACC_SCH.BSEG_BUKRS AND
				BSAIK_GJAHR = B04_07_IT_BSEG_BKPF_ACC_SCH.BSEG_GJAHR AND
				BSAIK_BELNR = B04_07_IT_BSEG_BKPF_ACC_SCH.BSEG_BELNR
 
       -- Add the controlling area in order to be able to add cost center information		
		LEFT JOIN A_TKA02
			ON A_TKA02.TKA02_BUKRS = BSAIK_BUKRS

	    -- Add cost center information 
		LEFT JOIN B04_02_TT_CSKT_DATBI
			ON A_TKA02.TKA02_KOKRS = B04_02_TT_CSKT_DATBI.CSKT_KOKRS
			AND BSAIK_KOSTL = B04_02_TT_CSKT_DATBI.CSKT_KOSTL
			AND B04_02_TT_CSKT_DATBI.CSKT_DATBI > @downloaddate

		-- Include profit centers descriptions
		-- Thuan update 2024-01-09 link with BSEG_KOKRS
		LEFT JOIN B04_04_TT_CEPCT_UNIQUE
		ON	BSEG_KOKRS = B04_04_TT_CEPCT_UNIQUE.CEPCT_KOKRS AND
			BSAIK_PRCTR = B04_04_TT_CEPCT_UNIQUE.CEPCT_PRCTR

		-- Get posting key description
		LEFT JOIN B00_TBSLT
		ON B00_TBSLT.TBSLT_BSCHL = B04_08_TT_BSIK_BSAK.BSAIK_BSCHL AND
		   B00_TBSLT.TBSLT_UMSKZ = B04_08_TT_BSIK_BSAK.BSAIK_UMSKZ

		--Get special g/l indicator description
		LEFT JOIN A_T074T
		ON A_T074T.T074T_SPRAS IN ('E', 'EN') AND
		   A_T074T.T074T_SHBKZ = B04_08_TT_BSIK_BSAK.BSAIK_UMSKZ AND
		   A_T074T.T074T_KOART = 'K'

		WHERE ISNULL(BSAIK_BSTAT, '') = ''

		/* 
			Step 9.2:
						Add a columns to flag the AP documents which credit vendor and debit customer but the customer and vendor is the same person.

		*/

		EXEC SP_DROPTABLE 'B04_13B_IT_FIN_GL_CHECK_LIST'
		SELECT DISTINCT B04_BSEG_BUKRS, B04_BSEG_GJAHR, B04_BSEG_BELNR, B04_BSEG_KUNNR, B04_BSEG_SHKZG, B04_BSEG_KOART INTO B04_13B_IT_FIN_GL_CHECK_LIST FROM B04_11_IT_FIN_GL
		WHERE B04_BSEG_SHKZG = 'S' AND B04_BSEG_KOART = 'D'
        EXEC sp_CREATE_INDEX 'B04_BSEG_BUKRS, B04_BSEG_GJAHR, B04_BSEG_BELNR, B04_BSEG_KUNNR, B04_BSEG_SHKZG, B04_BSEG_KOART', 'B04_13B_IT_FIN_GL_CHECK_LIST'

        ALTER TABLE B04_10_IT_BSAK_BSIK_AP_ACC_SCH ADD ZF_LIFNR_KUNNR_IS_SAME_FLAG NVARCHAR(1) DEFAULT 'N' WITH VALUES;
		UPDATE B04_10_IT_BSAK_BSIK_AP_ACC_SCH
		SET ZF_LIFNR_KUNNR_IS_SAME_FLAG = 'Y'
		WHERE EXISTS(
			SELECT *
			FROM B04_13B_IT_FIN_GL_CHECK_LIST
			WHERE B04_13B_IT_FIN_GL_CHECK_LIST.B04_BSEG_BUKRS = B04_10_IT_BSAK_BSIK_AP_ACC_SCH.BSAIK_BUKRS AND
			   B04_13B_IT_FIN_GL_CHECK_LIST.B04_BSEG_GJAHR = B04_10_IT_BSAK_BSIK_AP_ACC_SCH.BSAIK_GJAHR AND
			   B04_13B_IT_FIN_GL_CHECK_LIST.B04_BSEG_BELNR = B04_10_IT_BSAK_BSIK_AP_ACC_SCH.BSAIK_BELNR AND
			   B04_13B_IT_FIN_GL_CHECK_LIST.B04_BSEG_KUNNR = B04_10_IT_BSAK_BSIK_AP_ACC_SCH.LFA1_KUNNR
		)
		AND B04_10_IT_BSAK_BSIK_AP_ACC_SCH.BSAIK_SHKZG = 'H' AND ISNULL(B04_10_IT_BSAK_BSIK_AP_ACC_SCH.LFA1_KUNNR, '') <> ''


-- Step 10/ Append BSAD and BSID tables and create a list to which accounting schemes can be added

EXEC sp_droptable 'B04_11_TT_BSID_BSAD'
 
  -- Closed items   
       SELECT
            -- Key that will enable to join to BSEG and back to BSAD
            A_BSAD.BSAD_MANDT AS BSAID_MANDT
            ,A_BSAD.BSAD_BUKRS AS BSAID_BUKRS
            ,A_BSAD.BSAD_GJAHR AS BSAID_GJAHR
            ,A_BSAD.BSAD_BELNR AS BSAID_BELNR
            ,A_BSAD.BSAD_BUZEI AS BSAID_BUZEI
            -- Posting key information that is useful for determining if it is an invoice or payment
            ,A_BSAD.BSAD_BSCHL AS BSAID_BSCHL
			-- Profit center and Cost center information
			,A_BSAD.BSAD_PRCTR AS BSAID_PRCTR
			,A_BSAD.BSAD_KOSTL AS BSAID_KOSTL
            -- debit credit indicator that is useful for determining if it is an invoice or payment
            ,A_BSAD.BSAD_SHKZG AS BSAID_SHKZG       
            -- Document type that is useful for determining if is an invoice or a payment
            ,A_BSAD.BSAD_BLART AS BSAID_BLART
            -- Information for calculation of value fields as below
            ,A_BSAD.BSAD_WAERS AS BSAID_WAERS
            ,A_BSAD.BSAD_DMBTR AS BSAID_DMBTR
			,A_BSAD.BSAD_DMBE2 AS BSAID_DMBE2
			,A_BSAD.BSAD_DMBE3 AS BSAID_DMBE3
			  -- Other fields needed for AP cube:
			,A_BSAD.BSAD_UMSKS As BSAID_UMSKS
			,A_BSAD.BSAD_UMSKZ As BSAID_UMSKZ
			,A_BSAD.BSAD_AUGDT As BSAID_AUGDT
			,A_BSAD.BSAD_AUGBL As BSAID_AUGBL
			,A_BSAD.BSAD_ZUONR As BSAID_ZUONR
 			,A_BSAD.BSAD_BUDAT As BSAID_BUDAT
			,A_BSAD.BSAD_BLDAT As BSAID_BLDAT
			,A_BSAD.BSAD_CPUDT As BSAID_CPUDT
			,A_BSAD.BSAD_XBLNR As BSAID_XBLNR
			,A_BSAD.BSAD_MONAT As BSAID_MONAT
			,A_BSAD.BSAD_ZUMSK As BSAID_ZUMSK
			,A_BSAD.BSAD_GSBER As BSAID_GSBER
			,A_BSAD.BSAD_WRBTR As BSAID_WRBTR
			,A_BSAD.BSAD_MWSKZ As BSAID_MWSKZ
			,A_BSAD.BSAD_MWSTS As BSAID_MWSTS
			,A_BSAD.BSAD_WMWST As BSAID_WMWST
			,A_BSAD.BSAD_SGTXT As BSAID_SGTXT
			,A_BSAD.BSAD_AUFNR As BSAID_AUFNR
			,A_BSAD.BSAD_HKONT As BSAID_HKONT
			,A_BSAD.BSAD_KUNNR AS BSAID_KUNNR
			,A_BSAD.BSAD_ZFBDT As BSAID_ZFBDT
			,A_BSAD.BSAD_ZTERM As BSAID_ZTERM
			,A_BSAD.BSAD_ZBD1T As BSAID_ZBD1T
			,A_BSAD.BSAD_ZBD2T As BSAID_ZBD2T
			,A_BSAD.BSAD_ZBD3T As BSAID_ZBD3T
			,A_BSAD.BSAD_ZBD1P As BSAID_ZBD1P
			,A_BSAD.BSAD_ZBD2P As BSAID_ZBD2P
			,A_BSAD.BSAD_SKFBT As BSAID_SKFBT
			,A_BSAD.BSAD_SKNTO As BSAID_SKNTO
			,A_BSAD.BSAD_WSKTO As BSAID_WSKTO
			,A_BSAD.BSAD_ZLSCH As BSAID_ZLSCH
			,A_BSAD.BSAD_ZLSPR As BSAID_ZLSPR
			,A_BSAD.BSAD_BSTAT As BSAID_BSTAT
			,A_BSAD.BSAD_PROJK As BSAID_PROJK
			,A_BSAD.BSAD_XRAGL As BSAID_XRAGL
			,A_BSAD.BSAD_XNEGP As BSAID_XNEGP
			,A_BSAD.BSAD_AUGGJ As BSAID_AUGGJ
			,A_BSAD.BSAD_REBZG As BSAID_REBZG
			,A_BSAD.BSAD_VBELN AS BSAID_VBELN
			,A_BSAD.BSAD_XANET AS BSAID_XANET
			-- Add difference in number of days between input date and matching date
			,DATEDIFF(d,A_BSAD.BSAD_CPUDT,A_BSAD.BSAD_AUGDT) AS ZF_BSAID_CPUDT_AGE_DAYS
			-- Add indicator to show if the document is open or closed based on table name
			,'Closed' AS ZF_BSAID_OPEN_CLOSED
			-- Add description of debit/credit indicator
			, CASE 
				WHEN BSAD_SHKZG='H' THEN 'Credit' 
				ELSE 'Debit' 
			  END AS ZF_BSAID_SHKZG_DESC 		
			  -- Add integer value for debit/credit indicator
			, CASE 
				WHEN BSAD_SHKZG='H' THEN -1 
				ELSE 1 END 
			  AS ZF_BSAID_SHKZG_INTEGER
			  -- Add matching year-month
			,CAST(YEAR(BSAD_AUGDT) AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(MONTH(BSAD_AUGDT) AS VARCHAR(2)),2) AS ZF_BSAD_AUGDT_YEAR_MNTH
			--Add actual discount amount
			,CASE 
				WHEN BSAD_SKFBT = 0  THEN 0 
				ELSE ABS(ROUND(BSAD_WSKTO/BSAD_SKFBT,3) * 100)
			END AS ZF_BSAID_WSKTO_SKBFT
			,CASE 
	   		WHEN A_BSAD.BSAD_SKFBT = 0 THEN 0 ELSE ROUND(A_BSAD.BSAD_WSKTO/A_BSAD.BSAD_SKFBT,3) * 100 * CASE WHEN A_BSAD.BSAD_SHKZG='H' THEN -1 ELSE 1 END 		
			END	AS ZF_BSAID_WSKTO_ACTUAL_DISCOUNT
			,NULL ZF_BSAID_AUGDT_CLR_PER_YR
       INTO B04_11_TT_BSID_BSAD
       FROM A_BSAD
	   WHERE NOT ((BSAD_BUKRS = 'TR10' OR BSAD_BUKRS = 'TR20') AND BSAD_MONAT = 13)
	   AND           BSAD_BUDAT    >= @date1
	   AND            BSAD_BUDAT    <= @date2
	   
  -- Open items
   INSERT INTO B04_11_TT_BSID_BSAD
       SELECT
              -- Key that will enable to join to BSEG and back to BSAD/BSID
              A_BSID.BSID_MANDT AS BSAID_MANDT
              ,A_BSID.BSID_BUKRS AS BSAID_BUKRS
              ,A_BSID.BSID_GJAHR AS BSAID_GJAHR
              ,A_BSID.BSID_BELNR AS BSAID_BELNR
              ,A_BSID.BSID_BUZEI AS BSAID_BUZEI
              -- Posting key information that is useful for determining if it is an invoice or payment
              ,A_BSID.BSID_BSCHL AS BSAID_BSCHL
			-- Profit center and Cost center information
			,A_BSID.BSID_PRCTR AS BSAID_PRCTR
			,A_BSID.BSID_KOSTL AS BSAID_KOSTL
              -- Debit credit indicator that is useful for determining if it is an invoice or payment
              ,A_BSID.BSID_SHKZG AS BSAID_SHKZG
              -- Document type that is useful for determining if is an invoice or a payment
              ,A_BSID.BSID_BLART AS BSAID_BLART
              -- Supplier number in order to be able to add the supplier account group text
              -- which will be useful in order to know if it is for interco, employee or regular supplier
              -- Information for calculation of value fields as below
              ,A_BSID.BSID_WAERS AS BSAID_WAERS
              ,A_BSID.BSID_DMBTR AS BSAID_DMBTR
			  ,A_BSID.BSID_DMBE2 AS BSAID_DMBE2
			  ,A_BSID.BSID_DMBE3 AS BSAID_DMBE3
			  -- Other fields needed for AP cube:
			,A_BSID.BSID_UMSKS As BSAID_UMSKS
			,A_BSID.BSID_UMSKZ As BSAID_UMSKZ
			,A_BSID.BSID_AUGDT As BSAID_AUGDT
			,A_BSID.BSID_AUGBL As BSAID_AUGBL
			,A_BSID.BSID_ZUONR As BSAID_ZUONR
 			,A_BSID.BSID_BUDAT As BSAID_BUDAT
			,A_BSID.BSID_BLDAT As BSAID_BLDAT
			,A_BSID.BSID_CPUDT As BSAID_CPUDT
			,A_BSID.BSID_XBLNR As BSAID_XBLNR
			,A_BSID.BSID_MONAT As BSAID_MONAT
			,A_BSID.BSID_ZUMSK As BSAID_ZUMSK
			,A_BSID.BSID_GSBER As BSAID_GSBER
			,A_BSID.BSID_WRBTR As BSAID_WRBTR
			,A_BSID.BSID_MWSKZ As BSAID_MWSKZ
			,A_BSID.BSID_MWSTS As BSAID_MWSTS
			,A_BSID.BSID_WMWST As BSAID_WMWST
			,A_BSID.BSID_SGTXT As BSAID_SGTXT
			,A_BSID.BSID_AUFNR As BSAID_AUFNR
			,A_BSID.BSID_HKONT As BSAID_HKONT
			,A_BSID.BSID_KUNNR AS BSAID_KUNNR
			,A_BSID.BSID_ZFBDT As BSAID_ZFBDT
			,A_BSID.BSID_ZTERM As BSAID_ZTERM
			,A_BSID.BSID_ZBD1T As BSAID_ZBD1T
			,A_BSID.BSID_ZBD2T As BSAID_ZBD2T
			,A_BSID.BSID_ZBD3T As BSAID_ZBD3T
			,A_BSID.BSID_ZBD1P As BSAID_ZBD1P
			,A_BSID.BSID_ZBD2P As BSAID_ZBD2P
			,A_BSID.BSID_SKFBT As BSAID_SKFBT
			,A_BSID.BSID_SKNTO As BSAID_SKNTO
			,A_BSID.BSID_WSKTO As BSAID_WSKTO
			,A_BSID.BSID_ZLSCH As BSAID_ZLSCH
			,A_BSID.BSID_ZLSPR As BSAID_ZLSPR
			,A_BSID.BSID_BSTAT As BSAID_BSTAT
			,A_BSID.BSID_PROJK As BSAID_PROJK
			,A_BSID.BSID_XRAGL As BSAID_XRAGL
			,A_BSID.BSID_XNEGP As BSAID_XNEGP
			,A_BSID.BSID_AUGGJ As BSAID_AUGGJ
			,A_BSID.BSID_REBZG As BSAID_REBZG
			,A_BSID.BSID_VBELN AS BSAID_VBELN
			,A_BSID.BSID_XANET AS BSAID_XANET
			-- Add difference in number of days between input date and matching date
			,DATEDIFF(d,A_BSID.BSID_CPUDT,A_BSID.BSID_AUGDT) AS ZF_BSAID_CPUDT_AGE_DAYS
			-- Add indicator to show if the document is open or closed based on table name
			,'Open' AS ZF_BSAID_OPEN_CLOSED
			-- Add description of debit/credit indicator
			, CASE 
				WHEN BSID_SHKZG='H' THEN 'Credit' 
				ELSE 'Debit' 
			  END AS ZF_BSAID_SHKZG_DESC 		
			  -- Add integer value for debit/credit indicator
			, CASE 
				WHEN BSID_SHKZG='H' THEN -1 
				ELSE 1 END 
			  AS ZF_BSAID_SHKZG_INTEGER
			  -- Add matching year-month
			,CAST(YEAR(BSID_AUGDT) AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(MONTH(BSID_AUGDT) AS VARCHAR(2)),2) AS ZF_BSID_AUGDT_YEAR_MNTH
			--Add actual discount amount
			,CASE 
				WHEN BSID_SKFBT = 0  THEN 0 
				ELSE ABS(ROUND(BSID_WSKTO/BSID_SKFBT,3) * 100)
			END AS ZF_BSAID_WSKTO_SKBFT
			,CASE 
			WHEN A_BSID.BSID_SKFBT = 0 THEN 0 ELSE ROUND(A_BSID.BSID_WSKTO/A_BSID.BSID_SKFBT,3) * 100 * CASE WHEN A_BSID.BSID_SHKZG='H' THEN -1 ELSE 1 END 		
			END	AS ZF_BSAID_WSKTO_ACTUAL_DISCOUNT
			,NULL ZF_BSAID_AUGDT_CLR_PER_YR
       FROM A_BSID
       -- Insert only records not already in BSAD (e.g. cleared while extracting data)
       LEFT JOIN A_BSAD
              ON	(A_BSID.BSID_BUKRS = A_BSAD.BSAD_BUKRS) AND
                    (A_BSID.BSID_GJAHR = A_BSAD.BSAD_GJAHR) AND
                    (A_BSID.BSID_BELNR = A_BSAD.BSAD_BELNR) AND
                    (A_BSID.BSID_BUZEI = A_BSAD.BSAD_BUZEI)
       WHERE A_BSAD.BSAD_BELNR IS NULL
			AND NOT ((BSID_BUKRS = 'TR10' OR BSID_BUKRS = 'TR20') AND BSID_MONAT = 13)
			AND  BSID_BUDAT <= @date2

 
-- Step 11/ Add the supplier account group and the document type description
--         Add value fields so that we can see the total value per account type
--         Add the accounting schmes


EXEC SP_DROPTABLE    'B04_12_IT_BSAD_BSID_AR_ACC_SCH'
 
       SELECT B04_11_TT_BSID_BSAD.*
	   ,IIF(BSAID_AUGBL = BSAID_BELNR, 1, 0) ZF_DOC_CLEARING_FLAG
	   -- Header information
	   ,A_BKPF.BKPF_AWTYP
	   ,B00_TBSLT.TBSLT_LTEXT
	   ,A_T074T.T074T_LTEXT

	   -- Local currency code
       ,A_T001.T001_WAERS
	   -- Signed amount - values are inversed so that total spend shows as positive on the dashboard
       ,CONVERT(MONEY,BSAID_DMBTR * COALESCE(TCURX_CC.TCURX_FACTOR,1) * IIF(BSAID_SHKZG = 'H',-1,1))                                         AS ZF_BSAID_DMBTR_S
	   -- Custom currency code
       ,@currency      AS GLOBALS_CURRENCY
	   -- Signed amount in custom currency - values are inversed so that total spend shows as positive on the dashboard                                                                                                                                                                                AS AM_GLOBALS_CURRENCY
       ,CONVERT(MONEY,BSAID_DMBTR * COALESCE(TCURX_CC.TCURX_FACTOR,1) * IIF(BSAID_SHKZG = 'H', -1,1)  *  COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1))     AS ZF_BSAID_DMBTR_S_CUC
	   ,BSAID_DMBE2 * IIF(BSAID_SHKZG = 'H', -1,1) ZF_BSAID_DMBE2_S
	   ,BSAID_DMBE3 * IIF(BSAID_SHKZG = 'H', -1,1) ZF_BSAID_DMBE3_S
	   -- Document type description
       ,B00_T003T.T003T_LTEXT
	   --Accounting schemes:
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.BKPF_TCODE, '_') BKPF_TCODE
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_DEBIT_ACCOUNT_TYPES, '_') ZF_DEBIT_ACCOUNT_TYPES
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_CREDIT_ACCOUNT_TYPES, '_') ZF_CREDIT_ACCOUNT_TYPES
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_DEBIT_HKONT_LIST, '_') ZF_DEBIT_HKONT_LIST
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_CREDIT_HKONT_LIST, '_') ZF_CREDIT_HKONT_LIST
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_DEBIT_SKAT_TXT20_LIST, '_') ZF_DEBIT_SKAT_TXT20_LIST
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_CREDIT_SKAT_TXT20_LIST, '_') ZF_CREDIT_SKAT_TXT20_LIST
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_DEBIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST, '_') AS ZF_DEBIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_CREDIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST, '_') AS ZF_CREDIT_T012K_FEBKO_SKB1_HBKID_XGKON_FLAG_LIST
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_CREDIT_SKA1_GVTYP_FLAG_LIST, '_') AS ZF_CREDIT_SKA1_GVTYP_FLAG_LIST
		,ISNULL(B04_07_IT_BSEG_BKPF_ACC_SCH.ZF_DEBIT_SKA1_GVTYP_FLAG_LIST, '_') AS ZF_DEBIT_SKA1_GVTYP_FLAG_LIST
		,COALESCE(CASE 
			WHEN B04_02_TT_CSKT_DATBI.CSKT_LTEXT ='' OR  B04_02_TT_CSKT_DATBI.CSKT_LTEXT IS NULL THEN 'Not assigned'
			ELSE BSAID_KOSTL 
		 END,'Not assigned') ZF_BSAID_KOSTL
		-- Cost center description
		,COALESCE(CASE 
			WHEN B04_02_TT_CSKT_DATBI.CSKT_LTEXT ='' OR  B04_02_TT_CSKT_DATBI.CSKT_LTEXT IS NULL THEN 'Not assigned'
			ELSE B04_02_TT_CSKT_DATBI.CSKT_LTEXT 
		 END,'Not assigned') ZF_CSKT_LTEXT,
		 CEPCT_MCTXT,
		 KNA1_KTOKD,
		 KNA1_LIFNR,
		 T077X_TXT30
       INTO B04_12_IT_BSAD_BSID_AR_ACC_SCH
       FROM B04_11_TT_BSID_BSAD

	   --Get header informationp for BKPF table
	   LEFT JOIN A_BKPF
	   ON	B04_11_TT_BSID_BSAD.BSAID_BUKRS = A_BKPF.BKPF_BUKRS AND
			B04_11_TT_BSID_BSAD.BSAID_GJAHR = A_BKPF.BKPF_GJAHR AND 
			B04_11_TT_BSID_BSAD.BSAID_BELNR = A_BKPF.BKPF_BELNR
	   -- Thuan update 2024-01-09 to get BSEG_KOKRS from BSEG table
	   LEFT JOIN A_BSEG
			ON B04_11_TT_BSID_BSAD.BSAID_BUKRS = A_BSEG.BSEG_BUKRS AND
				B04_11_TT_BSID_BSAD.BSAID_GJAHR = A_BSEG.BSEG_GJAHR AND
				B04_11_TT_BSID_BSAD.BSAID_BELNR = A_BSEG.BSEG_BELNR AND 
				B04_11_TT_BSID_BSAD.BSAID_BUZEI = A_BSEG.BSEG_BUZEI

	   --Get supplier information from the supplier master data table
	   LEFT JOIN A_KNA1 
		  ON KNA1_KUNNR = BSAID_KUNNR
       -- Add customer account group
	   LEFT JOIN B00_T077X
          ON A_KNA1.KNA1_KTOKD = B00_T077X.T077X_KTOKD
	   -- Add document type description
       LEFT JOIN B00_T003T
           ON B04_11_TT_BSID_BSAD.BSAID_BLART = (B00_T003T.T003T_BLART)
       -- Obtain company description and house currency
       LEFT JOIN A_T001
              ON  BSAID_BUKRS = A_T001.T001_BUKRS
     	-- Add currency factor from company currency to USD

		LEFT JOIN B00_IT_TCURF
		ON A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR
		AND B00_IT_TCURF.TCURF_TCURR  = @currency  
		AND B00_IT_TCURF.TCURF_GDATU = (
			SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
			FROM B00_IT_TCURF
			WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
					B00_IT_TCURF.TCURF_TCURR  = @currency  AND
					B00_IT_TCURF.TCURF_GDATU <= B04_11_TT_BSID_BSAD.BSAID_BUDAT
			ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
			)
		-- Add exchange rate from company currency to USD
		LEFT JOIN B00_IT_TCURR
			ON A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR
			AND B00_IT_TCURR.TCURR_TCURR  = @currency  
			AND B00_IT_TCURR.TCURR_GDATU = (
				SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
				FROM B00_IT_TCURR
				WHERE A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
						B00_IT_TCURR.TCURR_TCURR  = @currency  AND
						B00_IT_TCURR.TCURR_GDATU <= B04_11_TT_BSID_BSAD.BSAID_BUDAT
				ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
				) 
             
		-- Add currency conversion factor for document currency
		LEFT JOIN B00_TCURX TCURX_DOC 
				ON 
				 BSAID_WAERS = TCURX_DOC.TCURX_CURRKEY

		-- Add currency conversion factors for company currency
		LEFT JOIN B00_TCURX TCURX_CC     
				ON 
				 A_T001.T001_WAERS = TCURX_CC.TCURX_CURRKEY 
				 
		-- Add the accounting schemes
		LEFT JOIN B04_07_IT_BSEG_BKPF_ACC_SCH
		ON   BSAID_BUKRS = B04_07_IT_BSEG_BKPF_ACC_SCH.BSEG_BUKRS AND
				BSAID_GJAHR = B04_07_IT_BSEG_BKPF_ACC_SCH.BSEG_GJAHR AND
				BSAID_BELNR = B04_07_IT_BSEG_BKPF_ACC_SCH.BSEG_BELNR

       -- Add the controlling area in order to be able to add cost center information		
		LEFT JOIN A_TKA02
			ON A_TKA02.TKA02_BUKRS = BSAID_BUKRS

	    -- Add cost center information 
		LEFT JOIN B04_02_TT_CSKT_DATBI
			ON A_TKA02.TKA02_KOKRS = B04_02_TT_CSKT_DATBI.CSKT_KOKRS
			AND BSAID_KOSTL = B04_02_TT_CSKT_DATBI.CSKT_KOSTL
			AND B04_02_TT_CSKT_DATBI.CSKT_DATBI > @downloaddate

		-- Thuan update 2024-01-09 link with BSEG_KOKRS
		LEFT JOIN B04_04_TT_CEPCT_UNIQUE
		ON	BSEG_KOKRS = B04_04_TT_CEPCT_UNIQUE.CEPCT_KOKRS AND
			BSAID_PRCTR = B04_04_TT_CEPCT_UNIQUE.CEPCT_PRCTR 

		-- Get posting key description
		LEFT JOIN B00_TBSLT
		ON B00_TBSLT.TBSLT_BSCHL = B04_11_TT_BSID_BSAD.BSAID_BSCHL AND
		   B00_TBSLT.TBSLT_UMSKZ = B04_11_TT_BSID_BSAD.BSAID_UMSKZ

		--Get special g/l indicator description
		LEFT JOIN A_T074T
		ON A_T074T.T074T_SPRAS IN ('E', 'EN') AND
		   A_T074T.T074T_SHBKZ = B04_11_TT_BSID_BSAD.BSAID_UMSKZ AND
		   A_T074T.T074T_KOART = 'D'

		WHERE ISNULL(BSAID_BSTAT, '') = ''

	/* 
			Step 11.1:
						Add a columns to flag the AR documents which debit customer and credit vendor but the customer and vendor is the same person.
	*/
		EXEC SP_DROPTABLE 'B04_13B_IT_FIN_GL_CHECK_LIST'
		SELECT DISTINCT B04_BSEG_BUKRS, B04_BSEG_GJAHR, B04_BSEG_BELNR, B04_BSEG_KUNNR, B04_BSEG_SHKZG, B04_BSEG_KOART INTO B04_13B_IT_FIN_GL_CHECK_LIST FROM B04_11_IT_FIN_GL
		WHERE B04_BSEG_SHKZG = 'H' AND B04_BSEG_KOART = 'K'


		ALTER TABLE B04_12_IT_BSAD_BSID_AR_ACC_SCH ADD ZF_LIFNR_KUNNR_IS_SAME_FLAG NVARCHAR(1) DEFAULT 'N' WITH VALUES;
		UPDATE B04_12_IT_BSAD_BSID_AR_ACC_SCH
		SET ZF_LIFNR_KUNNR_IS_SAME_FLAG = 'Y'
		WHERE EXISTS(
			SELECT TOP 1 1
			FROM B04_11_IT_FIN_GL
			WHERE B04_11_IT_FIN_GL.B04_BSEG_BUKRS = B04_12_IT_BSAD_BSID_AR_ACC_SCH.BSAID_BUKRS AND
			   B04_11_IT_FIN_GL.B04_BSEG_GJAHR = B04_12_IT_BSAD_BSID_AR_ACC_SCH.BSAID_GJAHR AND
			   B04_11_IT_FIN_GL.B04_BSEG_BELNR = B04_12_IT_BSAD_BSID_AR_ACC_SCH.BSAID_BELNR AND
			   B04_11_IT_FIN_GL.B04_BSEG_LIFNR = B04_12_IT_BSAD_BSID_AR_ACC_SCH.KNA1_LIFNR AND
			   B04_11_IT_FIN_GL.B04_BSEG_SHKZG = 'H' AND B04_11_IT_FIN_GL.B04_BSEG_KOART = 'K'
			   AND ISNULL(B04_BSEG_LIFNR, '') <> ''
		)
		AND B04_12_IT_BSAD_BSID_AR_ACC_SCH.BSAID_SHKZG = 'S' 

		
--/*Drop temporary tables*/
--EXEC SP_REMOVE_TABLES '%[_]TT[_]%'
EXEC sp_RENAME_FIELD 'B04B_', 'B04_12_IT_BSAD_BSID_AR_ACC_SCH'
EXEC SP_REMOVE_TABLES '%_TT_%'
/* log cube creation*/
 
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','B04_05_IT_FIN_GL',(SELECT COUNT(*) FROM B04_11_IT_FIN_GL)
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','B04_07_IT_BSEG_BKPF_ACC_SCH',(SELECT COUNT(*) FROM B04_07_IT_BSEG_BKPF_ACC_SCH)
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','B04_10_IT_BSAK_BSIK_AP_ACC_SCH',(SELECT COUNT(*) FROM B04_10_IT_BSAK_BSIK_AP_ACC_SCH)
 
/* log end of procedure*/

 
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL
GO
