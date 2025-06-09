USE [DIVA_GB00_FY23_24]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SP_CHECK_TBL_CREATION_DATE]
AS
SELECT [name] AS [TableName], [create_date] AS [CreatedDate] FROM sys.tables
where LEFT(name, 2) = 'A_'





GO
