USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU14_Identify vendors that don't have duplicate invoice check set]
AS
--DYNAMIC_SCRIPT_START

--Script objective: Identify vendors that don't have duplicate invoice check set

--STep 1/ Get the information from supplier cube relate to the test
--From TMODU_FAUNA we can check the status field 
--TMODU_MODIF will be the position inside the status field
--In this data set
-- duplicate invoice check set (REPRF), the status field will be T077K_FAUFS
--Base on these, we can get TMODU_MODIF, which is the position inside T077L_FAUFS


--For the status string field (FAUSA,FAUSF,...)
-- . means optional, + required and - suppress.
EXEC SP_DROPTABLE SU14_01_RT_LFA1_LFB1_REPRF_CHECK

SELECT DISTINCT
	BP01_01_LFB1_LIFNR,
	BP01_01_LFB1_BUKRS,
	BP01_01_LFA1_NAME1,
	BP01_01_LFA1_KTOKK,
	BP01_01_T077Y_TXT30,
	BP01_01_LFB1_REPRF ,
	BP01_01_T001_BUTXT,
	T077K_FAUSF,
	SUBSTRING(T077K_FAUSF,
					(
						SELECT CAST(TMODU_MODIF AS INT) AS ZF_TMODU_MODIF_POSITION FROM A_TMODU WHERE TMODU_TABNM='LFB1' AND TMODU_FELDN='REPRF'
					)
						,1) AS ZF_DUP_INV_VERIFICATION_STATUS,
	CASE 	SUBSTRING(T077K_FAUSF,(SELECT CAST(TMODU_MODIF AS INT) AS ZF_TMODU_MODIF_POSITION FROM A_TMODU WHERE TMODU_TABNM='LFB1' AND TMODU_FELDN='REPRF'),1)
		WHEN '.' THEN 'Optional'
		WHEN '+' THEN 'Required'
		WHEN '-' THEN 'Suppress'
		END AS ZF_DUP_INV_VERIFICATION_STATUS_DESC
INTO SU14_01_RT_LFA1_LFB1_REPRF_CHECK
FROM BP01_01_IT_SUPP
LEFT JOIN A_T077K
	ON T077K_KTOKK=BP01_01_LFA1_KTOKK
 

--Rename the fields
EXEC SP_UNNAME_FIELD 'BP01_01_','SU14_01_RT_LFA1_LFB1_REPRF_CHECK'
EXEC  SP_RENAME_FIELD 'SU14_01_','SU14_01_RT_LFA1_LFB1_REPRF_CHECK'

GO
