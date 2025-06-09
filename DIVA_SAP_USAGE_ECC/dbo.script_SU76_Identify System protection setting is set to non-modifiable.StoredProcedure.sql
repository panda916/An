USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_SU76_Identify System protection setting is set to non-modifiable]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START

-- Script object: Check production system has non-modifiable setting
-- Step 1: Select data from TADIR (Directory of Repository Objects table)
EXEC SP_DROPTABLE 'SU76_01_RT_TADIR_SYS_PROTEC_SETTING_NON_MODIFIABLE'

SELECT *,
-- Add flag to show Object is setting to non-modifiable
	(
		CASE
			WHEN TADIR_EDTFLAG = 'N' THEN 'Yes'
			ELSE 'No'
		END
	) AS ZF_OBJ_EDIT_WITH_SPECIAL_EDITOR_FLAG
INTO SU76_01_RT_TADIR_SYS_PROTEC_SETTING_NON_MODIFIABLE
FROM A_TADIR

-- Rename the fields
EXEC SP_RENAME_FIELD 'SU76_01_', 'SU76_01_RT_TADIR_SYS_PROTEC_SETTING_NON_MODIFIABLE'

GO
