USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU44_Identify controlling areas that don't post to GL]
AS
--DYNAMIC_SCRIPT_START

--Script objective : Create table for test 44
--The system is configured with results analysis keys to calculate work in process accurately and post the results to accurate G/L accounts.

--Step 1: Load the B cube BC11_01_IT_TKA02_TKA01_TKKAP_TKKAB to identify controlling areas that don't post to GL 

EXEC SP_UNNAME_FIELD 'BC11_01_','BC11_01_IT_TKA02_TKA01_TKKAP_TKKAB';
EXEC SP_DROPTABLE SU44_01_RT_TKA02_KOKRS_NOT_FOUND_TKKAP
SELECT *,
      IIF(TKKAP_RFLG3 ='X','Yes','No') AS ZF_TKKAP_RFLG3_DESC,
	  IIF(TKKAP_ABRKZI ='X','Yes','No') AS ZF_TKKAP_ABRKZI_DESC
INTO SU44_01_RT_TKA02_KOKRS_NOT_FOUND_TKKAP
FROM BC11_01_IT_TKA02_TKA01_TKKAP_TKKAB

--Step 2: Load table TKKAB

EXEC SP_DROPTABLE SU44_02_RT_TKKAB;
SELECT *
INTO SU44_02_RT_TKKAB
FROM A_TKKAB;

--Rename the fields

EXEC SP_RENAME_FIELD 'SU44_01_','SU44_01_RT_TKA02_KOKRS_NOT_FOUND_TKKAP';
EXEC SP_RENAME_FIELD 'SU44_02_','SU44_02_RT_TKKAB';
GO
