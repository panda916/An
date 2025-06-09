USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[B07_SAP_CONFIGURATION_SECURITY](@DBNAME as NVARCHAR(MAX))
AS

-- Remove exist tables
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU60_%'
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU61_%'
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU62_%'
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU65_%'
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU66_%'
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU67_%'
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU68_%'

-- Run all scripts related to Sap configuation security
	EXEC SP_EXEC_DYNAMIC @DBNAME,[script_SU60_Check if password parameters are correctly configured]
	EXEC SP_EXEC_DYNAMIC @DBNAME,[script_SU61_Check list of passwords to be rejected]
	EXEC SP_EXEC_DYNAMIC @DBNAME,[script_SU62_Check logon parameters]
	EXEC SP_EXEC_DYNAMIC @DBNAME,[script_SU65_Check that authorization objects cannot be globally switched off]
	EXEC SP_EXEC_DYNAMIC @DBNAME,[script_SU66_Identify authorization objects that have been switched off]
	EXEC SP_EXEC_DYNAMIC @DBNAME,[script_SU67_Identify authorization objects disabled at TCODE level]
	EXEC SP_EXEC_DYNAMIC @DBNAME,[script_SU68_Identify users that are allowed to have multiple logins]
GO
