USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU75_Check that the clients are all set to production]
AS 
--DYNAMIC_SCRIPT_START

--Script objective: Indentify the company code are set to productive
--Check that the clients are all set to production
--Step 1 Get the list of company code , flag the case are set to productive
EXEC SP_DROPTABLE SU75_01_RT_T001_T000_ADD_XPROD_FLAG

SELECT DISTINCT 
BC07_01_T001_MANDT,
BC07_01_T001_BUKRS,
BC07_01_T001_BUTXT,
BC07_01_T001_XPROD,
BC07_01_ZF_T000_CCCATEGORY_DESC,
BC07_01_T000_CCCATEGORY,
BC07_01_T001_KTOPL,
BC07_01_T004T_KTPLT,
IIF(BC07_01_T001_XPROD='X','Yes','') AS ZF_T001_XPROD_FLAG
INTO SU75_01_RT_T001_T000_ADD_XPROD_FLAG
FROM BC07_01_IT_T001_T009_T001B_T000

--Rename fields
EXEC SP_UNNAME_FIELD 'BC07_01_','SU75_01_RT_T001_T000_ADD_XPROD_FLAG'
EXEC SP_RENAME_FIELD 'SU75_01_','SU75_01_RT_T001_T000_ADD_XPROD_FLAG'
GO
