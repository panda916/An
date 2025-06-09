USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU53_Identify the standard accounts has transaction key relate to cash receipt]
AS
--DYNAMIC_SCRIPT_START

--Script objective : Identify the standard accounts has transaction key relate to cash receipt

--Step 1 Get the list of standard acocunt
--Flag the case where transaction key is ZDI
EXEC SP_DROPTABLE SU53_01_RT_T030_CASH_RECEIPT_APP

SELECT *,
IIF(T030_KTOSL='ZDI','X','') AS ZF_T030_KTOSL_ZDI_PAY_DIFF
INTO SU53_01_RT_T030_CASH_RECEIPT_APP
FROM BC21_02_IT_T030_ADD_DESC


--Rename fields
EXEC SP_UNNAME_FIELD 'BC08_01_','SU53_01_RT_T030_CASH_RECEIPT_APP'
EXEC SP_RENAME_FIELD 'SU53_01_','SU53_01_RT_T030_CASH_RECEIPT_APP'

GO
