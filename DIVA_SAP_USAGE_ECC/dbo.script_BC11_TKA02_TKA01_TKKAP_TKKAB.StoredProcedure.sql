USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_BC11_TKA02_TKA01_TKKAP_TKKAB]
AS
--DYNAMIC_SCRIPT_START
--Script objective: Create controlling area cubes

--Step 1 Create Create controlling area cubes

EXEC SP_DROPTABLE BC11_01_IT_TKA02_TKA01_TKKAP_TKKAB

SELECT * 
INTO BC11_01_IT_TKA02_TKA01_TKKAP_TKKAB
FROM  A_TKKAP
--Add the information from TKA01
LEFT JOIN A_TKA01 ON TKA01_KOKRS=TKKAP_KOKRS
--Results Analysis Versions for Results Analysis
LEFT JOIN A_TKA02 ON TKA02_KOKRS=TKKAP_KOKRS
--Add company code
LEFT JOIN A_T001
ON T001_KTOPL=TKA01_KTOPL


GO
