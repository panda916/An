USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU71_Check if all default system users are secured]
AS
--DYNAMIC_SCRIPT_START

---Step 1: Check if there is any default system users not in clock status
---Default system are secured when they are inactive after using. It should be shown under USR02_UFLAG 

EXEC SP_DROPTABLE SU71_01_XT_URS02_UFLAG_ADD_DESC_FLK_0;
SELECT *,
      IIF(ZF_USR02_UFLAG LIKE 'X','Yes','No') AS ZF_USR02_UFLAG_DESC_YES_NO 
INTO SU71_01_XT_URS02_UFLAG_ADD_DESC_FLK_0
FROM BC16_01_IT_USR02_USERS
WHERE ZF_USR02_DEFAULT_USER LIKE 'Yes';

EXEC SP_RENAME_FIELD 'SU71_01_','SU71_01_XT_URS02_UFLAG_ADD_DESC_FLK_0';
GO
