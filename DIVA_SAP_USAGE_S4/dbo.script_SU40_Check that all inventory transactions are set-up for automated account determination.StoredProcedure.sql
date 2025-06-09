USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[script_SU40_Check that all inventory transactions are set-up for automated account determination]
AS
--DYNAMIC_SCRIPT_START

--Script objective :Check that all inventory transactions are set-up for automated account determination
--
--STep 1 Get the list of standards account
--Flag the case where the transaction key relate to inventory
--Flage the case where the transaction key relate to inventory and missing the GL account

EXEC SP_DROPTABLE SU40_01_RT_T030_KTOSL_EQ_BSX_KDM_PRV_PRY_UMB
SELECT DISTINCT * ,
IIF( T030_KTOSL= 'BSX' OR T030_KTOSL='KDM' OR T030_KTOSL='PRV' OR T030_KTOSL='PRY' OR T030_KTOSL='UMB'
,'X','') AS ZF_T030_KTOSL_INV_RELATE,
IIF( 
	(T030_KTOSL= 'BSX' OR T030_KTOSL='KDM' OR T030_KTOSL='PRV' OR T030_KTOSL='PRY' OR T030_KTOSL='UMB')
	AND 
	(T030_KONTS='' OR T030_KONTH=''),'X','') AS ZF_T030_KONTH_KONTS_MISSING
INTO SU40_01_RT_T030_KTOSL_EQ_BSX_KDM_PRV_PRY_UMB
FROM BC21_02_IT_T030_ADD_DESC

--Rename the fields

EXEC SP_RENAME_FIELD 'SU40_01_','SU40_01_RT_T030_KTOSL_EQ_BSX_KDM_PRV_PRY_UMB'


GO
