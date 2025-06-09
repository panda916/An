USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_BC09_T163K_T163I]
AS
--DYNAMIC_SCRIPT_START
--Script objective: Create the cube for account assignment category

--Step 1 Get the information about account assignment category 
--Add tthe text description for account assignment category
EXEC SP_DROPTABLE BC09_01_IT_T163K_T163I
SELECT DISTINCT * ,
CASE WHEN T163K_KNTTP='A' THEN 'Asset'
	WHEN T163K_KNTTP='V' THEN 'Consumption'
	WHEN T163K_KNTTP='E' THEN 'Accounting via sales order'
	WHEN T163K_KNTTP='U' THEN 'Unknown'
	WHEN T163K_KNTTP='P' THEN 'Accounting via project' ELSE 'Not found'
	END AS ZF_T163K_KZVBR_DESC
INTO BC09_01_IT_T163K_T163I
FROM A_T163K
--Add text description for AcctAssgntCateg Desc
LEFT JOIN A_T163I
ON T163K_KNTTP=T163I_KNTTP AND T163I_SPRAS='EN'

--Rename the fields
EXEC SP_RENAME_FIELD 'BC09_01_','BC09_01_IT_T163K_T163I'

GO
