USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU60_Check if password parameters are correctly configured]
AS
--DYNAMIC_SCRIPT_START

--Script objective: Identify if password parameters are configured compared with the standard test value

--Step 1 Password parameters are configured in accordance with best practices
--Get the latest date

EXEC SP_DROPTABLE 'SU60_01_XT_PAHI_PASSWORD_PARAM'
SELECT DISTINCT
A.*,
CASE WHEN  (A.BC14_01_PAHI_PARNAME= 'login/min_password_diff' AND CAST(A.BC14_01_PAHI_PARVALUE AS INT )< CAST(A.BC14_01_AM_PAHI_TEST_VALUE AS INT)) THEN 'X'
	 WHEN  A.BC14_01_PAHI_PARNAME= 'login/min_password_digits' AND CAST(A.BC14_01_PAHI_PARVALUE AS INT )< CAST(A.BC14_01_AM_PAHI_TEST_VALUE AS INT) THEN 'X'
	 WHEN  A.BC14_01_PAHI_PARNAME= 'login/min_password_lng' AND CAST(A.BC14_01_PAHI_PARVALUE AS INT )< CAST(A.BC14_01_AM_PAHI_TEST_VALUE AS INT) THEN 'X'
	 WHEN  A.BC14_01_PAHI_PARNAME= 'login/min_password_lowercase' AND CAST(A.BC14_01_PAHI_PARVALUE AS INT )< CAST(A.BC14_01_AM_PAHI_TEST_VALUE AS INT) THEN 'X'
	 WHEN  A.BC14_01_PAHI_PARNAME= 'login/min_password_specials' AND CAST(A.BC14_01_PAHI_PARVALUE AS INT )< CAST(A.BC14_01_AM_PAHI_TEST_VALUE AS INT) THEN 'X'
	 WHEN  A.BC14_01_PAHI_PARNAME= 'login/min_password_uppercase' AND CAST(A.BC14_01_PAHI_PARVALUE AS INT )< CAST(A.BC14_01_AM_PAHI_TEST_VALUE AS INT) THEN 'X'
	 WHEN  A.BC14_01_PAHI_PARNAME= 'login/password_compliance_to_current_policy' 
		  AND (CAST(A.BC14_01_PAHI_PARVALUE AS INT )=0  AND CAST(A.BC14_01_AM_PAHI_TEST_VALUE AS INT)=1 )
				THEN 'X'
	 WHEN  A.BC14_01_PAHI_PARNAME= 'login/password_expiration_time' AND CAST(A.BC14_01_PAHI_PARVALUE AS INT )> CAST(A.BC14_01_AM_PAHI_TEST_VALUE AS INT) THEN 'X'
	 WHEN  A.BC14_01_PAHI_PARNAME= 'login/password_history_size' AND CAST(A.BC14_01_PAHI_PARVALUE AS INT )< CAST(A.BC14_01_AM_PAHI_TEST_VALUE AS INT) THEN 'X'
	 WHEN  A.BC14_01_PAHI_PARNAME= 'login/password_logon_usergroup' AND LEN(A.BC14_01_PAHI_PARVALUE)< LEN(A.BC14_01_AM_PAHI_TEST_VALUE) THEN 'X'
	 ELSE '' END
AS ZF_PAHI_PARVALUE_TEST_WEAKER
INTO SU60_01_XT_PAHI_PASSWORD_PARAM
FROM BC14_01_IT_PAHI_ADD_AM_PARAMETER_TEST AS A
INNER JOIN 
	(	
		SELECT BC14_01_PAHI_HOSTNAME,BC14_01_PAHI_PARNAME,MAX(BC14_01_PAHI_PARDATE) AS ZF_BC14_01_PAHI_PARDATE_MAX
		FROM BC14_01_IT_PAHI_ADD_AM_PARAMETER_TEST
				WHERE
					 BC14_01_PAHI_PARNAME= 'login/min_password_diff' OR
					 BC14_01_PAHI_PARNAME= 'login/min_password_digits' OR
					 BC14_01_PAHI_PARNAME= 'login/min_password_letters' OR
					 BC14_01_PAHI_PARNAME= 'login/min_password_lng' OR
					 BC14_01_PAHI_PARNAME= 'login/min_password_lowercase' OR
					 BC14_01_PAHI_PARNAME= 'login/min_password_specials' OR
					 BC14_01_PAHI_PARNAME= 'login/min_password_uppercase' OR
					 BC14_01_PAHI_PARNAME= 'login/password_compliance_to_current_policy' OR
					 BC14_01_PAHI_PARNAME= 'login/password_expiration_time' OR
					 BC14_01_PAHI_PARNAME= 'login/password_history_size' OR
					 BC14_01_PAHI_PARNAME='login/password_logon_usergroup'
		GROUP BY BC14_01_PAHI_HOSTNAME,BC14_01_PAHI_PARNAME
	) AS B
	ON A.BC14_01_PAHI_HOSTNAME=B.BC14_01_PAHI_HOSTNAME 
	AND A.BC14_01_PAHI_PARDATE=B.ZF_BC14_01_PAHI_PARDATE_MAX
	AND A.BC14_01_PAHI_PARNAME=B.BC14_01_PAHI_PARNAME
WHERE 	 
	 A.BC14_01_PAHI_PARNAME= 'login/min_password_diff' OR
	 A.BC14_01_PAHI_PARNAME= 'login/min_password_digits' OR
	 A.BC14_01_PAHI_PARNAME= 'login/min_password_letters' OR
	 A.BC14_01_PAHI_PARNAME= 'login/min_password_lng' OR
	 A.BC14_01_PAHI_PARNAME= 'login/min_password_lowercase' OR
	 A.BC14_01_PAHI_PARNAME= 'login/min_password_specials' OR
	 A.BC14_01_PAHI_PARNAME= 'login/min_password_uppercase' OR
	 A.BC14_01_PAHI_PARNAME= 'login/password_compliance_to_current_policy' OR
	 A.BC14_01_PAHI_PARNAME= 'login/password_expiration_time' OR
	 A.BC14_01_PAHI_PARNAME= 'login/password_history_size' OR
	 A.BC14_01_PAHI_PARNAME='login/password_logon_usergroup' 


--Rename the fields
 EXEC SP_UNNAME_FIELD 'BC14_01_','SU60_01_XT_PAHI_PASSWORD_PARAM'
 EXEC SP_RENAME_FIELD 'SU60_01_','SU60_01_XT_PAHI_PASSWORD_PARAM'
GO
