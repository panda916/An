USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[B08_SAP_CONFIGURATION_LOGS](@DBNAME as NVARCHAR(MAX))
AS

-- Remove exist tables
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU64_%'
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU69_%'
	EXEC   SP_REMOVE_TABLES_MASTER @DBNAME, 'SU70_%'

-- Run all scripts related to Sap configuation security
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU64_CHeck that the secrutiy log is enabled]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU69_Check that table changes are set to be logged]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU70_Check that sensitive tables are set for logging of changes]



GO
