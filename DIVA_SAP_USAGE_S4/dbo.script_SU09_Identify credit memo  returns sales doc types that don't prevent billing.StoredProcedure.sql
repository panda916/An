USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_SU09_Identify credit memo/ returns sales doc types that don't prevent billing]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START

-- Script objective: Identify credit memo and sales document are blocked or not 
-- because credit memo and return sales document types should be prevented from creating a billing document.
-- Step 1: select data from BO05_01_IT_SALE_DOCUMENT(sales document type cube)


EXEC SP_REMOVE_TABLES 'SU09_01_XT_TVAK_CRE_MEMO_RETURN_SD_TYPE_BLOCK'

SELECT 
	DISTINCT
	TVAK_AUART,
	TVAKT_BEZEI,
	TVAK_KOPGR,
	TVHBT_BEZEI,
	TVAK_LFARV,
	TVAK_FKARV,
	TVAK_FKARA,
	TVAK_FAKSK,
	TVAK_LIFSK,
	TVAK_VBTYP,
	ZF_TVAK_VBTYP_DESCRIPTION,
	TVLKT_VTEXT_TVAK,
	TVFKT_VTEXT_TVAK,
	TVFST_VTEXT_TVAK,
	TVFKT_VTEXT_TVAK_FKARA,
	-- Add flag to show credit memo and return sales document types are blocked or not
	(
		CASE 
			WHEN LEN(TVAK_FAKSK)  > 0  THEN 'Yes'
			ELSE 'No'
		END
	) AS ZF_TVAK_FKASK_BLCK_BILLG
INTO SU09_01_XT_TVAK_CRE_MEMO_RETURN_SD_TYPE_BLOCK
FROM BO05_01_IT_TVAK_SALE_DOCUMENT_TYPE
WHERE TVAK_VBTYP IN ('K','H')

-- Rename the fields
EXEC SP_RENAME_FIELD 'SU09_01_', 'SU09_01_XT_TVAK_CRE_MEMO_RETURN_SD_TYPE_BLOCK'
GO
