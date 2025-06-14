USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROCEDURE [dbo].[script_B32_ECC_AMAZON_SALES_INFO]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START
/*  Change history comments
	Update history 
	-------------------------------------------------------
	Date            | Who   |  Description 
	--  23-03-2022	| Thuan	| Remove MANDT field in join
*/
-- Step 1 : Insert value for B32_01_IT_COPA_CUBE table in ECC system.

INSERT INTO DIVA_MASTER_SCRIPT..B32_01_IT_COPA_CUBE
SELECT 
	DISTINCT 
	B18_COPA_MANDT, -- 
	B18B_COPA_BUKRS, -- Company code.
	B18B_COPA_GJAHR, -- Fiscal year.
	B18B_COPA_BELNR, -- Document number.
	B18B_COPA_POSNR, -- Line item.
	B18B_COPA_REC_WAERS_COC, -- Company currency.
	B18B_COPA_REC_WAERS_CUC, -- Custom currency.
	B18B_ZF_BUDAT_POSTED_IN_PER_FLAG, -- COPA_BUDAT between date1, date2.
 --   B18B_COMA_M_COPA_field_label -- We can ignore this field in ECC and S4.
    B18B_COMA_M_Hierarchy_L1,  
	B18B_ZF_COPA_FIELD_VALUE_COC, -- COPA value coc
	B18B_ZF_COPA_FIELD_VALUE_CUC, -- COPA value cuc
	B18_COPA_VKORG, -- Sale organization.
	B18_COPA_VTWEG, -- Distribution channel.
	B18_COPA_KAUFN, -- Sale order number.
	B18_COPA_FKART, -- Bliing type.
	B18_COPA_SPART, -- Divison
	B18_COPA_KNDNR, -- Customer.
	B18_COPA_ARTNR, -- Product number.
	B18_ZF_GJAHR_PERDE_FISCAL_YQ, -- Quarter
	B18_ZF_BUDAT_CALENDAR_YM, -- Month
	B18_ZF_TOKYO_6_DIGIT, -- Tokyo 6 digit.
	B18_ZF_COPA_PROD_L1,
	B18_ZF_COPA_PROD_L2,
	B18_ZF_COPA_PROD_L3,
	B18_ZF_COPA_PROD_L4,
	B18_ZF_COPA_PROD_L5,
	B18_COPA_BUDAT, -- Posting date.
	B18_COPA_PRCTR, -- Profit center.
	B18_COPA_KOKRS, 
	B18_COPA_SKOST,
	B18_ZF_TRADING_PARTNER,
	B18_ZF_TRADING_PARTNER_NAME, -- Trading partner
	B18_COPA_VRGAR, -- Record type.
	B18_COPA_ABSMG,
	B18_COPA_KDPOS,
	B18_COPA_RBELN,
	B18_COPA_RPOSN,
	-- Some amount fields only appear in S4.
	0 B18_ZF_ACDOCA_KSL_S,
	0 B18_ZF_ACDOCA_OSL_S,
	'' ,
	'',
	'',
	-- Amount in GPW system.
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	'',
	'',
	'',
	'',
	'',
	'',
	'',
	'',
	'',
	'ECC6' as ZF_ECC_S4_FLAG,
	 DB_NAME() as ZF_DATABASE_FLAG
FROM B18B_08_IT_COPA_HIERARCHY_VALUE A
	INNER JOIN B18_09_IT_COPA_TRANSACTION B 
	ON A.B18B_COPA_BUKRS = B.B18_COPA_BUKRS
	AND A.B18B_COPA_GJAHR = B.B18_COPA_GJAHR
	AND A.B18B_COPA_BELNR = B.B18_COPA_BELNR
	AND A.B18B_COPA_POSNR = B.B18_COPA_POSNR  	
---- Remove dup same region 
LEFT JOIN DIVA_MASTER_SCRIPT..B32_01_IT_COPA_CUBE C ON A.B18B_COPA_BUKRS = C.B32_COPA_BUKRS
                                                                                        AND A.B18B_COPA_GJAHR = C.B32_COPA_GJAHR 
																						AND A.B18B_COPA_BELNR = C.B32_COPA_BELNR
                                                                                        AND A.B18B_COPA_POSNR = C.B32_COPA_POSNR

WHERE C.B32_COPA_POSNR IS NULL AND
  EXISTS ((
							SELECT *
									FROM DIVA_MASTER_SCRIPT..AM_AMAZON_SALE_DATA
									WHERE DBO.REMOVE_LEADING_ZEROES(B18_COPA_KNDNR) = dbo.REMOVE_LEADING_ZEROES(Customer)
									AND DB_NAME() LIKE '%' + Entity + '%'
				
				)     
			)


-- Step 2 : Insert value for B32_02_IT_COMPANY_INFO table.

INSERT INTO DIVA_MASTER_SCRIPT..B32_02_IT_COMPANY_INFO
SELECT 
	DISTINCT T001_BUKRS,
	T001_BUTXT,
	T001_WAERS,
	T001_BUKRS+' - '+T001_BUTXT 	
	FROM A_T001 A
