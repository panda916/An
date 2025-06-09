USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SP_TRANSFER_TABLE_BETWEEN_DATABASE_VINH]
	-- Add the parameters for the stored procedure here
	@FROM_DATABASE NVARCHAR(100),
	@TO_DATABASE NVARCHAR(100)
AS
BEGIN
	EXEC SP_EXEC_DYNAMIC @FROM_DATABASE, 'script_SP_TRANSFER_TABLE_BETWEEN_DATABASE_VINH', @TO_DATABASE
END
GO
