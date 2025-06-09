USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU27_Indentify the account assignment categories where the account assignment can be changed]
AS
--DYNAMIC_SCRIPT_START

--Script objective:
--Indentify the account assignment categories where the account assignment can be changed

--Step 1 Get the liest of  account assignment categorie
--Add a flag where no description for account assignment category

EXEC SP_DROPTABLE SU27_01_RT_ACCOUNT_ASSIGN_CATEGORY 

SELECT *,
--Add flag for no description case
IIF(BC09_01_T163I_KNTTX IS NULL OR LEN(BC09_01_T163I_KNTTX)=0, 'X','') AS ZF_T163I_KNTTX_NULL_FLAG
INTO SU27_01_RT_ACCOUNT_ASSIGN_CATEGORY
FROM BC09_01_IT_T163K_T163I
--Rename the fields
EXEC SP_UNNAME_FIELD 'BC09_01_','SU27_01_RT_ACCOUNT_ASSIGN_CATEGORY'
EXEC SP_RENAME_FIELD 'SU27_01_','SU27_01_RT_ACCOUNT_ASSIGN_CATEGORY'

GO
