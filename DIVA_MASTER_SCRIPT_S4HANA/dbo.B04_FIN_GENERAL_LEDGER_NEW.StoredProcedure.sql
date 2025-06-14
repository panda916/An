USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[B04_FIN_GENERAL_LEDGER_NEW] (@DBNAME NVARCHAR(MAX))
AS
--	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'B04_%'

	IF @DBNAME LIKE '%SIE%' 
		BEGIN
			EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B04_FIN_GENERAL_LEDGER_SIE_NEW'

			EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'B01_05_IT_CBE_BP%'
			EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'B02_03_IT_CBE_BP_BANK%'
			EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B01_CBE_BP_OPTIMIZED'
			EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B02_CBE_BP_BANK_OPTIMIZED'

		END
	
	ELSE EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B04_FIN_GENERAL_LEDGER_NEW'

	EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B04_SS01_GENERAL'
GO
