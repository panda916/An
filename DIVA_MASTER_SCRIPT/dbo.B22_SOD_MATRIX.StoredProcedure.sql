USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[B22_SOD_MATRIX](@DBNAME as NVARCHAR(MAX))
AS
EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'B22%'
--EXEC SP_EXEC_DYNAMIC 'DIVA_TURKEY_FY19_20Q3', 'script_B22_SOD_MATRIX_PREPARATION'
EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B22_SOD_MATRIX_PREPARATION'
EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B22_SOD_MATRIX'



GO
