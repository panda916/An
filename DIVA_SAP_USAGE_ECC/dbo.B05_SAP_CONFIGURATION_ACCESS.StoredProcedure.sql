USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[B05_SAP_CONFIGURATION_ACCESS](@DBNAME as NVARCHAR(MAX))
AS

-- Remove exist tables
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU63_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU71_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU72_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU73_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU78_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU79_%'
	EXEC  SP_REMOVE_TABLES_MASTER @DBNAME, 'SU83_%'

-- Run all scripts related to Sap Configuation access
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU63_Check if SAP* is secure]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU71_Check if all default system users are secured]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU72_Check if all system users have changed passwords]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU73_Check if powerful profiles are secured]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU78_Check no users can do debug in production]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU79_Check terminated users have validity date and locked]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU83_Check custom programs are assigned authorization group]
GO
