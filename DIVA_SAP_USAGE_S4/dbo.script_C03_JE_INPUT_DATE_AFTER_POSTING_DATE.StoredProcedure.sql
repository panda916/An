USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE      PROCEDURE [dbo].[script_C03_JE_INPUT_DATE_AFTER_POSTING_DATE]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START
BEGIN

/*Change history comments*/

/*
	Title			:	C03: Entry date and posting date of JE
	  
	--------------------------------------------------------------
	Update history
	--------------------------------------------------------------
	Date		    | Who |	Description
	19/09/2022        DAT   First version for Sony ECC
*/
--Step 1/ Identify journal entries for which the input date is after the posting date
-- and the posting date is in a diferent period to the input date


EXEC SP_DROPTABLE 'C03_01_XT_JE_CPUDT_AFTER_BUDAT_PER'
SELECT 
	DISTINCT
	B04_08_IT_FIN_GL.*,
	CASE 
		WHEN DATEDIFF(DAY,B04_GL_ACDOCA_BUDAT,B04_GL_ACDOCA_CPUDT) >=1 AND DATEDIFF(DAY,B04_GL_ACDOCA_BUDAT,B04_GL_ACDOCA_CPUDT) <= 32 THEN '1 - 32 days'
		WHEN DATEDIFF(DAY,B04_GL_ACDOCA_BUDAT,B04_GL_ACDOCA_CPUDT) >= 33 AND DATEDIFF(DAY,B04_GL_ACDOCA_BUDAT,B04_GL_ACDOCA_CPUDT) <= 60 THEN '33 - 60 days'
		WHEN DATEDIFF(DAY,B04_GL_ACDOCA_BUDAT,B04_GL_ACDOCA_CPUDT) >= 61 AND DATEDIFF(DAY,B04_GL_ACDOCA_BUDAT,B04_GL_ACDOCA_CPUDT) <= 90 THEN '61 - 90 days'
		WHEN DATEDIFF(DAY,B04_GL_ACDOCA_BUDAT,B04_GL_ACDOCA_CPUDT) >= 91 AND DATEDIFF(DAY,B04_GL_ACDOCA_BUDAT,B04_GL_ACDOCA_CPUDT) <= 120 THEN '91 - 120 days'
		WHEN DATEDIFF(DAY,B04_GL_ACDOCA_BUDAT,B04_GL_ACDOCA_CPUDT) >= 121 AND DATEDIFF(DAY,B04_GL_ACDOCA_BUDAT,B04_GL_ACDOCA_CPUDT) <= 180 THEN '121 - 180 days'
		WHEN DATEDIFF(DAY,B04_GL_ACDOCA_BUDAT,B04_GL_ACDOCA_CPUDT) >= 181 AND DATEDIFF(DAY,B04_GL_ACDOCA_BUDAT,B04_GL_ACDOCA_CPUDT) <= 360 THEN '181 - 360 days'
		ELSE '>360 days' 
	END AS ZF_BKPF_CPUDT_MINUS_BUDAT_BUCKETS,
	T001_BUTXT,
	T003T_LTEXT,
	MAKT_MAKTX,
	MARA_MTART,
	T134T_MTBEZ,
	V_USERNAME_NAME_TEXT,
	KNA1_NAME1,
	LFA1_NAME1
INTO C03_01_XT_JE_CPUDT_AFTER_BUDAT_PER
FROM B04_08_IT_FIN_GL
LEFT JOIN A_T001
ON B04_GL_ACDOCA_RBUKRS = T001_BUKRS
LEFT JOIN A_T003T
ON B04_GL_ACDOCA_BLART = T003T_BLART
LEFT JOIN A_MAKT
ON B04_GL_ACDOCA_MATNR = MAKT_MATNR
LEFT JOIN A_MARA
ON B04_GL_ACDOCA_MATNR = MARA_MATNR
LEFT JOIN A_T134T
ON MARA_MTART = T134T_MTART
LEFT JOIN A_V_USERNAME
ON B04_GL_ACDOCA_USNAM = V_USERNAME_BNAME
LEFT JOIN A_KNA1
ON B04_GL_ACDOCA_KUNNR = KNA1_KUNNR
LEFT JOIN A_LFA1
ON B04_GL_ACDOCA_LIFNR = LFA1_LIFNR
WHERE DATEDIFF(DAY,B04_GL_ACDOCA_BUDAT,B04_GL_ACDOCA_CPUDT) >=1 AND NOT(MONTH(B04_GL_ACDOCA_BUDAT) = MONTH(B04_GL_ACDOCA_CPUDT) AND YEAR(B04_GL_ACDOCA_BUDAT) = YEAR(B04_GL_ACDOCA_CPUDT))

--/*Drop temporary tables*/

EXEC SP_UNNAME_FIELD 'B04_GL_', 'C03_01_XT_JE_CPUDT_AFTER_BUDAT_PER'

END
GO
