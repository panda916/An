USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[B01_SAP_CONFIGURATION_INVENTORY](@DBNAME as NVARCHAR(MAX))
AS
-- Remove exist tables
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU04_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU08_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU13_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU18_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU25_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU42_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU43_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU45_%'

-- Run script related to inventory
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU04_Identify materials and purchase orders that allow for unlimited overdelivery]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU08_Check if tolerance groups are set for physical inventory differences]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU13_Identify materials that don't have cycle counting]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU18_Identify if price control indicator and mandatory price control are set]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU25_Identify storage locations that do not allow inventory freeze]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU42_Identify movement types that allow for GR reversal after IR]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU43_Identify storage locations that allow negative stock]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU45_Identify material types that don't update quantity/ value]








GO
