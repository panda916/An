USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROC [dbo].[B39_DUPLICATE_INVOICES](@DBNAME as NVARCHAR(MAX))
AS
EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'B39_%'

EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B39_DUPLICATE_INVOICES'
GO
