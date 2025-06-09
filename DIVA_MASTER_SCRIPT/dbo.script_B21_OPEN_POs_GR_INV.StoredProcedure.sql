USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROCEDURE [dbo].[script_B21_OPEN_POs_GR_INV]
  
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START

/* 
	Title        :  B21_OPEN_POs
    Description  :  Open POs
       
    -------------------------------------------------------------- 
    Update history 
    -------------------------------------------------------------- 
    Date		|  Who    |  Description 
	14-09-2020	   THUAN     Start create Open POs script 
	23-03-2022	   Thuan	 Remove MANDT field in join
*/ 

--Declare parameters here
--EXEC SP_REMOVE_TABLES 'B21%'

DECLARE
	 @currency nvarchar(max)			= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'currency')
	,@date1 nvarchar(max)				= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'date1')
	,@date2 nvarchar(max)				= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'date2')
	,@downloaddate nvarchar(max)		= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'downloaddate')
	,@exchangeratetype nvarchar(max)	= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'exchangeratetype')
	,@language1 nvarchar(max)			= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'language1')
	,@language2 nvarchar(max)			= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'language2')
	,@year nvarchar(max)				= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'year')
	,@id nvarchar(max)					= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'id')
	,@LIMIT_RECORDS INT		= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS')



-- Step 1/ Filter POs on those that are
-- Step 1.1 / Get some fields missing in PO cube 
-- EKPO_ELIKZ (Delivery completed)
-- EKPO_EREKZ (Final Invoice Indicator)
-- EKPO_LOEKZ (Deletion Indicator in Purchasing Document)
-- EKKO_KDATB (Start of Validity Period)
-- EKKO_KDATE (End of Validity Period)
-- EKKO_FRGSX (Release strategy)  EKKO_FRGSX <> '' and EKKO_FRGSX not null then check 
-- EKKO_FRGKE (Release Indicator: Purchasing Document) Mising field
-- EKKO_FRGGR (Release group) Mising field  
-- EKKO_FRGRL (Release Not Yet Completely Effected) Missing field
-- EKKO_FRGZU (Release status)
-- EKKO_BSART (Add document type) 


--CREATE INDEX PO_CUBE_MANDT_EBELN ON B09_13_IT_PTP_POS (B09_EKKO_MANDT,B09_EKKO_EBELN);
--CREATE INDEX EKPO_MANDT_EBELN ON A_EKPO (EKPO_MANDT,EKPO_EBELN);
--CREATE INDEX EKKO_MANDT_EBELN ON A_EKPO (EKPO_MANDT,EKPO_EBELN);

EXEC SP_DROPTABLE 'B21_01_TT_POS'
SELECT DISTINCT   
	A.*, 
	EKPO_ELIKZ as B09_EKPO_ELIKZ,
	EKPO_EREKZ as B09_EKPO_EREKZ,
	EKKO_KDATB as B09_EKKO_KDATB,
	EKKO_KDATE as B09_EKKO_KDATE,
	EKKO_FRGSX as B09_EKKO_FRGSX,
	EKKO_FRGKE as B09_EKKO_FRGKE, 
	EKKO_FRGZU as B09_EKKO_FRGZU,
	EKKO_STATU as B09_EKKO_STATU,
	EKKO_FRGGR AS B09_EKKO_FRGGR, ---(Release group) Mising field  
  EKKO_FRGRL AS B09_EKKO_FRGRL ---(Release Not Yet Completely Effected) Missing field
INTO B21_01_TT_POS
FROM B09_13_IT_PTP_POS AS A 

LEFT JOIN A_EKPO AS B
	ON A.B09_EKKO_EBELN =	B.EKPO_EBELN AND 
		A.B09_EKPO_EBELP = B.EKPO_EBELP
LEFT JOIN A_EKKO AS C
	ON A.B09_EKKO_EBELN = C.EKKO_EBELN
WHERE B09_EKKO_BSTYP = 'F'

-- Step 1.2/ Filter POs on those that are.

EXEC SP_DROPTABLE 'B21_02_TT_PO_N_D_EXP'

SELECT *
INTO B21_02_TT_PO_N_D_EXP
FROM B21_01_TT_POS
WHERE
-- Delivery not completed.
	B09_EKPO_ELIKZ = ''  AND 
