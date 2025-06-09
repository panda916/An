USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_BC07_T001_T001B_T009_T009B_T000_CC_FY_PP_CAT]
AS
--DYNAMIC_SCRIPT_START
--Script objetive :

--Step 1/ Get the company master data
--Add the information about fiscal year variant and Permitter posting period
--Add flag for the case where company code does not have  Fiscal Year Variants and  Permitter posting period
--Add the flags for to see the different between fisrt and last Posting Period Allowed
EXEC SP_DROPTABLE BC07_01_IT_T001_T009_T001B_T000

SELECT DISTINCT 
--Get the company code master date
		A_T001.*,
--Add Fiscal Year Variants 
		T009_XKALE,
		T009_XJABH,
		T009_ANZBP,
		T009_ANZSP,
		IIF(T009_PERIV IS NULL, 'X','') AS ZF_T009_PERIV_NULL_FLAG, --Flag the company that are not set  Fiscal Year Variants 
		T001B_RRCTY,
--Add Permitted Posting Periods 
		CASE 
			WHEN T001B_RRCTY=0 THEN 'Actual'
			WHEN T001B_RRCTY=1 THEN 'Plan'
			WHEN T001B_RRCTY=2 THEN 'Actual assessment/distribution'
			WHEN T001B_RRCTY=3 THEN 'Planned assessment/distribution'
			ELSE 'No description found' END AS  ZF_T001B_RRCTY_DESC, -- Description for Record Type

		T001B_MKOAR,
		CASE
		WHEN T001B_MKOAR='+' THEN 'Valid for all account types'	
		WHEN T001B_MKOAR='A' THEN 'Assets'	
		WHEN T001B_MKOAR='C' THEN 'CO-PA: Profitability Analysis'	
		WHEN T001B_MKOAR='D' THEN 'Customers'	
		WHEN T001B_MKOAR='G' THEN 'Special Purpose Ledger'	
		WHEN T001B_MKOAR='K' THEN 'Vendors'	
		WHEN T001B_MKOAR='M' THEN 'Materials'	
		WHEN T001B_MKOAR='S' THEN 'G/L accounts'	
		WHEN T001B_MKOAR='V' THEN 'Contract accounts'	
		ELSE 'No description found' END AS ZF_T001B_MKOAR_DESC, --Description for Account Type 
		T001B_BKONT,
		T001B_VKONT,
		T001B_FRYE1,
		T001B_FRPE1,
		T001B_TOYE1,
		T001B_TOPE1,
		T001B_FRYE2,
		T001B_FRPE2,
		T001B_TOYE2,
		T001B_TOPE2,
		T001B_BRGRU,
		T001B_FRYE3 ,
		T001B_FRPE3,
		T001B_TOYE3, 
		T001B_TOPE3,
--CLient information
		T000_CCCATEGORY,
		CASE
			WHEN T000_CCCATEGORY='P' THEN 'Production'
			WHEN T000_CCCATEGORY='T' THEN 'Test'
			WHEN T000_CCCATEGORY='C' THEN 'Customizing'
			WHEN T000_CCCATEGORY='D' THEN 'Demo'
			WHEN T000_CCCATEGORY='E' THEN 'Training/Education'
			WHEN T000_CCCATEGORY='S' THEN 'SAP reference'
		ELSE 'Not found' END AS ZF_T000_CCCATEGORY_DESC,
		T004T_KTPLT,
		IIF(T001B_BUKRS IS NULL, 'X','') AS ZF_T001B_BUKRS_NULL_FLAG,-- Flag the companys are not set Permitted Posting Periods 
		IIF(T001B_FRPE1<>T001B_TOPE1,'X','') AS ZF_DIFF_T001B_FRPE1_TOPE1,--Flag the case where First Posting Period Allowed and Last First Posting Period Allowed in Interval 1
		IIF(T001B_FRPE2<>T001B_TOPE2,'X','') AS ZF_DIFF_T001B_FRPE2_TOPE2,--Flag the case where First Posting Period Allowed and Last First Posting Period Allowed in Interval 2
		IIF(T001B_FRPE3<>T001B_TOPE3,'X','') AS ZF_DIFF_T001B_FRPE3_TOPE3--Flag the case where First Posting Period Allowed and Last First Posting Period Allowed in Interval 3
INTO BC07_01_IT_T001_T009_T001B_T000
FROM A_T001 
--Add Fiscal Year Variants 
LEFT JOIN A_T009 ON T001_PERIV=T009_PERIV
--Add Permitted Posting Periods 
LEFT JOIN A_T001B ON T001_BUKRS=T001B_BUKRS
--Add client information
LEFT JOIN A_T000 ON T001_MANDT=T000_MANDT
--Add the chart of account description
LEFT JOIN A_T004T ON T001_KTOPL=T004T_KTOPL


--Rename the fields
EXEC SP_RENAME_FIELD 'BC07_01_','BC07_01_IT_T001_T009_T001B_T000'

GO
