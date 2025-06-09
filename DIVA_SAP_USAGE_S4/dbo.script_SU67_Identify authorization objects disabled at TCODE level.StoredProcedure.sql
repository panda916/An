USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU67_Identify authorization objects disabled at TCODE level]
AS
--DYNAMIC_SCRIPT_START

-- HL |	2024-09-23: Rename the fields of the table A_USOBX_C
-- Step 0: Rename the fields of A_USOBX_C as in the S4 master script, the prefix is renamed from USOBX_C_ to USOBX_

		EXEC SP_UNNAME_FIELD 'USOBX_', 'A_USOBX_C'
		EXEC SP_RENAME_FIELD 'USOBX_C_', 'A_USOBX_C'

--Step 1: load table A_USOBX and inner join with table A_USOBX_C and then identify if USOBX_OKFLAG = 'U' 
--OR NULL which means they are not maintained


EXEC SP_DROPTABLE 'SU67_01_RT_USOBX_OKFLAG_U';
SELECT A_USOBX.*,
       A_USOBX_C.*       ,
		CASE	   	
			WHEN USOBX_TYPE='TR' THEN	'Transaction'
			WHEN USOBX_TYPE='RE' THEN	'?'
			WHEN USOBX_TYPE='RF' THEN	'RFC Function Module'
			WHEN USOBX_TYPE='HT' THEN	'Hash Value for TADIR Object'
			WHEN USOBX_TYPE='HS' THEN 	'Hash Value for External Service'
			WHEN USOBX_TYPE='HC' THEN	'Collision Hash Value' 
			ELSE 'Not found' END AS ZF_USOBX_TYPE_DESC,

	   CASE 
			WHEN USOBX_OKFLAG='N' THEN 'No authorization check'
			WHEN USOBX_OKFLAG='X' THEN 'Authorization check takes place'
			WHEN USOBX_OKFLAG='U' THEN 'Not maintained'
			WHEN USOBX_OKFLAG='Y' THEN 'Authorization check takes place; default values in USOBT'
			WHEN USOBX_OKFLAG='V' THEN 'Authorization check takes place, no default values'
			WHEN USOBX_OKFLAG IS NULL THEN 'Not maintained'
			ELSE 'Not found' END AS ZF_USOBX_OKFLAG_DESC,
	   CASE 
		    WHEN USOBX_C_OKFLAG = 'N' THEN 'No authorization check'
			WHEN USOBX_C_OKFLAG = 'X' THEN 'Authorization check takes place'
			WHEN USOBX_C_OKFLAG = 'U' THEN 'Not maintained'
			WHEN USOBX_C_OKFLAG = 'Y' THEN 'Authorization check takes place; default values in USOBT'
			WHEN USOBX_C_OKFLAG IS NULL THEN 'Not maintained'
			WHEN USOBX_C_OKFLAG = 'V' THEN 'Authorization check takes place, no default values'
			ELSE 'Not found' END AS ZF_USOBX_C_OKFLAG_DESC
INTO SU67_01_RT_USOBX_OKFLAG_U
FROM A_USOBX
INNER JOIN A_USOBX_C
ON   USOBX_NAME = USOBX_C_NAME 
     AND USOBX_OBJECT = USOBX_C_OBJECT 
     AND USOBX_TYPE = USOBX_C_TYPE ;

--Step 2: Filter out all the authorization objects that are disable at TCODE level 

EXEC SP_DROPTABLE 'SU67_02_XT_USOBX_C_OFLAG_N_U_OR_NULL'
SELECT DISTINCT SU67_01_RT_USOBX_OKFLAG_U.*
INTO SU67_02_XT_USOBX_C_OFLAG_N_U_OR_NULL
FROM SU67_01_RT_USOBX_OKFLAG_U
WHERE  USOBX_OKFLAG IN ('X', 'Y' ,'V') AND USOBX_C_OKFLAG IN ('N', 'U', NULL) 

-- Step 3: Find users and profiles with access to T-codes with authorization objects disabled
-- Step 3.1: Insert data from SOD cube into new table

