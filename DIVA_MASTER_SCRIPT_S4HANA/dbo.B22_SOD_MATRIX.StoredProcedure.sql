USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROC [dbo].[B22_SOD_MATRIX](@DBNAME as NVARCHAR(MAX))
AS

EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'B22_%'
EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B22_SOD_MATRIX_PREPARATION'
EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B22_SOD_MATRIX'



GO
