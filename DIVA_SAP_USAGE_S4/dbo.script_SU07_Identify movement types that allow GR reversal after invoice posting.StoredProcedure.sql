USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU07_Identify movement types that allow GR reversal after invoice posting]
AS
--DYNAMIC_SCRIPT_START

--Script objective: Identity the movement type where reversal of GR allowed for GR-based IV despite invoice
--Step 1 Get the list movement type
--Flag the case where Reversal of GR allowed for GR-based IV despite invoice
EXEC SP_DROPTABLE SU07_01_RT_T156_XWSBR_FLAG
SELECT 	   DISTINCT T156_BWART,
		T156_XNEBE,
		T156_SHKZG,
		IIF(T156_SHKZG='H','Credit','Debit') AS ZF_T156_SHKZG_DESC,
IIF(T156_XWSBR='X','Yes','No') AS ZF_T156_XWSBR_FLAG,
T156HT_BTEXT
INTO SU07_01_RT_T156_XWSBR_FLAG
FROM A_T156
LEFT JOIN A_T156HT ON T156_BWART=T156HT_BWART AND T156HT_SPRAS='EN'

--STep 2 Rename fields
EXEC SP_RENAME_FIELD 'SU07_01_', 'SU07_01_RT_T156_XWSBR_FLAG'


GO
