USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU56_Check if automated postings are set-up for cash discounts]
AS
--DYNAMIC_SCRIPT_START

--Script objective : Identify the standards accounts have transaction keys is STK 

--STep1 Get the date from standards account cube
--Flag the case where T030_KTOSL is 'SKT' or '' or 'SKV'
EXEC SP_DROPTABLE SU56_01_RT_T030_KTOSL_EQ_SKT_SKE_SKV_FLAG

SELECT *,
IIF(T030_KTOSL='SKT' OR T030_KTOSL='SKV' OR T030_KTOSL='SKE','X','') AS ZF_T030_KTOSL_EQ_SKT_SKE_SKV
INTO SU56_01_RT_T030_KTOSL_EQ_SKT_SKE_SKV_FLAG
FROM BC21_02_IT_T030_ADD_DESC


--Rename fields

EXEC SP_RENAME_FIELD 'SU56_01_','SU56_01_RT_T030_KTOSL_EQ_SKT_SKE_SKV_FLAG'


GO