WHERE EXISTS 
-- Only get company codes in B32_01_IT_COPA_CUBE table
	(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_01_IT_COPA_CUBE
		WHERE B32_01_IT_COPA_CUBE.B32_COPA_BUKRS = A.T001_BUKRS
	)
-- Remove dup same region
AND NOT EXISTS
	(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_02_IT_COMPANY_INFO B
		WHERE B.B32_T001_BUKRS = A.T001_BUKRS
	)

-- Step 3/ Insert value for B32_03_IT_CUSTOMER_INFO table.  

INSERT INTO DIVA_MASTER_SCRIPT..B32_03_IT_CUSTOMER_INFO
SELECT 
	DISTINCT 
		KNA1_KUNNR,
		KNA1_NAME1,
		KNA1_KTOKD,
		KNA1_BRAN1,
		KNA1_BRAN2,
		KNA1_BRAN3,
		KNA1_BRAN4,
		KNA1_BRAN5,
		KNA1_KUNNR+' - '+KNA1_NAME1,
		INTERCO_TXT,
		T077X_TXT30
FROM    A_KNA1 A
LEFT JOIN AM_T077X ON A.KNA1_KTOKD = T077X_KTOKD
WHERE EXISTS
-- Only get customers in B32_01_IT_COPA_CUBE table
	(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_01_IT_COPA_CUBE
		WHERE B32_01_IT_COPA_CUBE.B32_COPA_KNDNR = A.KNA1_KUNNR
	)
-- Remove dup same region
AND NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_03_IT_CUSTOMER_INFO B
		WHERE B.B32_KNA1_KUNNR = A.KNA1_KUNNR
)

-- Step 4 : Insert value for B32_04_IT_MATERIAL_INFO table.

INSERT INTO DIVA_MASTER_SCRIPT..B32_04_IT_MATERIAL_INFO
SELECT 
	DISTINCT 
		MAKT_MANDT,
		MAKT_MATNR, -- Material number
		MAKT_MAKTX, -- Material description.
		MARA_MATKL, -- Material Group.
		T023T_WGBEZ, -- Material group description.
		MARA_MTART, -- Material type,
		T134T_MTBEZ, -- Material type description.
		MAKT_MATNR

FROM  A_MAKT A
-- Only get material in B32_01_IT_COPA_CUBE table.
INNER JOIN DIVA_MASTER_SCRIPT..B32_01_IT_COPA_CUBE ON B32_COPA_ARTNR = A.MAKT_MATNR
-- Get Material group number.
LEFT JOIN A_MARA ON  A.MAKT_MATNR = MARA_MATNR
-- Get Material group desc.
LEFT JOIN A_T023T ON MARA_MATKL =  T023T_MATKL
-- Get Material type.
LEFT JOIN A_T134T ON MARA_MTART = T134T_MTART
WHERE A.MAKT_MATNR <> ''
-- Remove dup same region
AND NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_04_IT_MATERIAL_INFO B
		WHERE B.B32_MAKT_MATNR = A.MAKT_MATNR
)

-- Step 5 : Insert value for B32_05_IT_SALE_ORG_INFO table.

INSERT INTO DIVA_MASTER_SCRIPT..B32_05_IT_SALE_ORG_INFO
SELECT 
	DISTINCT 
		TVKOT_VKORG, -- Sales Organization
		TVKOT_VTEXT -- Sales Organization name.
		
FROM  A_TVKOT A
-- Only get sale organzation in B32_01_IT_COPA_CUBE table.
INNER JOIN DIVA_MASTER_SCRIPT..B32_01_IT_COPA_CUBE ON B32_COPA_VKORG = A.TVKOT_VKORG
WHERE 
-- Remove dup same region
NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_05_IT_SALE_ORG_INFO B
		WHERE B.B32_TVKOT_VKORG = A.TVKOT_VKORG
)
AND TVKOT_VKORG <> ''

-- Step 6 : Insert value for B32_06_IT_DISTRIBUTION_INFO table.

INSERT INTO DIVA_MASTER_SCRIPT..B32_06_IT_DISTRIBUTION_INFO
SELECT 
	DISTINCT 
		TVTWT_VTWEG, -- Distribution Channel
		TVTWT_VTEXT -- Distribution Channel name.
		
FROM  A_TVTWT A
-- Only get Distribution Channel in B32_01_IT_COPA_CUBE table.
INNER JOIN DIVA_MASTER_SCRIPT..B32_01_IT_COPA_CUBE ON B32_COPA_VTWEG = A.TVTWT_VTWEG
WHERE 
-- Remove dup same region
NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_06_IT_DISTRIBUTION_INFO B
		WHERE B.B32_TVTWT_VTWEG = A.TVTWT_VTWEG
)
AND TVTWT_VTWEG <> ''


-- Step 7 : Insert value for B32_07_IT_DIVISION_INFO table.

