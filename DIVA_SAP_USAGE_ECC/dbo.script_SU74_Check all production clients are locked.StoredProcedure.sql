USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU74_Check all production clients are locked]
AS
--DYNAMIC_SCRIPT_START

-- Script object:Check all production clients are locked
-- Step 1: select data from T001

EXEC SP_REMOVE_TABLES 'SU74_01_RT_T001_PRODUCTION_CLIENT_BLOCKED'

SELECT DISTINCT
	T001_MANDT,
	T001_BUKRS,
	T001_BUTXT,
	T001_XPROD,
	T000_CCCORACTIV,
	T000_CCNOCLIIND,
	T000_CCCOPYLOCK,
	T000_CCCATEGORY,
	T000_MTEXT,
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
	IIF(T000_CCCORACTIV <> '2', 'Yes','No') AS ZF_T000_CCCORACTIV_NOT_EQ_2_FLAG,
	IIF(T000_CCNOCLIIND = '', 'Yes','No') AS ZF_T000_CCNOCLIIND_EQ_BLANK_FLAG,
	IIF(T000_CCCOPYLOCK = '', 'Yes','No') AS ZF_T000_CCCOPYLOCK_EQ_BLANK_FLAG
INTO SU74_01_RT_T001_PRODUCTION_CLIENT_BLOCKED
FROM A_T001
-- Get changes and transports for client-specific objects, 	maintenance authorization for objects in all clients
-- and protection reg. client copy program and comparison tools
LEFT JOIN A_T000
ON T000_MANDT = T001_MANDT

-- Rename the fields
EXEC SP_RENAME_FIELD 'SU74_01_', 'SU74_01_RT_T001_PRODUCTION_CLIENT_BLOCKED'
GO
