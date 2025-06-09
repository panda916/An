USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[B03_SAP_CONFIGURATION_P2P](@DBNAME as NVARCHAR(MAX))
AS

-- Remove exist tables
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU01_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU05_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU06_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU07_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU14_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU15_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU16_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU32_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU34_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU35_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU36_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU86_%'

-- Run all scripts related to P2P
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU01_Check if tolerance limits are set]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU05_Identify payment block keys that allow unblock in payment proposal]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU06_Identify movement types and valuation classes that don’t have account check or account assignment]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU07_Identify movement types that allow GR reversal after invoice posting]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU14_Identify vendors that don't have duplicate invoice check set]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU15_Verify appropriate warning messages on invoices]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU16_Identify movement types that allow for automatic creation of the PO (and therefore no PR reference)]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU32_Identify 1TV not in appropriate account groups]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU34_ Check if purchase documents are blocked if changed after release]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU35_Check if release groups are assigned to release strategies]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU36_Check if tolerance limits are set for clearing]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU86_ Identify sensitive vendor fields that are not set for 4-eye principle]
GO
