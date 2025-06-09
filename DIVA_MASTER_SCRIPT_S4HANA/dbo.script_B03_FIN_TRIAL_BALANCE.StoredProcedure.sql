USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--ALTER PROCEDURE [dbo].[B03_FIN_TRIAL_BALANCE]
CREATE   PROCEDURE [dbo].[script_B03_FIN_TRIAL_BALANCE]
WITH EXECUTE AS CALLER
AS

--DYNAMIC_SCRIPT_START

/*Purpose of the query:
- Obtain a detailed trial balance per month (with the month in a column rather than one column per month).
Whereas the cube FIN-02-BAL takes the information from GLT0 in the FROM clause this query uses SKB1 (FIN-03-GLM) in the FROM and B00_GL rather than GLT0.
B00_GL is a view of GLT0 to which the field MONAT has been added, to show the values that were in a column for each month as values htat are in a line for each month.
Hence the name 'unpivot'.
Result:
--This version of the balance includes the accounts that are not in the trial balance.  
--This version of the balance multiplies out the COA by all the months found in B00_GL ---- duplicates on the key in this case therefore accepted  */

/* Initiate the log */  
--Create database log table if it does not exist
IF OBJECT_ID('_DatabaseLogTable', 'U') IS NULL BEGIN CREATE TABLE [dbo].[_DatabaseLogTable] ([Database] nvarchar(max) NULL,[Object] nvarchar(max) NULL,[Object Type] nvarchar(max) NULL,[User] nvarchar(max) NULL,[Date] date NULL,[Time] time NULL,[Description] nvarchar(max) NULL,[Table] nvarchar(max),[Rows] int) END

