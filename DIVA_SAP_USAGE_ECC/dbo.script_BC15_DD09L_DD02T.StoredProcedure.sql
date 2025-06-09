USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[script_BC15_DD09L_DD02T] AS
--DYNAMIC_SCRIPT_START
--Script objective : Create technical setting for table cube

--Step 1 Get the information about technical setting for table
--Add the name of the table
EXEC SP_DROPTABLE BC15_01_IT_DD09L_DD02T

SELECT A.*, 
CASE 
	WHEN	DD09L_AS4LOCAL= 'A' THEN 'Entry activated or generated in this form'
	WHEN	DD09L_AS4LOCAL= 'L'	THEN 'Lock entry (first N version)'
	WHEN	DD09L_AS4LOCAL= 'N' THEN 'Entry edited, but not activated'	
	WHEN	DD09L_AS4LOCAL= 'S'	THEN 'Previously active entry, backup copy'
	WHEN	DD09L_AS4LOCAL= 'T'	THEN 'Temporary version when editing'
	ELSE 'Not found' END ZF_DD09L_AS4LOCAL_DESC,
CASE
WHEN DD09L_TABKAT=0	THEN 'Tables < 500K'
WHEN DD09L_TABKAT=1	THEN 'Tables < 1.5 MB'
WHEN DD09L_TABKAT=2	THEN 'Tables < 6.5 MB'
WHEN DD09L_TABKAT=3	THEN 'Tables < 25 MB'
WHEN DD09L_TABKAT=4	THEN 'Tables > 160 MB'
WHEN DD09L_TABKAT=5	THEN 'Value cannot be maintained manually (Early Watch value)'
WHEN DD09L_TABKAT=6	THEN 'Value cannot be maintained manually (Early Watch value)'
WHEN DD09L_TABKAT=7	THEN 'Value cannot be maintained manually (Early Watch value)'
WHEN DD09L_TABKAT=8	THEN 'Value cannot be maintained manually (Early Watch value)'
WHEN DD09L_TABKAT=9	THEN 'Value cannot be maintained manually (Early Watch value)'
WHEN DD09L_TABKAT=10	THEN 'Value cannot be maintained manually (Early Watch value)'
WHEN DD09L_TABKAT=11	THEN 'Value cannot be maintained manually (Early Watch value)'
WHEN DD09L_TABKAT=12	THEN 'Value cannot be maintained manually (Early Watch value)'
WHEN DD09L_TABKAT=13	THEN 'Value cannot be maintained manually (Early Watch value)'
WHEN DD09L_TABKAT=14	THEN  'Value cannot be maintained manually (Early Watch value)'
ELSE 'Not found' END AS ZF_DD09L_TABKAT_DESC,
	DD02T_DDTEXT,
	USER_ADDR_NAME_TEXTC
INTO BC15_01_IT_DD09L_DD02T
FROM A_DD09L AS A
--Add the name of the table
LEFT JOIN A_DD02T
ON
	A.DD09L_TABNAME=DD02T_TABNAME AND
	DD09L_AS4LOCAL=DD02T_AS4LOCAL AND 
	DD09L_AS4VERS=DD02T_AS4VERS
 -- Add the name of the user who did last changed
LEFT JOIN A_USER_ADDR
ON 
	A_USER_ADDR.USER_ADDR_BNAME=DD09L_AS4USER	
--Rename the fields
EXEC SP_RENAME_FIELD 'BC15_01_','BC15_01_IT_DD09L_DD02T'

GO
