USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_SU46_50_Identify pricing procedures that allow for manual pricing]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START

-- Script objective: Check customer specific pricing to sales orders and prevent manual changes to pricing
--Step 1: Check the restrictions on manual entry is configured in conditions in sales
EXEC SP_REMOVE_TABLES 'SU46_50_01_RT_T685A_PROCDEDURE_ALLOW_MANUAL_PRICING'

SELECT DISTINCT
	BC13_01_IT_T685A_SALES_CONDITION_TYPES.*,
	-- Add flag to show which conditions in sales have manual entry or not
	(
		CASE
			WHEN T685A_KMANU IN ('', 'A', 'C') THEN 'Yes'
			ELSE 'No'
		END
	) AS ZF_T685A_KMANU_EQ_A_C_BLANK_FLAG
INTO SU46_50_01_RT_T685A_PROCDEDURE_ALLOW_MANUAL_PRICING
FROM BC13_01_IT_T685A_SALES_CONDITION_TYPES
-- Filter on application in sales/distribution am_scope
INNER JOIN AM_SALES_DIST_KAPPL_CODES
ON T685A_KAPPL = KAPPL

-- Rename the fields
EXEC SP_RENAME_FIELD 'SU46_50_01_', 'SU46_50_01_RT_T685A_PROCDEDURE_ALLOW_MANUAL_PRICING'
GO
