USE [DIVA_ASAP_TEST_DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<thuan.tran@aufinia.com>
-- Create date: <Feb 1, 2023>
-- Description:	<Create and update AM table relate to process minning mapping>
-- =============================================
CREATE   PROCEDURE [dbo].[A_012_CREATE/UPDATE_AM_COMPANY_CODE]
AS
BEGIN
	EXEC SP_REMOVE_TABLES 'AM_COMPANY_CODE'
	SELECT 
	DISTINCT 
		SCOPE_CMPNY_CODE AS COMPANY_CODE
	INTO AM_COMPANY_CODE
	FROM AM_SCOPE
END



GO
