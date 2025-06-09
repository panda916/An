USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_SU51_Identify document types credit memos that are not blocked for processing]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START

-- Script objective: Identify credit memo request type of sale documents have been blocked for processing
-- identified based on description
-- Step 1: select credit memo request type of sale documents from BO05_01_IT_SALE_DOCUMENT(sales document type cube)
EXEC SP_REMOVE_TABLES 'SU51_01_XT_TVAK_CRE_MEMO_BLOCKED'


SELECT DISTINCT 
	TVAK_FAKSK,
	TVAK_AUART,
	TVAKT_BEZEI,
	TVAK_VBTYP,
	TVFST_VTEXT_TVAK,
	ZF_TVAK_VBTYP_DESCRIPTION,
	-- Add flag to show credit memo request type of sale documents are blocked or not
	(
		CASE
			WHEN LEN(TVAK_FAKSK) > 0 THEN 'Yes'
			ELSE 'No'
		END
	) AS ZF_TVAK_FAKSK_BLOCKED_FLAG
INTO SU51_01_XT_TVAK_CRE_MEMO_BLOCKED
FROM BO05_01_IT_TVAK_SALE_DOCUMENT_TYPE
-- Just get document category that related to credit memo
WHERE ZF_TVAK_VBTYP_DESCRIPTION LIKE '%credit memo%'

-- Rename the fields
EXEC SP_RENAME_FIELD 'SU51_01_', 'SU51_01_XT_TVAK_CRE_MEMO_BLOCKED'
GO
