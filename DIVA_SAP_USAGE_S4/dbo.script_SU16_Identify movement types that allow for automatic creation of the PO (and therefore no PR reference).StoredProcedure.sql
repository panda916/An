USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU16_Identify movement types that allow for automatic creation of the PO (and therefore no PR reference)]
AS
--DYNAMIC_SCRIPT_START

--Script ojective: Indentify the movement type that allow to create purchase order automatically	

--Step 1 Get the list of  Movement Type
--Add the flag for the case where movement type that allow to create purchase order automatically	
EXEC SP_DROPTABLE SU16_01_RT_T156_XNEBE_EQ_X_FLAG
SELECT 
DISTINCT
	    T156_BWART,
		T156_XNEBE,
		T156_SHKZG,
		IIF(T156_SHKZG='H','Credit','Debit') AS ZF_T156_SHKZG_DESC,
IIF(T156_XNEBE='X','Yes','') AS ZF_T156_XNEBE_FLAG,
T156HT_BTEXT
INTO SU16_01_RT_T156_XNEBE_EQ_X_FLAG
FROM A_T156
LEFT JOIN A_T156HT ON T156_BWART=T156HT_BWART AND T156HT_SPRAS='EN'

--STep 2 Rename fields
EXEC SP_RENAME_FIELD 'SU16_01_', 'SU16_01_RT_T156_XNEBE_EQ_X_FLAG'
GO
