USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[B04_SAP_CONFIGURATION_R2R](@DBNAME as NVARCHAR(MAX))
AS

-- Remove exist tables
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU26_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU23_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU27_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU31_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU37_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU39_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU40_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU44_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU53_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU54_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU56_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU75_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU82_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU88_%'

-- Run all scripts related to R2R
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU21_SU26_SU40 Identify movement types/ valuation classes/ account modifier combinations]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU23_Identify company codes that are not assigned to fiscal year variants or that have more than one period open]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU27_Indentify the account assignment categories where the account assignment can be changed]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU31_Check if GR/IR accounts allow for manual postings]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU37_SU57_Identify reconciliation accounts that allow for manual posting]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU39_Check if logistics postings are active]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU40_Check that all inventory transactions are set-up for automated account determination]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU44_Identify controlling areas that don't post to GL]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU53_Identify the standard accounts has transaction key relate to cash receipt]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU54_Identify company codes that do not have payment reason codes set and check reason code settings]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU56_Check if automated postings are set-up for cash discounts]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU75_Check that the clients are all set to production]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU82_Identify company code are set to productive]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU88_Check that there are maximum exchange rate difference limits]
GO