EXEC SP_REMOVE_TABLES 'SU67_03_TT_UST10S_AGR_PROFILE_OBJCT_AUTH_FIELD_VALUE'
SELECT *
INTO SU67_03_TT_UST10S_AGR_PROFILE_OBJCT_AUTH_FIELD_VALUE
FROM B22_09_IT_UST10S_AGR_PROFILE_OBJCT_AUTH_FIELD_VALUE

-- Step 3.2: Reformat data of ZF_AGR_UST12_VON and ZF_AGR_UST12_BIS field 
--Update the combined user auhorization object list, to convert the * symbol to % (SQL uses % as regular expression to re-present many characters instead of *)
	
UPDATE SU67_03_TT_UST10S_AGR_PROFILE_OBJCT_AUTH_FIELD_VALUE
SET ZF_AGR_UST12_VON = REPLACE(ZF_AGR_UST12_VON, '%', '[#]')

UPDATE SU67_03_TT_UST10S_AGR_PROFILE_OBJCT_AUTH_FIELD_VALUE
SET ZF_AGR_UST12_VON = REPLACE(ZF_AGR_UST12_VON, '*', '%'),
ZF_AGR_UST12_BIS = REPLACE(ZF_AGR_UST12_BIS, '*', '%')

--Update the combined user auhorization object list, we will ingore $ values because SAP also skips them in the initial authorization check.
UPDATE SU67_03_TT_UST10S_AGR_PROFILE_OBJCT_AUTH_FIELD_VALUE
SET ZF_AGR_UST12_VON = '',
ZF_AGR_UST12_BIS = ''
WHERE ZF_AGR_UST12_VON LIKE '$%'

--Update the combined user auhorization object list, we will ingore ', '' values because SAP also skips them in the initial authorization check.
UPDATE SU67_03_TT_UST10S_AGR_PROFILE_OBJCT_AUTH_FIELD_VALUE
SET ZF_AGR_UST12_VON = '%',
ZF_AGR_UST12_BIS = ''
WHERE ZF_AGR_UST12_VON = '''' OR ZF_AGR_UST12_VON = ''''''

--Remove the authorization object field with blank value to speed up the script.
DELETE SU67_03_TT_UST10S_AGR_PROFILE_OBJCT_AUTH_FIELD_VALUE
WHERE ZF_AGR_UST12_VON = ''

-- Step 3.3: List of users relating to the exceptions

EXEC SP_DROPTABLE 'SU67_04_XT_UST12_BNAME_TCODE_AUTH_OBJ_DISABLED'

SELECT DISTINCT USR02_BNAME,
				AT.*,
				A_TSTCT.TSTCT_TTEXT,
				A_V_USERNAME.V_USERNAME_NAME_TEXT
INTO SU67_04_XT_UST12_BNAME_TCODE_AUTH_OBJ_DISABLED
FROM SU67_03_TT_UST10S_AGR_PROFILE_OBJCT_AUTH_FIELD_VALUE A
INNER JOIN SU67_02_XT_USOBX_C_OFLAG_N_U_OR_NULL AT 
ON (ZF_AGR_UST12_VON = '%')
						OR (ZF_AGR_UST12_BIS = '' 
						AND AT.USOBX_NAME LIKE A.ZF_AGR_UST12_VON)
						OR (ZF_AGR_UST12_BIS <> '' 
						AND AT.USOBX_NAME BETWEEN REPLACE(ZF_AGR_UST12_VON, '%', '') AND REPLACE(ZF_AGR_UST12_BIS, '%', ''))
LEFT JOIN A_TSTCT -- Get transaction code description
ON TSTCT_TCODE = AT.USOBX_NAME
LEFT JOIN A_V_USERNAME -- Get username
ON USR02_BNAME = V_USERNAME_BNAME


EXEC SP_RENAME_FIELD 'SU67_01_','SU67_01_RT_USOBX_OKFLAG_U';
EXEC SP_RENAME_FIELD 'SU67_02_','SU67_02_XT_USOBX_C_OFLAG_N_U_OR_NULL';
EXEC SP_RENAME_FIELD 'SU67_04_','SU67_04_XT_UST12_BNAME_TCODE_AUTH_OBJ_DISABLED';

GO
