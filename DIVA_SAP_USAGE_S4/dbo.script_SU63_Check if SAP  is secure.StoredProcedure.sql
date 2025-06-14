USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_SU63_Check if SAP* is secure]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START

-- Script object: Check if SAP* is secure

EXEC SP_REMOVE_TABLES 'SU63_01_RT_PAHI_USERS_SAPSTAR'

SELECT A.*,
	IIF(A.BC14_01_PAHI_PARVALUE = '1','Yes','No') AS ZF_PAHI_PARNAME_PREVENT_SAPSTAR
INTO SU63_01_RT_PAHI_USERS_SAPSTAR
FROM BC14_01_IT_PAHI_ADD_AM_PARAMETER_TEST AS A
INNER JOIN 
	(	
		SELECT BC14_01_PAHI_HOSTNAME,BC14_01_PAHI_PARNAME,MAX(BC14_01_PAHI_PARDATE) AS ZF_BC14_01_PAHI_PARDATE_MAX
		FROM BC14_01_IT_PAHI_ADD_AM_PARAMETER_TEST
				WHERE BC14_01_PAHI_PARNAME='login/no_automatic_user_sapstar'
		GROUP BY BC14_01_PAHI_HOSTNAME,BC14_01_PAHI_PARNAME

	) AS B
	ON A.BC14_01_PAHI_HOSTNAME=B.BC14_01_PAHI_HOSTNAME 
	AND A.BC14_01_PAHI_PARDATE=B.ZF_BC14_01_PAHI_PARDATE_MAX
WHERE A.BC14_01_PAHI_PARNAME='login/no_automatic_user_sapstar'

-- Unname the fields, get BC14_01_ out of field name
EXEC SP_UNNAME_FIELD 'BC14_01_', 'SU63_01_RT_PAHI_USERS_SAPSTAR'

-- Rename the fields
EXEC SP_RENAME_FIELD 'SU63_01_', 'SU63_01_RT_PAHI_USERS_SAPSTAR'
GO
