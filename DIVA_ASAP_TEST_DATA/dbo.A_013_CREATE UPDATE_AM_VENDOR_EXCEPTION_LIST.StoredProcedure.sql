USE [DIVA_ASAP_TEST_DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<thuan.tran@aufinia.com>
-- Create date: <Feb 1, 2023>
-- Description:	<Create and update AM_VENDOR_EXCEPTION_LIST mapping table relate to script_B08_PTP_SMD script>
-- =============================================
CREATE     PROCEDURE [dbo].[A_013_CREATE/UPDATE_AM_VENDOR_EXCEPTION_LIST]
AS
BEGIN
	EXEC SP_REMOVE_TABLES 'AM_VENDOR_EXCEPTION_LIST'

	CREATE TABLE [dbo].[AM_VENDOR_EXCEPTION_LIST](
		[VEL_COMPANY_CODE] [nvarchar](1000) NULL,
		[VEL_SUPPLIER_NUM] [nvarchar](1000) NULL
	) 
END



GO
