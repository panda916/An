USE [DIVA_WARRANTY_APAC]
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[ReadNLines]
	@path [nvarchar](max),
	@nrlines [int]
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [CLRReadLines].[ReadWriteFileTips].[ReadNLines]
GO
