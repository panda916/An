USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_BC19_SE16N_TAB_UPDATES]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START
-- Create table display cube
EXEC SP_DROPTABLE 'BC19_01_IT_SE16N_TAB_UPDATES'

SELECT SE16N_CD_KEY_MANDT,
	SE16N_CD_KEY_ID,
	SE16N_CD_KEY_TAB,
	A_DD02T.DD02T_DDTEXT,
	SE16N_CD_KEY_SDATE,
	SE16N_CD_DATA_CHANGE_TYPE,
	SE16N_CD_KEY_UNAME,
	USER_ADDR_NAME_TEXTC,
	USER_ADDR_DEPARTMENT,
	USER_ADDR_NAME1,
	SE16N_CD_DATA_POS,
-- Add SE16N_CD_DATA_CHANGE_TYPE description
	(
		CASE
			WHEN SE16N_CD_DATA_CHANGE_TYPE = 'D' THEN 'Delete'
			WHEN SE16N_CD_DATA_CHANGE_TYPE = 'I' THEN 'Insert'
			WHEN SE16N_CD_DATA_CHANGE_TYPE = 'M' THEN 'Modify'
		END
	) AS ZF_SE16N_CD_DATA_CHANGE_TYPE_DESCRIPTION
INTO BC19_01_IT_SE16N_TAB_UPDATES
FROM A_SE16N_CD_KEY
-- Get some fields from SE16N_CD_DATA table
LEFT JOIN A_SE16N_CD_DATA
ON SE16N_CD_DATA_ID = SE16N_CD_KEY_ID
-- Get DD02T_TABNAME description
LEFT JOIN A_DD02T
ON DD02T_TABNAME = SE16N_CD_KEY_TAB
-- Get user name, department, name 1 of user
LEFT JOIN A_USER_ADDR
ON SE16N_CD_KEY_UNAME = USER_ADDR_BNAME

GO
