USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_SU48_Identify sales document types that are not set to check credit limits]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START

-- Script objective: Check which sales document types should have a credit check
-- Step 1: select data from BO05_01_IT_SALE_DOCUMENT (sales document types cube)
EXEC SP_REMOVE_TABLES 'SU48_01_RT_TVAK_CUS_CRE_LIMIT'

SELECT DISTINCT
	TVAK_AUART,
	TVAKT_BEZEI,
	TVAK_KLIMP,
	TVAK_VBTYP,
	ZF_TVAK_VBTYP_DESCRIPTION,
	-- Add check credit limit description
	(
		CASE
			WHEN TVAK_KLIMP = '' THEN 'No credit limit check'
			WHEN TVAK_KLIMP = 'A' THEN 'A - Run simple credit limit check and warning message'
			WHEN TVAK_KLIMP = 'B' THEN 'B - Rund simple redit limit check and error message'
			WHEN TVAK_KLIMP = 'C' THEN 'C - Run simple credit limit check and delivery block'
			WHEN TVAK_KLIMP = 'D' THEN 'D - Credit management: Automatic credit control'
		END
	) AS ZF_TVAK_KLIMP_DESCRIPTION,
	-- Add flag to show sales document types should have a credit check
	(
		CASE
			WHEN LEN(TVAK_KLIMP) > 0 THEN 'No'
			ELSE  'Yes'
		END
	) AS ZF_TVAK_KLIMP_EQ_BLANK_FLAG
INTO SU48_01_RT_TVAK_CUS_CRE_LIMIT
FROM BO05_01_IT_TVAK_SALE_DOCUMENT_TYPE

-- Rename the fields
EXEC SP_RENAME_FIELD 'SU48_01_', 'SU48_01_RT_TVAK_CUS_CRE_LIMIT'
GO