-- Final invoice not received
	B09_EKPO_EREKZ = '' AND 
-- Not deleted
	B09_EKPO_LOEKZ = '' AND
	B09_EKKO_LOEKZ = '' AND 
-- Validity start date (KDATB) is before extraction date
  (
	B09_EKKO_KDATB < (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'downloaddate')	
	OR B09_EKKO_KDATB ='1900-01-01' 
	OR B09_EKKO_KDATB IS NULL
  ) 
	AND	 
-- Validity end date after today or validity end date is null
	(
		B09_EKKO_KDATE >  CONVERT(VARCHAR(10), getdate(), 111) 
		OR B09_EKKO_KDATE IS NULL 
		OR B09_EKKO_KDATE ='1900-01-01'
	)
-- Company currency amount (local amount) > 10
	AND B09_ZF_EKPO_NETWR_COC > 10

EXEC SP_DROPTABLE 'B21_01_TT_POS'

-- Step 1.3 Create list of PO release
-- For those for which there IS a mention of release strategy (FRGSX), release indicator (FRGKE) or release group (FRGGR)

EXEC SP_DROPTABLE 'B21_03_TT_PO_REL'

SELECT *
INTO B21_03_TT_PO_REL
FROM B21_02_TT_PO_N_D_EXP
WHERE 
(
	(
		B09_EKKO_FRGSX <> '' 
		OR B09_EKKO_FRGKE <> ''
		--OR B09_EKKO_FRGGR <> ''
	)
	AND 
	(
		--B09_EKKO_FRGRL = '' AND 
		B09_EKKO_FRGZU <> ''
	)
)
OR
(
	B09_EKKO_FRGSX = ''
	AND B09_EKKO_FRGKE = ''
--	AND B09_EKKO_FRGGR = ''
--	AND B09_EKKO_FRGRL = ''
)



EXEC SP_DROPTABLE 'B21_02_TT_PO_N_D_EXP'
-- Step 2/ Identify POs for which total value in PO history does not reach PO original value
-- Step 2.1/ Total net order value (local value base on BUKRS and currency is USD).

EXEC SP_DROPTABLE 'B21_04_TT_TOT_PO'

SELECT
	B09_EKPO_BUKRS,
	B09_EKPO_EBELN,
	B09_EKPO_EBELP,
-- PO value (doc)
	SUM(B09_ZF_EKPO_NETWR_TCURFA) as 'B09_ZF_EKPO_NETWR_TCURFA',
-- PO value (cuc)
	SUM(B09_ZF_EKPO_NETWR_CUC) as 'B09_ZF_EKPO_NETWR_CUC',
-- PO value (COC)
	SUM(B09_ZF_EKPO_NETWR_COC) as 'B09_ZF_EKPO_NETWR_COC'
INTO B21_04_TT_TOT_PO
FROM B21_03_TT_PO_REL
GROUP BY B09_EKPO_BUKRS, B09_EKPO_EBELN, B09_EKPO_EBELP


-- Step 2.2/ Create list of GRs and INV amount from EKBE
-- Base on B_SS12 script in ACL.
-- Step 2.2.1/ From EKBE get some fields such as EKPO_BUKRS, EKPO_MEINS, EKPO_BPRME from EKKO and EKPO tables.

