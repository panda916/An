USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--ALTER PROCEDURE [dbo].[B03_FIN_TRIAL_BALANCE]
CREATE     PROCEDURE [dbo].[script_B03_FIN_TRIAL_BALANCE]
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
			 @currency nvarchar(max)			= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'currency')
			,@date1 nvarchar(max)				= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'date1')
			,@date2 nvarchar(max)				= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'date2')
			,@downloaddate nvarchar(max)		= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'downloaddate')
			,@exchangeratetype nvarchar(max)	= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'exchangeratetype')
			,@language1 nvarchar(max)			= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'language1')
			,@language2 nvarchar(max)			= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'language2')
			,@year nvarchar(max)				= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'year')
			,@id nvarchar(max)					= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'id')
			,@ZV_TB_RRCTY nvarchar(max)		    = (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'ZV_TB_RRCTY')
			,@LIMIT_RECORDS INT                 = CAST((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS') AS INT)
			,@ZV_DATE nvarchar(max)				= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'ZV_DATE')

      
SET ROWCOUNT @LIMIT_RECORDS
      

DECLARE @dateformat varchar(3)
SET @dateformat   = (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'dateformat')
SET DATEFORMAT @dateformat;

/*Change history comments*/

/*
    Title			:	_Cube FIN-02-BAL G/L Account balances
    Description		:	Balance totals as taken from table [GLT0]	

     
    --------------------------------------------------------------
    Update history
    --------------------------------------------------------------
    Date		    | Who   |	Description
	30-03-2016		  MW	    Initial Sony version
	18-04-2016		  EH	    Updated code for understanding
	11-05-2016		  MW	    Added company code to join on _FSMCAM_SCOPE
	14-02-2017		  JSM   	Added database log
	19-03-2017		  CW        Update and standardisation for SID
	08-06-2017		  AJ 	 	Updated scripts with new naming convention
	22-03-2022	     Thuan	    Remove MANDT field in join
*/


/*In case we are in test mode according to the globals table*/

/*--Step 1
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
--Fields are being calculated as mentioned in SELECT clause below*/


EXEC SP_DROPTABLE 	'B03_03_IT_FIN_TB' 

	SELECT
			B02_04_IT_FIN_COA.B02_SKB1_MANDT AS SKB1_MANDT,
			--AM_SCOPE.SCOPE_BUSINESS_DMN_L1,
			--AM_SCOPE.SCOPE_BUSINESS_DMN_L2,
			B02_04_IT_FIN_COA.B02_T001_KTOPL AS T001_KTOPL,
			B02_04_IT_FIN_COA.B02_T001_BUKRS AS T001_BUKRS, 
			B02_04_IT_FIN_COA.B02_T001_BUTXT AS T001_BUTXT, 
			--AM_FSMC.FSMC_ID,
			--AM_FSMC.FSMC_NAME,
			--AM_FSMC.FSMC_CNTRY_CODE,
   --         AM_FSMC.FSMC_REGION,
   --         AM_FSMC.FSMC_CONTROLLING_AREA,
   --         AM_FSMC.FSMC_PROFIT_CENTER,
			B00_TB.TB_RBUSA,
			--A_TGSBT.TGSBT_GTEXT,
			COALESCE(B00_TB.TB_RACCT,'Not in Bal')	AS TB_RACCT,
			B02_04_IT_FIN_COA.B02_SKB1_SAKNR AS SKB1_SAKNR,
			B02_04_IT_FIN_COA.B02_SKAT_TXT50 AS SKAT_TXT50, 
			B02_04_IT_FIN_COA.B02_TANGO_ACCT AS TANGO_ACCT,
			B02_04_IT_FIN_COA.B02_TANGO_ACCT_TXT AS TANGO_ACCT_TXT,
			B02_04_IT_FIN_COA.B02_SKB1_MITKZ AS SKB1_MITKZ,
			B02_04_IT_FIN_COA.B02_SKA1_XBILK AS SKA1_XBILK,
			T001_XNEGP,
			B00_TB.TB_RYEAR, 
			B00_TB.TB_MONAT,
			ISNULL(B00_TB.TB_RRCTY,'') AS TB_RRCTY,
			ISNULL(B00_TB.TB_RLDNR, '') AS TB_RLDNR,
				-- Add Posting month
			CASE
				WHEN TB_MONAT = 0 THEN 'Open'
				WHEN TB_MONAT = 1 THEN 'JAN'
				WHEN TB_MONAT = 2 THEN 'FEB'
				WHEN TB_MONAT = 3 THEN 'MAR'
				WHEN TB_MONAT = 4 THEN 'APR'
				WHEN TB_MONAT = 5 THEN 'MAY'
				WHEN TB_MONAT = 6 THEN 'JUN'
				WHEN TB_MONAT = 7 THEN 'JUL'
				WHEN TB_MONAT = 8 THEN 'AUG'
				WHEN TB_MONAT = 9 THEN 'SEP'
				WHEN TB_MONAT = 10 THEN 'OCT'
				WHEN TB_MONAT = 11 THEN 'NOV'
				ELSE 'DEC' 
			END AS [TB_MONAT_DESC], --Added for Sony
			-- Add Quarter
			CASE	
				WHEN B00_TB.TB_MONAT = 0 THEN 'Open'
				WHEN B00_TB.TB_MONAT = 1 THEN 'Q1'
				WHEN B00_TB.TB_MONAT = 2 THEN 'Q1'
				WHEN B00_TB.TB_MONAT = 3 THEN 'Q1'
				WHEN B00_TB.TB_MONAT = 4 THEN 'Q2'
				WHEN B00_TB.TB_MONAT = 5 THEN 'Q2'
				WHEN B00_TB.TB_MONAT = 6 THEN 'Q2'
				WHEN B00_TB.TB_MONAT = 7 THEN 'Q3'
				WHEN B00_TB.TB_MONAT = 8 THEN 'Q3'
				WHEN B00_TB.TB_MONAT = 9 THEN 'Q3'
				WHEN B00_TB.TB_MONAT = 10 THEN 'Q4'
				WHEN B00_TB.TB_MONAT = 11 THEN 'Q4'
				ELSE 'Q4' 
			END AS TB_MONAT_FQ,
			B00_TB.TB_RYEAR + '-' + B00_TB.TB_MONAT AS [TB_RYEAR_MONAT],

			-- Add debit/credit
			CASE B00_TB.TB_DRCRK
				WHEN 'S' THEN 'Debit'
				WHEN 'H' THEN 'Credit'
			END											AS [TB_DRCRK_DESC], 
			
			T001_WAERS,

			-- Add opening balance
			CASE 
				WHEN B00_TB.TB_MONAT = 0  THEN CONVERT(money, B00_TB.TB_HSLV1_16 * ISNULL(B00_TCURX.TCURX_FACTOR,1))  
				WHEN B00_TB.TB_MONAT <> 0 THEN 0
			END  AS TB_HSL_OPENING_BAL,

			-- Add debit movements
			CASE 
				WHEN B00_TB.TB_MONAT = 0  OR B00_TB.TB_DRCRK <> 'S' THEN 0 
				WHEN B00_TB.TB_MONAT <> 0 AND B00_TB.TB_DRCRK = 'S' THEN CONVERT(money, B00_TB.TB_HSLV1_16 * ISNULL(B00_TCURX.TCURX_FACTOR,1))
			END  AS TB_HSL_DEBIT_MOV,

			-- Add credit movements
			CASE 
				WHEN B00_TB.TB_MONAT = 0  OR B00_TB.TB_DRCRK <> 'H' THEN 0 
				WHEN B00_TB.TB_MONAT <> 0 AND B00_TB.TB_DRCRK = 'H' THEN CONVERT(money, B00_TB.TB_HSLV1_16 * ISNULL(B00_TCURX.TCURX_FACTOR,1))
			END  AS TB_HSL_CREDIT_MOV,

			-- Add total movements
			CONVERT(money, B00_TB.TB_HSLV1_16 * ISNULL(B00_TCURX.TCURX_FACTOR,1)) AS TB_HSL_TOT_MOV,

			@currency									AS GLOBALS_PARAMETER_CURR,

			-- Add opening balance(custom)
			CASE 
				WHEN B00_TB.TB_MONAT = 0  THEN CONVERT(money, B00_TB.TB_HSLV1_16 * ISNULL(B00_TCURX.TCURX_FACTOR,1) * COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1))
				WHEN B00_TB.TB_MONAT <> 0 THEN 0
			END  AS TB_HSL_OPENING_BAL_CUC,

			-- Add debit movements (custom)
			CASE 
				WHEN B00_TB.TB_MONAT = 0  OR B00_TB.TB_DRCRK <> 'S' THEN 0 
				WHEN B00_TB.TB_MONAT <> 0 AND B00_TB.TB_DRCRK = 'S' THEN CONVERT(money, B00_TB.TB_HSLV1_16 * ISNULL(B00_TCURX.TCURX_FACTOR,1) * COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1)) 
			END  AS TB_HSL_DEBIT_MOV_CUC,

			-- Add Credit movements (Custom)
			CASE 
				WHEN B00_TB.TB_MONAT = 0  OR B00_TB.TB_DRCRK <> 'H' THEN 0 
				WHEN B00_TB.TB_MONAT <> 0 AND B00_TB.TB_DRCRK = 'H' THEN CONVERT(money, B00_TB.TB_HSLV1_16 * ISNULL(B00_TCURX.TCURX_FACTOR,1) * COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1))
			END  AS TB_HSL_CREDIT_MOV_CUC,

			-- Add Total movements (Custom)
			CONVERT(money, B00_TB.TB_HSLV1_16 * ISNULL(B00_TCURX.TCURX_FACTOR,1) * COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1)) AS TB_HSL_TOT_MOV_CUC,

			-- Add opening balance(custom)
			CASE 
				WHEN B00_TB.TB_MONAT = 0 THEN B00_TB.TB_KSLV1_16
				WHEN B00_TB.TB_MONAT <> 0 THEN 0
			END TB_KSL_OPENING_BAL,

			-- Add debit movements (custom)
			CASE 
				WHEN B00_TB.TB_MONAT = 0  OR B00_TB.TB_DRCRK <> 'S' THEN 0 
				WHEN B00_TB.TB_MONAT <> 0 AND B00_TB.TB_DRCRK = 'S' THEN B00_TB.TB_KSLV1_16
			END TB_KSL_DEBIT_MOV,

			-- Add Credit movements (Custom)
			CASE 
				WHEN B00_TB.TB_MONAT = 0  OR B00_TB.TB_DRCRK <> 'H' THEN 0 
				WHEN B00_TB.TB_MONAT <> 0 AND B00_TB.TB_DRCRK = 'H' THEN B00_TB.TB_KSLV1_16
			END TB_KSL_CREDIT_MOV,

			-- Add Total movements (Custom)
			B00_TB.TB_KSLV1_16 TB_KSL_TOT_MOV
			-- Concatenate codes with their descriptions
			--,B00_TB.TB_RBUSA + ' - ' + A_TGSBT.TGSBT_GTEXT									AS TB_RBUSA_GTEXT
			,B02_04_IT_FIN_COA.B02_T001_BUKRS + ' - ' + B02_04_IT_FIN_COA.B02_T001_BUTXT		AS ZF_T001_BUKRS_BUTXT
			--,AM_FSMC.FSMC_ID+AM_FSMC.FSMC_NAME 													AS ZF_FSMC_ID_NAME
			,B02_04_IT_FIN_COA.B02_SKB1_SAKNR + ' - ' +  B02_04_IT_FIN_COA.B02_SKAT_TXT50		AS ZF_SKB1_SAKNR_TXT50,
			--,B02_04_IT_FIN_COA.B02_TANGO_ACCT + ' - ' + B02_04_IT_FIN_COA.B02_TANGO_ACCT_TXT	AS ZF_TANGO_ACCT_TEXT,
			B00_TB.ZF_DATE
		INTO  B03_03_IT_FIN_TB

		-- From clause is chart of accounts, with left join to trial balance in order to include
		-- all accounts, even those not in the trial balance

		FROM  B02_04_IT_FIN_COA
				
		-- Add the trial balance
		RIGHT JOIN  B00_TB
		ON  B02_04_IT_FIN_COA.B02_SKB1_SAKNR = B00_TB.TB_RACCT AND
			B02_04_IT_FIN_COA.B02_T001_BUKRS = B00_TB.TB_BUKRS AND
            B00_TB.TB_RYEAR IN (@year, @year-1, @year-2, @year-3, @year-4)

		---- Add the business domain (not necessary to do inner join because B02_04 is already limited on company code)
		INNER JOIN AM_SCOPE 
		ON  B00_TB.TB_BUKRS = AM_SCOPE.SCOPE_CMPNY_CODE
		
		-- Add indicator that negative postings are permitted
		LEFT JOIN A_T001
		ON  B00_TB.TB_BUKRS = A_T001.T001_BUKRS

	-- Add currency factor from company currency to USD

		LEFT JOIN B00_IT_TCURF
		ON A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR
		AND B00_IT_TCURF.TCURF_TCURR  = @currency  
		AND B00_IT_TCURF.TCURF_GDATU = (
			SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
			FROM B00_IT_TCURF
			WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
					B00_IT_TCURF.TCURF_TCURR  = @currency  AND
					B00_IT_TCURF.TCURF_GDATU <= ZF_DATE
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
					B00_IT_TCURR.TCURR_GDATU <= ZF_DATE
			ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
			) 
		-- Add currency factor to multiply up currencies that have too many zeros for SAP 
		LEFT JOIN B00_TCURX 
		ON  A_T001.T001_WAERS =  B00_TCURX.TCURX_CURRKEY	

  --      -- Add FSMC information
		--LEFT JOIN AM_FSMC 
		--ON  AM_FSMC.FSMC_PROFIT_CENTER = B00_TB.TB_BUKRS
		WHERE B00_TB.TB_RRCTY LIKE @ZV_TB_RRCTY

/*Rename fields for Qlik*/
EXEC sp_RENAME_FIELD 'B03_', 'B03_03_IT_FIN_TB'
--DROP OUTPUT TABLE IN B04 TO AVOID CONFLICT WHEN RUNNING B04
EXEC SP_DROPTABLE 'B04_06_IT_BSEG_BKPF_ACC_SCH'
GO
