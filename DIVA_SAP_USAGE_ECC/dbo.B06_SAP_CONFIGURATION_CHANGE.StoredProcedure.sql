USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[B06_SAP_CONFIGURATION_CHANGE](@DBNAME as NVARCHAR(MAX))
AS

-- Remove exist tables
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU74_%'
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU76_%'
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU77_%'
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU80_%'
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU81_%'
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU85_%'

-- Run all scripts related to Sap Configuation change
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU74_Check all production clients are locked]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU76_Identify System protection setting is set to non-modifiable]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU77_Show users that update tables directly through SE16N]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU80_Identify user access to a developer key]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU81_Identify transports originate in the development system]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU85_Check if custom progams have adequate descriptions]
GO