EXEC SP_DROPTABLE 'B21_05_IT_EKBE_EKPO_INFO'
SELECT DISTINCT 
	A.*,
	IIF(EKBE_SHKZG = 'S',1,-1) * EKBE_MENGE as 'ZF_EKBE_MENGE_S'
	,CONVERT(money,A.EKBE_WRBTR * (CASE WHEN (A.EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_DOC.TCURX_Factor,1)) AS ZF_EKBE_WRBTR_S
	,A_T001.T001_WAERS
	,CONVERT(money,A.EKBE_DMBTR * (CASE WHEN (A.EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_Factor,1)) AS ZF_EKBE_DMBTR_S
	,@currency					AS AM_GLOBALS_CURRENCY
	,CONVERT(money,A.EKBE_DMBTR * (CASE WHEN (A.EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) * COALESCE(TCURX_CC.TCURX_Factor,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)) AS ZF_EKBE_WBRTR_S_CUC,
	C.EKPO_BUKRS,
	C.EKPO_MEINS,
	C.EKPO_BPRME,
	CASE 
		WHEN A.EKBE_VGABE ='1' THEN 'Goods receipt' 
		WHEN A.EKBE_VGABE IN ('2','3','O','K') THEN 'Invoice' 
	END		AS ZF_EKBE_VGABE_DESC
	
INTO B21_05_IT_EKBE_EKPO_INFO
FROM A_EKBE as A
LEFT JOIN A_EKPO AS C
	ON A.EKBE_EBELN = C.EKPO_EBELN
	AND A.EKBE_EBELP = C.EKPO_EBELP
-- Add company code currency
		LEFT JOIN A_T001
		ON  C.EKPO_BUKRS = A_T001.T001_BUKRS
			
-- Add currency factor from company currency to USD

LEFT JOIN B00_IT_TCURF TCURF_CUC
ON A_T001.T001_WAERS = TCURF_CUC.TCURF_FCURR
AND TCURF_CUC.TCURF_TCURR  = @currency  
AND TCURF_CUC.TCURF_GDATU = (
	SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
	FROM B00_IT_TCURF
	WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
			B00_IT_TCURF.TCURF_TCURR  = @currency  AND
			B00_IT_TCURF.TCURF_GDATU <= EKBE_BUDAT
	ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
	)
-- Add exchange rate from company currency to USD
LEFT JOIN B00_IT_TCURR TCURR_CUC
	ON A_T001.T001_WAERS = TCURR_CUC.TCURR_FCURR
	AND TCURR_CUC.TCURR_TCURR  = @currency  
	AND TCURR_CUC.TCURR_GDATU = (
		SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
		FROM B00_IT_TCURR
		WHERE A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
				B00_IT_TCURR.TCURR_TCURR  = @currency  AND
				B00_IT_TCURR.TCURR_GDATU <= EKBE_BUDAT
		ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
		) 

-- Add currency factor from document currency to local currency

LEFT JOIN B00_IT_TCURF TCURF_COC
ON EKBE_WAERS = TCURF_COC.TCURF_FCURR
AND TCURF_COC.TCURF_TCURR  = T001_WAERS  
AND TCURF_COC.TCURF_GDATU = (
	SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
	FROM B00_IT_TCURF
	WHERE EKBE_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
			B00_IT_TCURF.TCURF_TCURR  = T001_WAERS  AND
			B00_IT_TCURF.TCURF_GDATU <= EKBE_BUDAT
	ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
	)


-- Add currency conversion factors for company code currency
		LEFT JOIN B00_TCURX TCURX_CC 
		ON 
	       A_T001.T001_WAERS = TCURX_CC.TCURX_CURRKEY 
-- Add currency conversion factor for document currency
		LEFT JOIN B00_TCURX TCURX_DOC
		ON 
		   A.EKBE_WAERS = TCURX_DOC.TCURX_CURRKEY


-- Step 2.3/ Split EKBE into lines with GRN info (VGABE = 1) and lines with invoice info VGABE = 2 (For Sony VGABE in  2,3,)
-- Step 2.3.1/ Create GRs table

EXEC SP_DROPTABLE 'B21_06_IT_EKBE_GR'
SELECT * 
INTO B21_06_IT_EKBE_GR
FROM B21_05_IT_EKBE_EKPO_INFO
WHERE EKBE_VGABE = '1'

-- Step 2.3.2/ Create INV table

EXEC SP_DROPTABLE 'B21_07_IT_EKBE_INV'
SELECT * 
INTO B21_07_IT_EKBE_INV
FROM B21_05_IT_EKBE_EKPO_INFO
WHERE EKBE_VGABE IN ('2','3','O','K')

-- Step 2.4/ Calculate the total quantity and amount GRs per PO
-- Step 2.4.1/ Total Amount and PO quantity base on company code, PO number, line item and PO unit of measure

EXEC SP_DROPTABLE 'B21_06A_TT_EKBE_GR_PO_UNIT'

SELECT 
	EKPO_BUKRS, 
	EKBE_EBELN, 
	EKBE_EBELP, 
	EKPO_MEINS, 
	SUM(EKBE_MENGE) as 'ZF_EKBE_MENGE_GR',
	SUM(ZF_EKBE_MENGE_S) as 'ZF_EKBE_MENGE_S_GR',
-- Document currency
	SUM(ZF_EKBE_WRBTR_S) as 'ZF_EKBE_WRBTR_GR_S'
INTO B21_06A_TT_EKBE_GR_PO_UNIT
FROM B21_06_IT_EKBE_GR
GROUP BY EKPO_BUKRS, EKBE_EBELN, EKBE_EBELP, EKPO_MEINS 

-- Step 2.4.2/ Total Amount and quantity base on company code, PO number, line item and Order price unit
-- OPU mean Oder price unit.
-- EKBE we don't have EKBE_BPMNG field.
-- So we only can calculate local amount base on company code, PO number, line item and order price unit.

EXEC SP_DROPTABLE 'B21_06B_TT_EKBE_GR_OPU'

SELECT 
	EKPO_BUKRS, 
	EKBE_EBELN, 
	EKBE_EBELP, 
	EKPO_BPRME, 
	SUM(ZF_EKBE_WRBTR_S) as 'ZF_EKBE_WRBTR_GR_S'
INTO B21_06B_TT_EKBE_GR_OPU
FROM B21_06_IT_EKBE_GR
GROUP BY EKPO_BUKRS, EKBE_EBELN, EKBE_EBELP, EKPO_BPRME 



-- Step 2.5/ Calculte the total quantity and amount of invoices per PO
-- Step 2.5.1/ Total local amount and PO quantity base on company code, PO number, line item and PO unit of measure

EXEC SP_DROPTABLE 'B21_07A_TT_EKBE_INV_PO_UNIT'

SELECT 
	EKPO_BUKRS, 
	EKBE_EBELN, 
	EKBE_EBELP, 
	EKPO_MEINS, 
	SUM(EKBE_MENGE) as 'ZF_EKBE_MENGE_INV',
	SUM(ZF_EKBE_MENGE_S) as 'ZF_EKBE_MENGE_S_INV',
	SUM(ZF_EKBE_WRBTR_S) as 'ZF_EKBE_WRBTR_INV_S'
INTO B21_07A_TT_EKBE_INV_PO_UNIT
FROM B21_07_IT_EKBE_INV
GROUP BY EKPO_BUKRS, EKBE_EBELN, EKBE_EBELP, EKPO_MEINS 

-- Step 2.5.2/ Total local amount and quantity base on company code, PO number, line item and Order price unit
-- OPU mean Oder price unit.
-- EKBE we don't have EKBE_BPMNG field.
-- So we only can calculate local amount base on company code, PO number, line item and order price unit.

EXEC SP_DROPTABLE 'B21_07B_TT_EKBE_INV_OPU'

SELECT 
	EKPO_BUKRS, 
	EKBE_EBELN, 
	EKBE_EBELP, 
	EKPO_BPRME, 
	SUM(ZF_EKBE_WRBTR_S) as 'ZF_EKBE_WRBTR_INV_S'
INTO B21_07B_TT_EKBE_INV_OPU
FROM B21_07_IT_EKBE_INV
GROUP BY EKPO_BUKRS, EKBE_EBELN, EKBE_EBELP, EKPO_BPRME 


-- Step 2.6/ Create a list of purchase order.

EXEC SP_DROPTABLE 'B21_08_TT_POS_MEINS_BPRME'
SELECT  
	EKPO_BUKRS, 
	EKBE_EBELN, 
	EKBE_EBELP, 
	EKPO_MEINS, 
	EKPO_BPRME 
INTO B21_08_TT_POS_MEINS_BPRME
FROM B21_05_IT_EKBE_EKPO_INFO
WHERE EKBE_VGABE IN ('1','2','3','O','K')
GROUP BY EKPO_BUKRS, EKBE_EBELN, EKBE_EBELP, EKPO_MEINS, EKPO_BPRME 

-- Step 2.7/ Join the total GRNs and Invoices per PO back to this list

EXEC SP_DROPTABLE 'B21_09_TT_TOT_GR_IN_PO'

SELECT 
	A.*,
	ZF_EKBE_MENGE_GR,
	ZF_EKBE_MENGE_S_GR,
	B.ZF_EKBE_WRBTR_GR_S,
	D.ZF_EKBE_MENGE_INV,
	D.ZF_EKBE_MENGE_S_INV,
	D.ZF_EKBE_WRBTR_INV_S
INTO B21_09_TT_TOT_GR_IN_PO
FROM B21_08_TT_POS_MEINS_BPRME AS A
-- GRs amount base on company code,  PO number, line item and PO unit of measure
LEFT JOIN B21_06A_TT_EKBE_GR_PO_UNIT AS B
	ON A.EKPO_BUKRS = B.EKPO_BUKRS 
	AND A.EKBE_EBELN = B.EKBE_EBELN 
	AND A.EKBE_EBELP = B.EKBE_EBELP
	AND A.EKPO_MEINS = B.EKPO_MEINS
-- GRs quantity base on company code, PO number, line item and Order price unit
-- Note : EKBE in SONY we don't have EKBE_BPMNG field.
LEFT JOIN B21_06B_TT_EKBE_GR_OPU AS C
	ON A.EKPO_BUKRS = C.EKPO_BUKRS
	AND A.EKBE_EBELN = C.EKBE_EBELN
	AND A.EKBE_EBELP = C.EKBE_EBELP
	AND A.EKPO_BPRME = C.EKPO_BPRME
-- INVs amount base on company code,  PO number, line item and PO unit of measure
LEFT JOIN B21_07A_TT_EKBE_INV_PO_UNIT AS D
	ON A.EKPO_BUKRS = D.EKPO_BUKRS 
	AND A.EKBE_EBELN = D.EKBE_EBELN 
	AND A.EKBE_EBELP = D.EKBE_EBELP
	AND A.EKPO_MEINS = D.EKPO_MEINS
-- INVs quantity base on company code, PO number, line item and Order price unit )
LEFT JOIN B21_07B_TT_EKBE_INV_OPU AS F
	ON A.EKPO_BUKRS = F.EKPO_BUKRS
	AND A.EKBE_EBELN = F.EKBE_EBELN
	AND A.EKBE_EBELP = F.EKBE_EBELP
	AND A.EKPO_BPRME = F.EKPO_BPRME

EXEC SP_DROPTABLE 'B21_06A_TT_EKBE_GR_PO_UNIT'
EXEC SP_DROPTABLE 'B21_06B_TT_EKBE_GR_OPU'
EXEC SP_DROPTABLE 'B21_07A_TT_EKBE_INV_PO_UNIT'
EXEC SP_DROPTABLE 'B21_07B_TT_EKBE_INV_OPU'
EXEC SP_DROPTABLE 'B21_08_TT_POS_MEINS_BPRME'
-- Step 2.8/ Join OPEN PO with GRs and INVs base on company code, PO number and line item.
-- Then compare INVs amount, GRs amount with open PO amount.
-- Only care cases like INVs amount >= PO amount or GRs amount >= PO amount.
-- For Total Allow for tolerance of 5 % (PO amount > INV amount and PO amount > GRs amount)
-- But SONY we only care INVs amount >= PO amount or GRs amount >= PO amount.

EXEC SP_DROPTABLE 'B21_10_TT_TOT_PO_GR_IN'

SELECT A.*,
	B.ZF_EKBE_WRBTR_GR_S,
	B.ZF_EKBE_WRBTR_INV_S
INTO B21_10_TT_TOT_PO_GR_IN
FROM B21_04_TT_TOT_PO AS A
LEFT JOIN B21_09_TT_TOT_GR_IN_PO AS B
	ON A.B09_EKPO_BUKRS = B.EKPO_BUKRS
	AND A.B09_EKPO_EBELN = B.EKBE_EBELN
	AND A.B09_EKPO_EBELP = B.EKBE_EBELP
-- Update 01/06/2021 Keep all OPEN PO records. No filter out in SQL.
--WHERE 
--	B.ZF_EKBE_WRBTR_INV_S >= B09_ZF_EKPO_NETWR_TCURFA
--	OR
--	B.ZF_EKBE_WRBTR_GR_S >= B09_ZF_EKPO_NETWR_TCURFA

EXEC SP_DROPTABLE 'B21_04_TT_TOT_PO'
EXEC SP_DROPTABLE 'B21_09_TT_TOT_GR_IN_PO'

-- Step 2.9/ Add PO number, line item that containt INVs amount > PO amount or GRs amount > PO amount back to full OPEN PO data.
-- Add 1 flag compare between GRs amount and PO amount : "GRs amount > PO amount" or "GRs amount =  PO amount".
-- Add 1 flag compare between INVs amount and PO amount : "INVs amount > PO amount" or "INVs amount =  PO amount".

EXEC SP_DROPTABLE 'B21_11_TT_TOT_INV_GR_GREATER_PO'

SELECT 
DISTINCT 
	A.*,
	B.ZF_EKBE_WRBTR_GR_S, 
	B.ZF_EKBE_WRBTR_INV_S, 
	IIF(ZF_EKBE_WRBTR_INV_S > A.B09_ZF_EKPO_NETWR_TCURFA,'INV amount > PO amount','INV amount <= PO amount') as ZF_INV_GREATER_PO_AMOUNT,
	IIF(ZF_EKBE_WRBTR_GR_S > A.B09_ZF_EKPO_NETWR_TCURFA,'GR amount > PO amount','GR amount <= PO amount') as ZF_GR_GREATER_PO_AMOUNT
INTO B21_11_TT_TOT_INV_GR_PO 
FROM B21_03_TT_PO_REL AS A
INNER JOIN  B21_10_TT_TOT_PO_GR_IN AS B
	ON A.B09_EKPO_BUKRS = B.B09_EKPO_BUKRS
		AND A.B09_EKPO_EBELN = B.B09_EKPO_EBELN
		AND A.B09_EKPO_EBELP = B.B09_EKPO_EBELP

EXEC SP_DROPTABLE 'B21_10_TT_TOT_PO_GR_IN'
EXEC SP_DROPTABLE 'B21_03_TT_PO_REL'		
-- Step 3/ Add a flag to show if the PO has been approbated within 1 year prior to the extraction 

-- Step 3.1/ From result from step 2.9 ( list of open POs and INVs amount >= PO amount or GRs amount >= PO amount).
-- Filter BEDAT (Purchasing document date) < download date - 180

EXEC SP_DROPTABLE 'B21_12_TT_CR_6M_PR_EXT'

SELECT *,
IIF(B09_EKKO_BEDAT < (SELECT DATEADD(day,-180,(SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'downloaddate'))),'X','') AS 'ZF_CR_6M_ED'
INTO B21_12_TT_CR_6M_PR_EXT
FROM B21_11_TT_TOT_INV_GR_PO

EXEC SP_DROPTABLE 'B21_11_TT_TOT_INV_GR_PO'
-- Step 3.2/ Add GL account and GL account text
-- Add Posting key text
-- Add Document type text
-- Item text
-- Create index 
-- Note SPNI region we dont have MKPF table so i get document type from BKPF table.
-- Add ageing bucket
-- In ACL we PO join GL by company code, PO number and line item . But 1 PO number and line item from PO cube maybe have many line in BSEG. So it will make duplication value.
-- I create 1 table from BSEG where PO number and line item exist in PO. In Qlik link PO with GL to get GL, Document type...
-- Add spend type from AM_SPEND_CATEGORY table ( product or non product)
--CREATE INDEX PO_BUKRS_EBELN_EBELP ON B21_12_TT_CR_6M_PR_EXT(B09_EKPO_BUKRS,B09_EKPO_EBELN,B09_EKPO_EBELP);
--CREATE INDEX GL_BUKRS_EBELN_EBELP ON B04_11_IT_FIN_GL(B04_BSEG_BUKRS,B04_BSEG_EBELN,B04_BSEG_EBELP);

EXEC SP_DROPTABLE 'B21_13_IT_BSEG_INFO'

SELECT DISTINCT 
	B04_BSEG_EBELN,
	B04_BSEG_EBELP,
	B04_BSEG_HKONT, 
	SKAT_TXT20, 
	SKAT_TXT50, 
	B04_BKPF_BLART,
	TBSLT_LTEXT, 
	B04_BSEG_BSCHL,
	T003T_LTEXT, 
	B04_BSEG_SGTXT,
	AM_SPEND_CATEGORY.SPCAT_SPEND_TYPE,
	B04_ZF_BSEG_DMBTR_S,
	B04_ZF_BSEG_DMBTR_S_CUC,
	B04_BSEG_BUKRS
INTO B21_13_IT_BSEG_INFO
FROM  B04_11_IT_FIN_GL
LEFT JOIN A_T001                                             
	ON  A_T001.T001_BUKRS = B04_11_IT_FIN_GL.B04_BSEG_BUKRS   

-- Add GL acoounts text.
LEFT JOIN A_SKAT
	ON  A_SKAT.SKAT_SAKNR = B04_11_IT_FIN_GL.B04_BSEG_HKONT AND
		A_SKAT.SKAT_KTOPL = A_T001.T001_KTOPL AND
		A_SKAT.SKAT_SPRAS = 'EN'
-- Add document type
LEFT JOIN B00_T003T
           ON B04_BKPF_BLART = B00_T003T.T003T_BLART
LEFT JOIN B00_TBSLT
			ON  B04_BSEG_UMSKZ = B00_TBSLT.TBSLT_UMSKZ 
			AND B04_BSEG_BSCHL = B00_TBSLT.TBSLT_BSCHL
--Get Spend category
LEFT JOIN AM_SPEND_CATEGORY
	ON DBO.REMOVE_LEADING_ZEROES(B04_11_IT_FIN_GL.B04_BSEG_HKONT) = DBO.REMOVE_LEADING_ZEROES(AM_SPEND_CATEGORY.SPCAT_GL_ACCNT)
WHERE EXISTS(
		SELECT TOP 1 1
		FROM B21_12_TT_CR_6M_PR_EXT
		WHERE B04_BSEG_BUKRS = B09_EKPO_BUKRS
		AND B04_BSEG_EBELN = B09_EKPO_EBELN
	)
-- Step 3.3/ Add the ageing bucket 
-- Add 2 flag for final table.
-- ZF_MAX_AEDAT_KDATB
-- ZF_AGEING_BUCKET
-- Get material text

EXEC SP_DROPTABLE 'B21_14_IT_OPEN_PO_GR_INV'

SELECT DISTINCT 
B21_12_TT_CR_6M_PR_EXT.*,
	CASE 
			WHEN B09_EKKO_AEDAT > B09_EKKO_KDATB THEN B09_EKKO_AEDAT
			WHEN B09_EKKO_KDATB > B09_EKKO_AEDAT THEN B09_EKKO_KDATB
			ELSE B09_EKKO_AEDAT 
	END AS ZF_MAX_AEDAT_KDATB,
	CONCAT(YEAR(B09_EKKO_BEDAT),' - ',RIGHT('0' + CAST(MONTH(B09_EKKO_BEDAT) AS NVARCHAR(2)),2)) AS ZF_EKKO_BEDAT_YM,
	MAKT_MAKTG,
	CAST('' as nvarchar(100)) ZF_AGEING_BUCKET,
	CAST('' as nvarchar(100)) ZF_COMPARE_INV_OPEN_PO,
	CAST('' as nvarchar(100)) ZF_COMPARE_GR_OPEN_PO,
	CAST('' as nvarchar(100)) ZF_COMPARE_INV_OPEN_PO_FLAG,
	CAST('' as nvarchar(100)) ZF_COMPARE_GR_OPEN_PO_FLAG
INTO B21_14_IT_OPEN_PO_GR_INV	
FROM B21_12_TT_CR_6M_PR_EXT
LEFT JOIN A_MAKT
ON B09_EKPO_MATNR = MAKT_MATNR

EXEC SP_DROPTABLE 'B21_12_TT_CR_6M_PR_EXT'

UPDATE B21_14_IT_OPEN_PO_GR_INV
SET ZF_AGEING_BUCKET =
(
	CASE 
			WHEN DATEDIFF(DAY,ZF_MAX_AEDAT_KDATB,@downloaddate) <= 180 THEN '1: 0 TO 6 MONTHS'
			WHEN DATEDIFF(DAY,ZF_MAX_AEDAT_KDATB,@downloaddate) > 180 AND DATEDIFF(DAY,ZF_MAX_AEDAT_KDATB,@downloaddate)  <= 365 THEN '2: 6 TO 12 MONTHS'
			WHEN DATEDIFF(DAY,ZF_MAX_AEDAT_KDATB,@downloaddate) > 365 AND DATEDIFF(DAY,ZF_MAX_AEDAT_KDATB,@downloaddate)  <= 545 THEN '3: 12 TO 18 MONTHS'
			WHEN DATEDIFF(DAY,ZF_MAX_AEDAT_KDATB,@downloaddate) > 545 AND DATEDIFF(DAY,ZF_MAX_AEDAT_KDATB,@downloaddate)  <= 730 THEN '4: 18 TO 24 MONTHS'
			ELSE '5: 24 MONTHS OR OV' 
	END
)


-- Step 3.4 / Update 4 fields comparison between the amount INV vs Open PO and GR and Open PO.

UPDATE B21_14_IT_OPEN_PO_GR_INV
SET 

-- Flag invoice amount and Open PO amount
ZF_COMPARE_INV_OPEN_PO =
	CASE 
			WHEN ZF_EKBE_WRBTR_INV_S > B09_ZF_EKPO_NETWR_TCURFA   THEN '>'
			WHEN ZF_EKBE_WRBTR_INV_S = B09_ZF_EKPO_NETWR_TCURFA   THEN '='
			ELSE '<' 
	END ,
-- GR amount - Open PO amount
-- Flag GR amount and Open PO amount
ZF_COMPARE_GR_OPEN_PO =
	CASE 
			WHEN ZF_EKBE_WRBTR_GR_S > B09_ZF_EKPO_NETWR_TCURFA  THEN '>'
			WHEN ZF_EKBE_WRBTR_GR_S = B09_ZF_EKPO_NETWR_TCURFA   THEN '='
			ELSE '<' 
	END ,
ZF_COMPARE_INV_OPEN_PO_FLAG = 
	CASE 
			WHEN ZF_EKBE_WRBTR_INV_S > B09_ZF_EKPO_NETWR_TCURFA  THEN 'Invoice amount > Open PO amount'
			WHEN ZF_EKBE_WRBTR_INV_S = B09_ZF_EKPO_NETWR_TCURFA  THEN 'Invoice amount = Open PO amount'
			ELSE 'Invoice amount < Open PO amount' 
	END ,
ZF_COMPARE_GR_OPEN_PO_FLAG = 
	CASE 
			WHEN ZF_EKBE_WRBTR_GR_S > B09_ZF_EKPO_NETWR_TCURFA    THEN 'GR amount > Open PO amount'
			WHEN ZF_EKBE_WRBTR_GR_S = B09_ZF_EKPO_NETWR_TCURFA    THEN 'GR amount = Open PO amount'
			ELSE 'GR amount < Open PO amount' 
	END 




-- Step 4/ Rename fields for final table before load it into QLik.

-- Step 4.1 B21_14 Comparison table GR, INV and PO.

EXEC SP_UNNAME_FIELD 'B09_' , 'B21_14_IT_OPEN_PO_GR_INV' 
EXEC SP_UNNAME_FIELD 'B04_' , 'B21_14_IT_OPEN_PO_GR_INV' 
EXEC sp_RENAME_FIELD 'B21_14_', 'B21_14_IT_OPEN_PO_GR_INV'

-- Step 4.2 OPen PO with some information in GL table.

EXEC SP_UNNAME_FIELD 'B04_' , 'B21_13_IT_BSEG_INFO' 
EXEC sp_RENAME_FIELD 'B21_13_', 'B21_13_IT_BSEG_INFO'

-- Step 4.3 Full EKBE table.

EXEC sp_RENAME_FIELD 'B21_05_', 'B21_05_IT_EKBE_EKPO_INFO'

-- Step 4.4 GR table and INV table.
EXEC sp_RENAME_FIELD 'B21_06_', 'B21_06_IT_EKBE_GR'

EXEC sp_RENAME_FIELD 'B21_07_', 'B21_07_IT_EKBE_INV'

EXEC SP_REMOVE_TABLES '%_TT_%'
GO