INSERT INTO DIVA_MASTER_SCRIPT..B32_07_IT_DIVISION_INFO
SELECT 
	DISTINCT 
		TSPAT_SPART, -- Division
		TSPAT_VTEXT -- Division name.
		
FROM  A_TSPAT A
-- Only get Division in B32_01_IT_COPA_CUBE table.
INNER JOIN DIVA_MASTER_SCRIPT..B32_01_IT_COPA_CUBE ON B32_COPA_SPART = A.TSPAT_SPART
WHERE 
-- Remove dup same region
NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_07_IT_DIVISION_INFO B
		WHERE B.B32_TSPAT_SPART = A.TSPAT_SPART
)
AND TSPAT_SPART <> ''


-- Step 8 : Insert value for B32_08_IT_BILL_DOC_TYPE_INFO table.

INSERT INTO DIVA_MASTER_SCRIPT..B32_08_IT_BILL_DOC_TYPE_INFO
SELECT 
	DISTINCT 
		TVFKT_FKART , -- Billing Type
		TVFKT_VTEXT -- Billing Type name.
		
FROM  A_TVFKT A
-- Only get Billing Type in B32_01_IT_COPA_CUBE table.
INNER JOIN DIVA_MASTER_SCRIPT..B32_01_IT_COPA_CUBE ON B32_COPA_FKART = A.TVFKT_FKART
WHERE 
-- Remove dup same region
NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_08_IT_BILL_DOC_TYPE_INFO B
		WHERE B.B32_TVFKT_FKART = A.TVFKT_FKART
)
AND TVFKT_FKART <> ''

-- Step 9 : Insert value for B32_09_IT_SALE_DOC_TYPE_INFO table.
INSERT INTO DIVA_MASTER_SCRIPT..B32_09_IT_SALE_DOC_TYPE_INFO
SELECT 
	DISTINCT 
		VBAK_VBELN , -- Sale document number
		VBAK_VKORG,  -- Sales Organization
		VBAK_AUART, -- Sale document type.
		VBAK_AUGRU, -- Order reason. 
		TVAKT_BEZEI, -- Sale document type text.
		TVAUT_BEZEI, -- Order reason text.	
		VBAK_VBELN+VBAK_VKORG
FROM  A_VBAK A
-- Only get sale document type in B32_01_IT_COPA_CUBE table.
INNER JOIN DIVA_MASTER_SCRIPT..B32_01_IT_COPA_CUBE ON VBAK_VBELN = B32_COPA_KAUFN AND B32_COPA_VKORG = VBAK_VKORG
-- Get sale document type text.
LEFT JOIN A_TVAKT ON TVAKT_AUART = VBAK_AUART
-- Get order reason text
LEFT JOIN A_TVAUT ON VBAK_AUGRU =  TVAUT_AUGRU
WHERE 
-- Remove dup same region
NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_09_IT_SALE_DOC_TYPE_INFO B
		WHERE B.B32_VBAK_VBELN = A.VBAK_VBELN
)
AND VBAK_VBELN <> ''

-- Step 10 : Insert value for B32_10_IT_PROFIT_CENTER_INFO table.
INSERT INTO DIVA_MASTER_SCRIPT..B32_10_IT_PROFIT_CENTER_INFO
SELECT 
	DISTINCT 
		CEPCT_PRCTR , -- Profit center.
		CEPCT_LTEXT,  -- Profit center desc.	
		CEPCT_KOKRS
FROM  B00_CEPCT A
-- Only get profit center in B32_01_IT_COPA_CUBE table.
INNER JOIN DIVA_MASTER_SCRIPT..B32_01_IT_COPA_CUBE ON CEPCT_PRCTR = B32_COPA_PRCTR AND B32_COPA_KOKRS = CEPCT_KOKRS
WHERE 
-- Remove dup same region
NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_10_IT_PROFIT_CENTER_INFO B
		WHERE B.B32_CEPCT_PRCTR = A.CEPCT_PRCTR
)
AND CEPCT_PRCTR <> ''

-- Step 11 : Insert value for B32_11_IT_COST_CENTER_INFO table.
INSERT INTO DIVA_MASTER_SCRIPT..B32_11_IT_COST_CENTER_INFO
SELECT 
	DISTINCT 
		CSKT_KOSTL , -- Cost center.
		CSKT_LTEXT,  -- Cost center desc.	
		CSKT_KOKRS
FROM  B00_CSKT A
-- Only get Cost center in B32_01_IT_COPA_CUBE table.
INNER JOIN DIVA_MASTER_SCRIPT..B32_01_IT_COPA_CUBE ON CSKT_KOSTL = B32_COPA_SKOST AND B32_COPA_KOKRS = CSKT_KOKRS
WHERE 
-- Remove dup same region
NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_11_IT_COST_CENTER_INFO B
		WHERE B.B32_CSKT_KOSTL = A.CSKT_KOSTL
)
AND CSKT_KOSTL <> ''
GO