--Log start of procedure
INSERT INTO [dbo].[_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure started',NULL,NULL


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

/*Change history comments*/

/*
    Title			:	script_B03_FIN_TRIAL_BALANCE
    Description		:	Balance totals as taken from table

     
    --------------------------------------------------------------
    Update history
    --------------------------------------------------------------
    Date		    | Who   |	Description
	30-03-2016		  MW	    Initial Sony version
	18-04-2016		  EH	    Updated code for understanding
	14-02-2017		  JSM   	Added database log
	19-03-2017		  CW        Update and standardisation for SID
	08-06-2017		  AJ 	 	Updated scripts with new naming convention
	24-03-2022		 Thuan		Remove MANDT field in join
*/


	/*Test mode*/
	SET ROWCOUNT @LIMIT_RECORDS


	/*In case we are in test mode according to the globals table*/

	/*
	--Step 1
	-- Obtain a trial balance that shows one column for the month, rather than the months in columns
	-- The data is taken from the chart of accounts, with left join on trial balance, in order to include
	--    accounts that are found in the chart of accounts but not in the trial balance
	-- Hard-coded values:
					Trial balance record type (TB_RRCTY) = 0
					Trial balance ledger (TB_RLDNR) = 00
	-- Rows are being removed due to the following filters (WHERE): 
					Trial balance record type (TB_RRCTY) = 0 (meaning actual rather than planned)
					Fiscal year is (@year, @year-1, @year-2, @year-3) - meaning only take the Trial balance for current and prior 3 fiscal years
					Selection on ledger (TB_RLDNR) = 00
	-- Note - use of TCURX table is incorrect for JPY for India
	--Fields are being added from other SAP tables as mentioned in JOIN clauses below
	--Fields are being calculated as mentioned in SELECT clause below
	*/


	EXEC SP_DROPTABLE 	'B03_01_IT_FIN_TB' 
	SELECT
			B02_02_IT_FIN_COA.B02_ACDOCA_RCLNT AS ACDOCA_RCLNT,
			B02_02_IT_FIN_COA.B02_ACDOCA_KTOPL AS ACDOCA_KTOPL,
			B02_02_IT_FIN_COA.B02_ACDOCA_RBUKRS AS ACDOCA_RBUKRS, 
			B02_02_IT_FIN_COA.B02_T001_BUTXT AS T001_BUTXT, 
			ACDOCA_RBUSA,
			ACDOCA_RACCT,
			B02_02_IT_FIN_COA.B02_SKAT_TXT50 AS SKAT_TXT50, 
			B02_02_IT_FIN_COA.B02_TANGO_ACCT AS TANGO_ACCT,
			B02_02_IT_FIN_COA.B02_TANGO_ACCT_TXT AS TANGO_ACCT_TXT,
			B02_02_IT_FIN_COA.B02_SKB1_MITKZ AS SKB1_MITKZ,
			B02_02_IT_FIN_COA.B02_SKA1_XBILK AS SKA1_XBILK,
			T001_XNEGP,
			ACDOCA_BSTAT,
			ACDOCA_BLART,
			A_T003T.T003T_LTEXT,
			ACDOCA_UMSKZ,
			ACDOCA_KOKRS,
			ZF_ACDOCA_BUZEI_ZERO_FLAG,
			DD07T_DDTEXT ZF_ACDOCA_BSTAT_DESC,
			ISNULL(A_T074T.T074T_LTEXT,'') ZF_ACDOCA_UMSKZ_DESC,
			ACDOCA_RYEAR, 
			ACDOCA_MONAT,
			ISNULL(ACDOCA_RRCTY,'') AS ACDOCA_RRCTY,
			ISNULL(ACDOCA_RLDNR, '') AS ACDOCA_RLDNR,

			-- Add Posting month description
			CASE
				WHEN CAST(ACDOCA_MONAT AS INT) IN (13,14,15,16) THEN 'Special Periods'
				WHEN CAST(ACDOCA_MONAT AS INT) = 0 THEN 'Open'
				ELSE B00_T009B.T247_KTX
			END AS [ZF_ACDOCA_BUDAT_MONTH_DESC], 

			-- Add Quarter
			CASE	
				WHEN CAST(ACDOCA_MONAT AS INT) = 0 THEN 'Open'
				WHEN CAST(ACDOCA_MONAT AS INT) IN (1, 2, 3) THEN 'Q1'
				WHEN CAST(ACDOCA_MONAT AS INT) IN (4, 5, 6) THEN 'Q2'
				WHEN CAST(ACDOCA_MONAT AS INT) IN (7, 8, 9) THEN 'Q3'
				WHEN CAST(ACDOCA_MONAT AS INT) IN (10, 11, 12) THEN 'Q4'
				ELSE 'Special Quater' 
			END AS ZF_ACDOCA_MONAT_FQ,
			ACDOCA_RYEAR + '-' + ACDOCA_MONAT AS [ZF_ACDOCA_RYEAR_MONAT],

			-- Add debit/credit
			CASE ACDOCA_DRCRK
				WHEN 'S' THEN 'Debit'
				WHEN 'H' THEN 'Credit'
			END											AS [ZF_ACDOCA_DRCRK_DESC], 
			
			ACDOCA_RHCUR,

			-- Add opening balance
			CASE 
				WHEN CAST(ACDOCA_MONAT AS INT) = 0  THEN CONVERT(money, ACDOCA_HSL * ISNULL(B00_TCURX_HSL.TCURX_FACTOR,1))  
				WHEN CAST(ACDOCA_MONAT AS INT) <> 0 THEN 0
			END  AS ZF_ACDOCA_HSL_OPENING_BAL,

			-- Add debit movements
			CASE 
				WHEN CAST(ACDOCA_MONAT AS INT) = 0  OR ACDOCA_DRCRK <> 'S' THEN 0 
				WHEN CAST(ACDOCA_MONAT AS INT) <> 0 AND ACDOCA_DRCRK = 'S' THEN CONVERT(money, ACDOCA_HSL * ISNULL(B00_TCURX_HSL.TCURX_FACTOR,1))
			END  AS ZF_ACDOCA_HSL_DEBIT_MOV,

			-- Add credit movements
			CASE 
				WHEN CAST(ACDOCA_MONAT AS INT) = 0  OR ACDOCA_DRCRK <> 'H' THEN 0 
				WHEN CAST(ACDOCA_MONAT AS INT) <> 0 AND ACDOCA_DRCRK = 'H' THEN CONVERT(money, ACDOCA_HSL * ISNULL(B00_TCURX_HSL.TCURX_FACTOR,1))
			END  AS ZF_ACDOCA_HSL_CREDIT_MOV,

			-- Add total movements
			CONVERT(money, ACDOCA_HSL * ISNULL(B00_TCURX_HSL.TCURX_FACTOR,1)) AS ZF_ACDOCA_HSL_TOT_MOV,

			@currency									AS GLOBALS_PARAMETER_CURR,

			-- Add opening balance(custom)
			CASE 
				WHEN CAST(ACDOCA_MONAT AS INT) = 0  THEN CONVERT(money, ACDOCA_KSL * ISNULL(B00_TCURX_KSL.TCURX_FACTOR,1) )
				WHEN CAST(ACDOCA_MONAT AS INT) <> 0 THEN 0
			END  AS ZF_ACDOCA_HSL_OPENING_BAL_CUC,

			-- Add debit movements (custom)
			CASE 
				WHEN CAST(ACDOCA_MONAT AS INT) = 0  OR ACDOCA_DRCRK <> 'S' THEN 0 
				WHEN CAST(ACDOCA_MONAT AS INT) <> 0 AND ACDOCA_DRCRK = 'S' THEN CONVERT(money, ACDOCA_KSL * ISNULL(B00_TCURX_KSL.TCURX_FACTOR,1) ) 
			END  AS ZF_ACDOCA_HSL_DEBIT_MOV_CUC,

			-- Add Credit movements (Custom)
			CASE 
				WHEN CAST(ACDOCA_MONAT AS INT) = 0  OR ACDOCA_DRCRK <> 'H' THEN 0 
				WHEN CAST(ACDOCA_MONAT AS INT) <> 0 AND ACDOCA_DRCRK = 'H' THEN CONVERT(money, ACDOCA_KSL * ISNULL(B00_TCURX_KSL.TCURX_FACTOR,1))
			END  AS ZF_ACDOCA_HSL_CREDIT_MOV_CUC,

			-- Add Total movements (Custom)
			CONVERT(money, ACDOCA_KSL * ISNULL(B00_TCURX_KSL.TCURX_FACTOR,1)) AS ZF_ACDOCA_HSL_TOT_MOV_CUC,

			-- Add opening balance(custom)
			CASE 
				WHEN CAST(ACDOCA_MONAT AS INT) = 0 THEN CONVERT(money, ACDOCA_KSL * ISNULL(B00_TCURX_KSL.TCURX_FACTOR,1))
				WHEN CAST(ACDOCA_MONAT AS INT) <> 0 THEN 0
			END ZF_ACDOCA_KSL_OPENING_BAL,

			-- Add debit movements (custom)
			CASE 
				WHEN CAST(ACDOCA_MONAT AS INT) = '0'  OR ACDOCA_DRCRK <> 'S' THEN 0 
				WHEN CAST(ACDOCA_MONAT AS INT) <> '0' AND ACDOCA_DRCRK = 'S' THEN CONVERT(money, ACDOCA_KSL * ISNULL(B00_TCURX_KSL.TCURX_FACTOR,1))
			END ZF_ACDOCA_KSL_DEBIT_MOV,

			-- Add Credit movements (Custom)
			CASE 
				WHEN CAST(ACDOCA_MONAT AS INT) = 0  OR ACDOCA_DRCRK <> 'H' THEN 0 
				WHEN CAST(ACDOCA_MONAT AS INT) <> 0 AND ACDOCA_DRCRK = 'H' THEN CONVERT(money, ACDOCA_KSL * ISNULL(B00_TCURX_KSL.TCURX_FACTOR,1))
			END ZF_ACDOCA_KSL_CREDIT_MOV,

			-- Add Total movements (Custom)
			CONVERT(money, ACDOCA_KSL * ISNULL(B00_TCURX_KSL.TCURX_FACTOR,1))  ZF_ACDOCA_KSL_TOT_MOV,
			-- Update OSL value 

			-- Add opening balance(OSL)
			CASE 
				WHEN CAST(ACDOCA_MONAT AS INT) = 0 THEN CONVERT(money, ACDOCA_OSL * ISNULL(B00_TCURX_OSL.TCURX_FACTOR,1))
				WHEN CAST(ACDOCA_MONAT AS INT) <> 0 THEN 0
			END ZF_ACDOCA_OSL_OPENING_BAL,

			-- Add debit movements (OSL)
			CASE 
				WHEN CAST(ACDOCA_MONAT AS INT) = '0'  OR ACDOCA_DRCRK <> 'S' THEN 0 
				WHEN CAST(ACDOCA_MONAT AS INT) <> '0' AND ACDOCA_DRCRK = 'S' THEN CONVERT(money, ACDOCA_OSL * ISNULL(B00_TCURX_OSL.TCURX_FACTOR,1))
			END ZF_ACDOCA_OSL_DEBIT_MOV,

			-- Add Credit movements (OSL)
			CASE 
				WHEN CAST(ACDOCA_MONAT AS INT) = 0  OR ACDOCA_DRCRK <> 'H' THEN 0 
				WHEN CAST(ACDOCA_MONAT AS INT) <> 0 AND ACDOCA_DRCRK = 'H' THEN CONVERT(money, ACDOCA_OSL * ISNULL(B00_TCURX_OSL.TCURX_FACTOR,1))
			END ZF_ACDOCA_OSL_CREDIT_MOV,

			-- Add Total movements (OSL)
			CONVERT(money, ACDOCA_OSL * ISNULL(B00_TCURX_OSL.TCURX_FACTOR,1))  ZF_ACDOCA_OSL_TOT_MOV,
			--Add Group Currency
			ACDOCA_RKCUR,
			-- Add other currency
			ACDOCA_ROCUR
			-- Concatenate codes with their descriptions
			,B02_02_IT_FIN_COA.B02_ACDOCA_RBUKRS + ' - ' + B02_02_IT_FIN_COA.B02_T001_BUTXT		AS ZF_T001_BUKRS_BUTXT
			,B02_02_IT_FIN_COA.B02_ACDOCA_RACCT + ' - ' +  B02_02_IT_FIN_COA.B02_SKAT_TXT50		AS ZF_SKA1_SAKNR_TXT50
            ,ZF_TB_JOIN_KEY,

			CAST('' AS nvarchar(MAX)) ZF_DEBIT_CREDIT_FLAG ,
			CAST('' AS nvarchar(MAX)) ZF_TOTAL_BAL_FLAG 


		INTO  B03_01_IT_FIN_TB

		-- From clause is chart of accounts, with left join to trial balance in order to include
		-- all accounts, even those not in the trial balance

		FROM  B00_TB
				
		-- Add the trial balance
		LEFT JOIN  B02_02_IT_FIN_COA
		ON  B02_02_IT_FIN_COA.B02_ACDOCA_RACCT = ACDOCA_RACCT AND
			B02_02_IT_FIN_COA.B02_ACDOCA_RBUKRS = ACDOCA_RBUKRS

		---- Add the business domain (not necessary to do inner join because B02_04 is already limited on company code)
		INNER JOIN AM_SCOPE 
		ON  ACDOCA_RBUKRS = AM_SCOPE.SCOPE_CMPNY_CODE
		
		-- Add indicator that negative postings are permitted
		LEFT JOIN A_T001
		ON  ACDOCA_RBUKRS = A_T001.T001_BUKRS
					
		-- Add currency factor for HSL amount
		LEFT JOIN B00_TCURX B00_TCURX_HSL
		ON  B00_TB.ACDOCA_RHCUR =  B00_TCURX_HSL.TCURX_CURRKEY	

		-- Add currency factor for KSL amount
		LEFT JOIN B00_TCURX B00_TCURX_KSL
		ON  B00_TB.ACDOCA_RKCUR =  B00_TCURX_KSL.TCURX_CURRKEY	
		-- Add currency factor for OSL amount
		LEFT JOIN B00_TCURX B00_TCURX_OSL
		ON  B00_TB.ACDOCA_ROCUR =  B00_TCURX_OSL.TCURX_CURRKEY	

		--Add Fiscal year variant periods informations
		LEFT JOIN B00_T009B
			ON A_T001.T001_PERIV = B00_T009B.T009B_PERIV
			AND CAST(ACDOCA_MONAT AS INT) = CAST(B00_T009B.T009B_POPER AS INT)

		-- Get bstat description text.
		LEFT JOIN A_DD07T
			ON DD07T_DDLANGUAGE IN ('E', 'EN')
			AND DD07T_DOMNAME = 'BSTAT'
			AND IIF(LEN(DD07T_DOMVALUE_L) > 0,DD07T_DOMVALUE_L, 'BLANK_VALUE') = IIF(LEN(ACDOCA_BSTAT) > 0, ACDOCA_BSTAT, 'BLANK_VALUE')

		-- Get special gl description text.
		LEFT JOIN A_T074T
			ON A_T074T.T074T_SPRAS IN ('E','EN')
			AND A_T074T.T074T_KOART = ACDOCA_KOART
			AND A_T074T.T074T_SHBKZ = ACDOCA_UMSKZ

		-- Get document type desc
		LEFT JOIN A_T003T
			ON A_T003T.T003T_SPRAS IN ('E', 'EN')
			AND A_T003T.T003T_BLART = ACDOCA_BLART
		

	-- Add some field in AM 20F account mapping. This is request from Jesper ( 27-11-2020)
	/* Create AM_TANGO_20F_MAPPING table.  */

	EXEC SP_DROPTABLE 	'AM_TANGO_20F_MAPPING' 
	SELECT A.*
		,
				CASE 
					WHEN TANGO_ACCT IS NOT NULL AND [Tango AC] IS NOT NULL	THEN [Group]
					WHEN TANGO_ACCT IS NOT NULL AND [Tango AC] IS  NULL THEN 00
					ELSE NULL
				END AS ZF_TANGO_20F_GROUP,  
		  		CASE 
					WHEN TANGO_ACCT IS NOT NULL AND [Tango AC] IS NOT NULL	THEN Mapping
					WHEN TANGO_ACCT IS NOT NULL AND [Tango AC] IS  NULL THEN '00 Not mapped to 20F'
					ELSE NULL
				END AS ZF_TANGO_20F_MAPPING
	INTO AM_TANGO_20F_MAPPING
	FROM AM_TANGO AS A 
	LEFT JOIN  DIVA_MASTER_SCRIPT_S4HANA..AM_20F_ACCOUNT AS B
	ON DBO.REMOVE_LEADING_ZEROES(A.TANGO_ACCT)  =  DBO.REMOVE_LEADING_ZEROES(B.[Tango AC])

	/*Rename fields for Qlik*/
	EXEC sp_RENAME_FIELD 'B03_', 'B03_01_IT_FIN_TB'



	--Step 2 Update the flag
	--For balane is 0 flag
	UPDATE B03_01_IT_FIN_TB
	SET B03_ZF_TOTAL_BAL_FLAG = 'X'
	WHERE B03_ACDOCA_RACCT IN
	(
		SELECT   B03_ACDOCA_RACCT
		FROM B03_01_IT_FIN_TB
		GROUP BY B03_ACDOCA_RACCT,B03_ACDOCA_RYEAR
		HAVING SUM(B03_ZF_ACDOCA_HSL_TOT_MOV) = 0  AND  SUM(B03_ZF_ACDOCA_KSL_TOT_MOV) = 0 
	)

	--Debit-credit is 0
	UPDATE B03_01_IT_FIN_TB
	SET B03_ZF_DEBIT_CREDIT_FLAG='Debit-credit is 0'
	WHERE B03_ACDOCA_RACCT IN
	(
		SELECT   B03_ACDOCA_RACCT
		FROM B03_01_IT_FIN_TB
		GROUP BY B03_ACDOCA_RACCT,B03_ACDOCA_RYEAR
		HAVING SUM(B03_ZF_ACDOCA_KSL_DEBIT_MOV) = 0  AND  SUM(B03_ZF_ACDOCA_KSL_CREDIT_MOV) = 0 
		AND  SUM(B03_ZF_ACDOCA_HSL_DEBIT_MOV) = 0  AND  SUM(B03_ZF_ACDOCA_HSL_CREDIT_MOV) = 0 
	)
	--Debit-credit is not 0, balance is 0
		  UPDATE B03_01_IT_FIN_TB
	SET B03_ZF_DEBIT_CREDIT_FLAG='Debit-credit not 0, balance is 0'
	WHERE B03_ACDOCA_RACCT IN
	(
		SELECT   B03_ACDOCA_RACCT
		FROM B03_01_IT_FIN_TB
		GROUP BY B03_ACDOCA_RACCT,B03_ACDOCA_RYEAR
		HAVING (SUM(B03_ZF_ACDOCA_KSL_DEBIT_MOV) <> 0  AND  SUM(B03_ZF_ACDOCA_KSL_CREDIT_MOV) <> 0 AND  SUM(B03_ZF_ACDOCA_KSL_TOT_MOV) = 0 )
		AND  (SUM(B03_ZF_ACDOCA_HSL_DEBIT_MOV) <> 0  AND  SUM(B03_ZF_ACDOCA_HSL_CREDIT_MOV) <> 0 AND   SUM(B03_ZF_ACDOCA_HSL_TOT_MOV) = 0  )
	)

	-- Drop all temporary table
	EXEC SP_REMOVE_TABLES'%_TT_%'

/* log cube creation*/

INSERT INTO [dbo].[_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Cube completed','B03_01_IT_FIN_TB',(SELECT COUNT(*) FROM B03_01_IT_FIN_TB) 
        

/* log end of procedure*/


INSERT INTO [dbo].[_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL
GO
