USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU34_ Check if purchase documents are blocked if changed after release]
AS
--DYNAMIC_SCRIPT_START

--Script objective: Identify the release indicator of purchasing document allow to changeable,no new determination of strategy

--Step 1 Get the list of release indicator
EXEC SP_DROPTABLE SU34_01_RT_T16FB_RELEASE_INDICATOR
SELECT *
INTO SU34_01_RT_T16FB_RELEASE_INDICATOR
FROM BC03_01_IT_T16FB_KZFAE_DESC

--STep 2 Rename fields
EXEC SP_UNNAME_FIELD 'BC03_01_', 'SU34_01_RT_T16FB_RELEASE_INDICATOR'
EXEC SP_RENAME_FIELD 'SU34_01_', 'SU34_01_RT_T16FB_RELEASE_INDICATOR'




GO
