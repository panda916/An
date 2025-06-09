USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_BC16_USR02_USERS]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START
EXEC SP_REMOVE_TABLES 'BC16_01_IT_USR02_USERS'

SELECT A_USR02.*
	,USGRPT_TEXT
	,USGRPT_USERGROUP
	,CASE WHEN USR02_PWDINITIAL = 0 THEN '0-Undetermined (Initial)'
	    WHEN USR02_PWDINITIAL = 1 THEN '1-True'
		WHEN USR02_PWDINITIAL = 2 THEN '2-False'
		END AS ZF_PWDINITIAL_DESC
	-- Logic to add text for user type 
	,CASE USR02_USTYP 
		WHEN 'A' THEN 'A-Dialog' 
		WHEN 'B' THEN 'B-System' 
		WHEN 'C' THEN 'C-Communication' 
		WHEN 'L' THEN 'L-Reference' 
		WHEN 'S' THEN 'S-Service' 
		ELSE '' 
	END							AS ZF_USR02_USTYP_SHORT_DESC
              
	-- Logic to give context to meaning of user type 
	,CASE USR02_USTYP 
		WHEN 'A' THEN 'A-Dialog user (regular)' 
		WHEN 'B' THEN 'B-System user (dialog not possible)' 
		WHEN 'C' THEN 'C-Communication user (dialog not possible)' 
		WHEN 'L' THEN 'L-Reference user (dialog not possible)' 
		WHEN 'S' THEN 'S-Service (dialog possible, no expiry)' 
	END							AS ZF_USR02_USTYP_LONG_DESC
	-- Logic to show locked and unlocked accounts 
	,CASE 
		WHEN USR02_UFLAG = 0 THEN '' 
		ELSE 'X' 
	END							AS ZF_USR02_UFLAG 
              
	-- Logic to show reason for lock 
	,CASE USR02_UFLAG 
		WHEN 0 THEN '0-Unlocked' 
		WHEN 32 THEN '32-Locked globally by Admin' 
		WHEN 64 THEN '64-Locked locally by Admin' 
		WHEN 96 THEN '96-Locked globally & locally by Admin' 
		WHEN 128 THEN '128-Locked due to incorrect logins' 
		WHEN 160 THEN '160-Locked due to incorrect logins & globally by Admin' 
		WHEN 192 THEN '192-Locked due to incorrect logins & locally by Admin' 
		WHEN 224 THEN '224-Locked due to incorrect logins & globally & locally by Admin' 
		ELSE '' 
	END							AS ZF_USR02_UFLAG_DESC  
	,A_USR06.USR06_LIC_TYPE
	
	--Add filter for default user 

	,IIF(
	      USR02_BNAME LIKE  'SAP*' 
		  OR USR02_BNAME LIKE 'DDIC' 
		  OR USR02_BNAME LIKE 'EARLYWATCH'
		  OR USR02_BNAME LIKE 'TMSADM'
		  OR USR02_CLASS LIKE 'SUPER', 'Yes','No') AS ZF_USR02_DEFAULT_USER
	,CASE USR02_CODVN
		WHEN 'A' THEN 'Code Version A (Obsolete)'
		WHEN 'B' THEN 'Code Version B (MD5-Based, 8 Characters, Upper-Case, ASCII)'
		WHEN 'C' THEN 'Code Version C (Not Implemented)'
		WHEN 'D' THEN 'Code Version D (MD5-Based, 8 Characters, Upper-Case, UTF-8)'
		WHEN 'E' THEN 'Code Version E (Corrected Code Version D)'
		WHEN 'F' THEN 'Code Version F (SHA1, 40 Characters, Case-Sensitive, UTF-8)'
		WHEN 'G' THEN 'Code Version G = Code Vers. F + Code Vers. B (2 Hash Values)'
		WHEN 'H' THEN 'Code Version H (Generic Hash Procedure)'
		WHEN 'I' THEN 'Code Version I = Code Versions H + F + B (Three Hash Values)'
		WHEN 'X' THEN 'Password Deactivated'
	END AS ZF_USR02_CODVN_DESCRIPTION,
	V_USERNAME_NAME_TEXT
INTO   BC16_01_IT_USR02_USERS
      
-- Include user master data and logon info 
FROM  A_USR02 
      
-- Include users full name 
LEFT JOIN A_V_USERNAME 
ON A_USR02.USR02_BNAME = A_V_USERNAME.V_USERNAME_BNAME 
      
-- Include licence type info 
LEFT JOIN A_USR06 
ON A_USR02.USR02_BNAME = A_USR06.USR06_BNAME 

--Add user group description
LEFT JOIN A_USGRPT
ON USR02_CLASS = USGRPT_USERGROUP AND USGRPT_SPRSL ='EN'


GO
