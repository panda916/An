USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_BC03_T16FB_KZFAE_DESC]
AS
--DYNAMIC_SCRIPT_START
BEGIN

--Script objective : create a cube for Release indicator : purchasing document

--Step 1 Create a cube Release indicator : purchasing document , base on table T16FB
EXEC SP_DROPTABLE BC03_01_IT_T16FB_KZFAE_DESC

SELECT DISTINCT
	T16FB_MANDT	,
	T16FB_FRGKE,	
	T16FB_KZFRE,	
	T16FB_KZFAE,
	T16FB_TLFAE ,	
--Add description for Changeability of Purchasing Document During/After Release
	CASE 
		WHEN T16FB_KZFAE= 1 THEN 'Cannot be changed'
		WHEN T16FB_KZFAE= 2 THEN 'Changeable, no new determination of strategy'
		WHEN T16FB_KZFAE= 3 THEN 'Changeable, new release in case of new strategy'
		WHEN T16FB_KZFAE= 4 THEN 'Changeable, new release in case of new strat. or val. change'
		WHEN T16FB_KZFAE= 5 THEN 'Changeable, new release if new strategy/outputted'
		WHEN T16FB_KZFAE= 6 THEN 'Changeable, new rel. if new strat. or value change/outputted'
	ELSE	'Changeable, new release in case of new strategy' END AS ZF_T16FB_KZFAE_DESC,
	T16FE_FRGET,
	IIF(T16FB_TLFAE=0,'Not changeable',CONCAT('If purchasing document value update is <',
							T16FB_TLFAE,
							+'% of original value, then new release not required')) AS ZF_T16FB_TLFAE_DESC
INTO BC03_01_IT_T16FB_KZFAE_DESC
	FROM A_T16FB
LEFT JOIN A_T16FE
ON T16FB_FRGKE=T16FE_FRGKE AND T16FE_SPRAS='EN'
	--Rename the fields
EXEC SP_RENAME_FIELD 'BC03_01_', 'BC03_01_IT_T16FB_KZFAE_DESC'

END 
GO
