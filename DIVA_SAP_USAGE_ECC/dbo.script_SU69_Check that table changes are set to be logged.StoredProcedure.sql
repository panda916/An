USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[script_SU69_Check that table changes are set to be logged]
AS
--DYNAMIC_SCRIPT_START

--Script objective : Check that table changes are set to be logged

--Step 1 filter out the case where PAHI_PARNAME='rec/client'
--Get the latest date only 
EXEC SP_DROPTABLE SU69_01_XT_ENABLE_LOGGING_TABLE

SELECT DISTINCT
A.*
INTO SU69_01_XT_ENABLE_LOGGING_TABLE
FROM BC14_01_IT_PAHI_ADD_AM_PARAMETER_TEST AS A
INNER JOIN 
	(	
		SELECT BC14_01_PAHI_HOSTNAME,BC14_01_PAHI_PARNAME,MAX(BC14_01_PAHI_PARDATE) AS ZF_BC14_01_PAHI_PARDATE_MAX
		FROM BC14_01_IT_PAHI_ADD_AM_PARAMETER_TEST
				WHERE BC14_01_PAHI_PARNAME='rec/client'
		GROUP BY BC14_01_PAHI_HOSTNAME,BC14_01_PAHI_PARNAME

	) AS B
	ON A.BC14_01_PAHI_HOSTNAME=B.BC14_01_PAHI_HOSTNAME 
	AND A.BC14_01_PAHI_PARDATE=B.ZF_BC14_01_PAHI_PARDATE_MAX
WHERE A.BC14_01_PAHI_PARNAME='rec/client'

--Rename the fields
EXEC SP_UNNAME_FIELD 'BC14_01_','SU69_01_XT_ENABLE_LOGGING_TABLE'
EXEC SP_RENAME_FIELD 'SU69_01_','SU69_01_XT_ENABLE_LOGGING_TABLE'


--Step 2/ Get the client information, only get the case production 
--FLag the case which is not have table logging
EXEC SP_DROPTABLE 'SU69_02_RT_T000_PRODUCTIVE'

SELECT DISTINCT A_T000.*,
	-- Add T000_CCCORACTIV description
	(
		CASE
			WHEN T000_CCCORACTIV = '' THEN 'No automatic recording of changes for transport'
			WHEN T000_CCCORACTIV = '1' THEN 'Changes are recorded in transport request'
			WHEN T000_CCCORACTIV = '2' THEN 'Customizing in this client cannot be changed'
			WHEN T000_CCCORACTIV = '3' THEN 'Customizing: Can be changed as req., but cannot be transp.'
		END
	) AS ZF_T000_CCCORACTIV_DESCRIPTION,
	-- Add T000_CCNOCLIIND description
	(
		CASE
			WHEN T000_CCNOCLIIND = '' THEN 'Changes to Repository and cross-client Customizing allowed'
			WHEN T000_CCNOCLIIND = '1' THEN 'No changes to cross-client Customizing objects'
			WHEN T000_CCNOCLIIND = '2' THEN 'No changes to Repository objects'
			WHEN T000_CCNOCLIIND = '3' THEN 'No changes to Repository and cross-client Customizing objs'
		END
	) AS ZF_T000_CCNOCLIIND_DESCRIPTION,
	-- Add T000_CCCOPYLOCK description
	(
		CASE
			WHEN T000_CCCOPYLOCK IS NULL THEN 'Protection level 0: No restriction'
			WHEN T000_CCCOPYLOCK = 'X' THEN 'Protection level 1: No overwriting'
			WHEN T000_CCCOPYLOCK = 'L' THEN 'Protection level 2: No overwriting, no external availability'
		END
	) AS ZF_T000_CCCOPYLOCK_DESCRIPTION,
	CASE T000_CCCATEGORY
		WHEN 'P' THEN 'Production'
		WHEN 'T' THEN 'Test'
		WHEN 'C' THEN 'Customizing'
		WHEN 'D' THEN 'Demo'
		WHEN 'E' THEN 'Training/Education'
		WHEN 'S' THEN 'SAP reference'
	END AS ZF_T000_CCCATEGORY_DESCRIPTION,
	
	CASE T000_CCIMAILDIS
		WHEN '' THEN 'eCATT and CATT Not Allowed'
		WHEN 'X' THEN 'eCATT and CATT Allowed'
		WHEN 'T' THEN 'eCATT and CATT Only Allowed for Trusted RFC'
		WHEN 'E' THEN 'eCATT Allowed, but FUN/ABAP and CATT not Allowed'
		WHEN 'F' THEN 'eCATT allowed, but FUN/ABAP and CATT only for Trusted RFC'
	END AS ZF_T000_CCIMAILDIS_DESCRIPTION,

	IIF(SU69_01_PAHI_PARVALUE IS NOT NULL OR LEN(TRIM(SU69_01_PAHI_PARVALUE))>0,'X','') AS ZF_T000_MANDT_IN_PAHI_FLAG,--Flag the case where client has table or not
	IIF(SU69_01_PAHI_PARVALUE IS NOT NULL OR LEN(TRIM(SU69_01_PAHI_PARVALUE))>0,SU69_01_PAHI_PARVALUE,'') AS ZF_T000_PAHI_JN_KEY_DM -- Add the key which will be used to join with PAHI
INTO SU69_02_RT_T000_PRODUCTIVE
FROM A_T000
INNER JOIN SU69_01_XT_ENABLE_LOGGING_TABLE
ON SU69_01_PAHI_PARVALUE='ALL' OR (SU69_01_PAHI_PARVALUE  LIKE '%'+T000_MANDT+'%')
	WHERE T000_CCCATEGORY='P'

--Remame the fields
EXEC SP_UNNAME_FIELD 'SU69_01_','SU69_02_RT_T000_PRODUCTIVE'
EXEC SP_RENAME_FIELD 'SU69_02_','SU69_02_RT_T000_PRODUCTIVE'



GO
