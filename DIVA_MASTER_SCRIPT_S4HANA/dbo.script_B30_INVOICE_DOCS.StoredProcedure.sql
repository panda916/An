USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[script_B30_INVOICE_DOCS]
AS

--DYNAMIC_SCRIPT_START.

/*  Change history comments
	Update history 
	-------------------------------------------------------
	Date            | Who   |  Description 
	24-03-2022	| Thuan	| Remove MANDT field in join
	19-09-2024	| HL	| Added field from SAP USAGE
*/
    DECLARE 	 
			 @currency nvarchar(max)			= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'currency')
			,@date1 nvarchar(max)				= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date1')
			,@date2 nvarchar(max)				= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date2')
			,@downloaddate nvarchar(max)		= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'downloaddate')
			,@exchangeratetype nvarchar(max)	= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'exchangeratetype')
			,@language1 nvarchar(max)			= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language1')
			,@language2 nvarchar(max)			= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language2')
			,@year nvarchar(max)				= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'year')
			,@id nvarchar(max)					= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'id')
			,@LIMIT_RECORDS INT					= CAST((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS') AS INT)


SET ROWCOUNT @LIMIT_RECORDS
DECLARE @dateformat varchar(3)
SET @dateformat   = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'dateformat')
SET DATEFORMAT @dateformat;
--	Step 9: Extract all invoice document from VBRK AND VBRP base on VBFA sale document flow table
	
	EXEC SP_REMOVE_TABLES 'B30_01_IT_INVOICE_DOCS'
	SELECT 
		   VBRK_MANDT,
		   VBRK_GJAHR, --HL: Added for SAP USAGE dashboard
		   VBRK_VBELN,
		   VBRP_NETWR,
		   VBRP_POSNR, -- Item nr
		   VBRK_FKART, -- Billing type
		   TVFKT_VTEXT, -- Get billing type desc
		   VBRK_FKTYP, -- Billing category
		 B00_DD07T_FKTYP.DD07T_DDTEXT ZF_VBRK_FKTYP_DESC, -- Get billing category desc
		   VBRP_PSTYV, -- Sale item category
		   TVAPT_VTEXT, --Item category desc
		   @currency ZF_CUSTOM_CURRENCY,
		   VBRK_WAERK, -- SD document currency
		   VBRK_VKORG, -- Sale orangization
		   TVKOT_VTEXT, --Sale organization desc,
		   B00_TVKO.TVKO_BUKRS,
		   B00_TVKO.TVKO_BUKRS_MAPPING,
			--BUKRS_MAPPING,
		   VBRK_VTWEG, -- Distribution channel
		   TVTWT_VTEXT, -- Distribution channel desc
		   VBRK_FKDAT, -- Billing date
		   VBRK_KONDA, -- Price group (customer)
		   T188T_VTEXT, -- Price group desc
		   VBRK_BZIRK, -- Sales district
		   T171T_BZTXT, -- Sale district desc
		   VBRK_PLTYP, -- Price list type
		   T189T_PTEXT, -- Price list type desc
		   VBRK_INCO1, --Incoterm part 1
		   VBRK_INCO2, -- Incoterm part 2
		   VBRK_KALSM, -- Price procedure
		   VBRK_ZTERM, -- Payment term
		   TVZBT_VTEXT, -- Payment term desc
		   VBRK_ZLSCH, -- Payment method
		   T042ZT_TEXT2, --Payment method desc
		   VBRK_ERNAM, -- Entry user
		   VBRK_ERDAT, -- Entry date
		   VBRK_AEDAT, -- Change on
		   VBRK_KUNAG, -- Sold-to-party
		   A_KNA1_KUNAG.KNA1_NAME1 ZF_KUNAG_NAME1, -- Name
		   A_KNA1_KUNAG.KNA1_ERDAT ZF_KUNAG_ERDAT, -- Customer created date
		   A_KNA1_KUNAG.KNA1_ERNAM ZF_KUNAG_ERNAM,
		   T005U_BEZEI, --Country name
		   A_KNA1_KUNAG.KNA1_PSTLZ ZF_KUNAG_PSTLZ, -- Postal code
		   T005T_LANDX, --Country text
		   A_KNA1_KUNAG.KNA1_ORT01 ZF_KUNAG_ORT01,-- City
		   A_KNA1_KUNAG.KNA1_STRAS ZF_KUNAG_STRAS, -- Street
		   VBRK_KUNRG, -- Payer
		   A_KNA1_KUNRG.KNA1_NAME1 ZF_KUNRG_NAME1,
		   A_KNA1_KUNRG.KNA1_ERDAT ZF_KUNRG_ERDAT,
		   A_KNA1_KUNRG.KNA1_PSTLZ ZF_KUNRG_PSTLZ,
		   A_KNA1_KUNRG.KNA1_ORT01 ZF_KUNRG_ORT01,
		   A_KNA1_KUNRG.KNA1_ERNAM ZF_KUNRG_ERNAM,
		   VBRK_KDGRP, -- Customer group
		   T151T_KTEXT, --Customer group desc
		   VBRP_ERNAM, -- User created object (item),
		   HEADER_USR_INFO.V_USERNAME_NAME_TEXT AS VBRK_ERNAM_NAME_TEXT,
		   ITEM_USR_INFO.V_USERNAME_NAME_TEXT AS VBRP_ERNAM_NAME_TEXT,
		   VBRP_ERDAT, -- Item entry date,
		   VBRK_ERZET,
		   VBRP_MATKL, -- Material group
		   T023T_WGBEZ, --Material group desc
		   VBRP_MATNR, -- Material nr
		   VBRP_ARKTX, --Material text
		   VBRP_VRKME, -- Sale unit
		   A_T006A_VRKME.T006A_MSEHT ZF_VBRP_VRKME_DESC, -- Sale unit desc
		   VBRP_FKIMG, -- Acutal quantity
		   VBRP_FKLMG, -- Billing quantity
		   VBRP_NTGEW, -- Net weight
		   VBRP_BRGEW, -- Gross weight
		   VBRP_GEWEI, -- Weight unit
		   A_T006A_GEWEI.T006A_MSEHT ZF_VBRP_GEWEI_DESC, --Weight unit desc
		   VBRP_VOLUM, -- Volume
		   VBRP_VOLEH, -- Voume unit
		   A_T006A_VOLEH.T006A_MSEHT ZF_VBRP_VOLEH_DESC, --Volume unit desc
		   VBRP_WERKS, -- Plant
		   T001W_NAME1,-- Plant desc
		   T001_WAERS,
		   T001_BUTXT, -- Hanh Lam : Added from SAP USAGE
		   VBRP_SPART, -- Devision
		   TSPAT_VTEXT,-- Devision desc
		   VBRP_ALAND, -- Departure country
		   VBRP_KOSTL, -- Cost center
		   VBRP_PRCTR, -- Proffit center
		   VBRP_LGORT, --Storge location
		   (VBRP_NETWR)*ISNULL(B00_TCURX.TCURX_FACTOR,1) ZF_VBRP_NETWR_S, -- Item net value
		   (VBRP_NETWR)*ISNULL(B00_TCURX.TCURX_FACTOR,1)* VBRP_KURSK * COALESCE(TCURF_COC.TCURF_TFACT,1)/COALESCE(TCURF_COC.TCURF_FFACT,1) ZF_VBRP_NETWR_S_COC, -- Item net value
		   (VBRP_NETWR)*ISNULL(B00_TCURX.TCURX_FACTOR,1)* VBRP_KURSK * COALESCE(TCURF_COC.TCURF_TFACT,1)/COALESCE(TCURF_COC.TCURF_FFACT,1) * COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1) ZF_VBRP_NETWR_S_CUC, -- Item net value
		   VBRP_MWSBP, -- Tax amount in document currency
		   VBRP_AUBEL, -- Sale docuemnt 
		   VBRP_AUPOS, -- Sale document item
		   VBRP_AUTYP, -- Sale document type
		   B00_DD07T_AUTYP.DD07T_DDTEXT ZF_VBRP_AUTYP_DESC, -- Sale type desc
		   VBRP_VGBEL, -- Reference document
		   VBRP_VGPOS, -- Reference document item
		   VBRP_VGTYP, -- Reference document type
		   B00_D007T_VGTYP.DD07T_DDTEXT ZF_VBRP_VGTYP_DESC, --Reference document type desc
		   VBRP_PRSDT, -- Pricing date
		   VBRP_KURSK, -- Exhange rate
		   VBRP_SPARA, -- Sale order division
--		   VBRP_BZIRK_AUFT,-- Sale district
		   VBRP_VKGRP, -- Sale group
		   VBRP_VKBUR,-- Sale office
		   VBRK_RFBSK, -- Status for transfer to accounting
		   VBRP_VBELN,
		   VBRK_BUKRS,
		   CONCAT(VBRK_MANDT,'|',VBRK_VBELN,'|',CAST(VBRP_POSNR AS INT)) ZF_SALE_INVOICE_DOC_KEY,
		   CASE 
				WHEN B00_DD07T_FKTYP.DD07T_DDTEXT IS NOT NULL THEN B00_DD07T_FKTYP.DD07T_DDTEXT
				WHEN VBRK_FKTYP='A'  AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL THEN 'Order related billing document'
				WHEN VBRK_FKTYP='B' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL  THEN 'Order related billing document for rebate settlement'
				WHEN VBRK_FKTYP='C' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL  THEN 'Order related billing documnent for partial settlement'
				WHEN VBRK_FKTYP='D' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL   THEN 'Periodic billing document'
				WHEN VBRK_FKTYP='E' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL  THEN 'Periodic biling with active invoice accrual'
				WHEN VBRK_FKTYP='F' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL  THEN 'Accrual'
				WHEN VBRK_FKTYP='I' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL  THEN 'Delivery-related billing document for inter-company billing'
				WHEN VBRK_FKTYP='K' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL  THEN 'Order related billing document for rebate correction'
				WHEN VBRK_FKTYP='L' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL  THEN 'Delivery related billing document' 
				WHEN VBRK_FKTYP='P' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL THEN 'Down payment request'
				WHEN VBRK_FKTYP='P' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL THEN 'Down payment request'
				WHEN VBRK_FKTYP='P' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL THEN 'Down payment request'
				WHEN VBRK_FKTYP='R' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL THEN 'Invoice list' 
				WHEN VBRK_FKTYP='U' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL THEN 'Billing request'
				WHEN VBRK_FKTYP='W' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL THEN 'POS billing document'
				WHEN VBRK_FKTYP='X' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL THEN 'Billing using general interface'
				WHEN VBRK_FKTYP='S' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL THEN 'CRM biling document'
				WHEN VBRK_FKTYP='N' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL THEN 'Provisional or differential billing document'
				WHEN VBRK_FKTYP='O' AND B00_DD07T_FKTYP.DD07T_DDTEXT IS NULL THEN 'Final billing document' 
				ELSE 'Billing document' END AS ZF_DD07T_DDTEXT_FKTYP 
	INTO B30_01_IT_INVOICE_DOCS
	FROM A_VBRK
	INNER JOIN A_VBRP
	ON  VBRK_VBELN = VBRP_VBELN

	--Only keep all sale organization relate to company code in the BKPF/BSEG cube
	--Khoi update
	-- Change the sale organization to company code
	INNER JOIN B00_TVKO
	ON VBRK_VKORG = TVKO_VKORG
	INNER JOIN AM_COMPANY_CODE
	ON COMPANY_CODE=VBRK_BUKRS

	-- Get currency factor
	LEFT JOIN B00_TCURX
	ON B00_TCURX.TCURX_CURRKEY = VBRK_WAERK COLLATE SQL_Latin1_General_CP1_CS_AS

	-- Get billing type desc
	LEFT JOIN A_TVFKT
	ON  TVFKT_SPRAS IN ('E', 'EN')
	AND TVFKT_FKART = VBRK_FKART COLLATE SQL_Latin1_General_CP1_CS_AS

	-- Get billing category desc
	LEFT JOIN B00_DD07T_FKTYP
	ON B00_DD07T_FKTYP.DD07T_DOMVALUE_L = VBRK_FKTYP

	-- Get billing item category
	LEFT JOIN A_TVAPT
	ON  TVAPT_SPRAS IN ('E', 'EN')
	AND VBRP_PSTYV = TVAPT_PSTYV COLLATE SQL_Latin1_General_CP1_CS_AS

	-- Get sale organization desc
	LEFT JOIN A_TVKOT
	ON  TVKOT_SPRAS IN ('E', 'EN')
	AND TVKOT_VKORG = VBRK_VKORG

	--Get distribution channel
	LEFT JOIN A_TVTWT
	ON  TVTWT_SPRAS IN ('E', 'EN')
	AND VBRK_VTWEG = TVTWT_VTWEG

	-- Get price group desc
	LEFT JOIN A_T188T
	ON  T188T_SPRAS IN ('E', 'EN')
	AND T188T_KONDA = VBRK_KONDA COLLATE SQL_Latin1_General_CP1_CS_AS

	-- Get customer group
	LEFT JOIN A_T151T
	ON  T151T_SPRAS IN ('E', 'EN')
	AND T151T_KDGRP = VBRK_KDGRP COLLATE SQL_Latin1_General_CP1_CS_AS

	-- Get sale district desc
	LEFT JOIN A_T171T
	ON  T171T_SPRAS IN ('E', 'EN')
	AND T171T_BZIRK = VBRK_BZIRK COLLATE SQL_Latin1_General_CP1_CS_AS

	-- Get price list type desc
	LEFT JOIN A_T189T
	ON T189T_SPRAS IN ('E', 'EN')
	AND T189T_PLTYP = VBRK_PLTYP COLLATE SQL_Latin1_General_CP1_CS_AS

	-- Get payment term desc
	LEFT JOIN A_TVZBT
	ON  TVZBT_SPRAS IN ('E', 'EN')
	AND TVZBT_ZTERM = VBRK_ZTERM COLLATE SQL_Latin1_General_CP1_CS_AS

	-- Get payment medthod
	LEFT JOIN A_T042ZT
	ON  T042ZT_LAND1 = VBRK_LAND1
	AND T042ZT_SPRAS IN ('E', 'EN')
	AND VBRK_ZLSCH = T042ZT_ZLSCH COLLATE SQL_Latin1_General_CP1_CS_AS

	--Get sold-to-party info
	LEFT JOIN A_KNA1 A_KNA1_KUNAG
	ON  VBRK_KUNAG = A_KNA1_KUNAG.KNA1_KUNNR

	--Get country desc for sold-to-party
	LEFT JOIN A_T005T
	ON  T005T_SPRAS IN ('E', 'EN')
	AND A_KNA1_KUNAG.KNA1_LAND1 = T005T_LAND1

	--Get region desc for sold-to-party
	LEFT JOIN A_T005U
	ON  T005U_SPRAS IN ('E', 'EN')
	AND T005U_LAND1 = KNA1_LAND1
	AND T005U_BLAND = KNA1_REGIO

	--Get payer info
	LEFT JOIN A_KNA1 A_KNA1_KUNRG
	ON  A_KNA1_KUNRG.KNA1_KUNNR = VBRK_KUNRG

	--Get material group desc
	LEFT JOIN A_T023T
	ON  T023T_SPRAS IN ('E', 'EN')
	AND T023T_MATKL = VBRP_MATKL COLLATE SQL_Latin1_General_CP1_CS_AS
		--Get sale unit desc
	LEFT JOIN A_T006A A_T006A_VRKME
	ON  A_T006A_VRKME.T006A_SPRAS IN ('E', 'EN')
	AND A_T006A_VRKME.T006A_MSEHI = VBRP_VRKME COLLATE SQL_Latin1_General_CP1_CS_AS

	--Get sale unit desc
	LEFT JOIN A_T006A A_T006A_GEWEI
	ON  A_T006A_GEWEI.T006A_SPRAS IN ('E', 'EN')
	AND A_T006A_GEWEI.T006A_MSEHI = VBRP_GEWEI COLLATE SQL_Latin1_General_CP1_CS_AS

	--Get sale unit desc
	LEFT JOIN A_T006A A_T006A_VOLEH
	ON  A_T006A_VOLEH.T006A_SPRAS IN ('E', 'EN')
	AND A_T006A_VOLEH.T006A_MSEHI = VBRP_VOLEH COLLATE SQL_Latin1_General_CP1_CS_AS

	--Get plant description
	LEFT JOIN A_T001W
	ON  T001W_WERKS = VBRP_WERKS COLLATE SQL_Latin1_General_CP1_CS_AS
	
	--Get division desc
	LEFT JOIN A_TSPAT
	ON  TSPAT_SPRAS IN ('E', 'EN')
	AND VBRP_SPART = TSPAT_SPART COLLATE SQL_Latin1_General_CP1_CS_AS

	--Get sale document type desc
	LEFT JOIN B00_DD07T_VBTYP B00_DD07T_AUTYP
	ON B00_DD07T_AUTYP.DD07T_DOMVALUE_L = VBRP_AUTYP COLLATE SQL_Latin1_General_CP1_CS_AS

	--Get reference document type
	LEFT JOIN B00_DD07T_VBTYP B00_D007T_VGTYP
	ON VBRP_VGTYP = B00_D007T_VGTYP.DD07T_DOMVALUE_L COLLATE SQL_Latin1_General_CP1_CS_AS

	--Get Company currency

	LEFT JOIN B00_03_IT_T001_RMV_DUP
	ON TVKO_BUKRS_MAPPING = B00_03_IT_T001_RMV_DUP.BUKRS_MAPPING


-- Add currency factor from company currency to USD
	LEFT JOIN B00_IT_TCURF TCURF_CUC
	ON B00_03_IT_T001_RMV_DUP.T001_WAERS = TCURF_CUC.TCURF_FCURR
	AND TCURF_CUC.TCURF_TCURR  = @currency  
	AND TCURF_CUC.TCURF_GDATU = (
		SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
		FROM B00_IT_TCURF
		WHERE B00_03_IT_T001_RMV_DUP.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
				B00_IT_TCURF.TCURF_TCURR  = @currency  AND
				B00_IT_TCURF.TCURF_GDATU <= VBRK_ERDAT
		ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
		)

-- Add exchange rate from company currency to USD
	LEFT JOIN B00_IT_TCURR TCURR_CUC
		ON B00_03_IT_T001_RMV_DUP.T001_WAERS = TCURR_CUC.TCURR_FCURR
		AND TCURR_CUC.TCURR_TCURR  = @currency  
		AND TCURR_CUC.TCURR_GDATU = (
			SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
			FROM B00_IT_TCURR
			WHERE B00_03_IT_T001_RMV_DUP.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
					B00_IT_TCURR.TCURR_TCURR  = @currency  AND
					B00_IT_TCURR.TCURR_GDATU <= VBRK_ERDAT
			ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
			) 
-- Add currency factor from document currency to local currency

	LEFT JOIN B00_IT_TCURF TCURF_COC
	ON VBRK_WAERK = TCURF_COC.TCURF_FCURR
	AND TCURF_COC.TCURF_TCURR  = T001_WAERS  
	AND TCURF_COC.TCURF_GDATU = (
		SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
		FROM B00_IT_TCURF
		WHERE VBRK_WAERK = B00_IT_TCURF.TCURF_FCURR AND 
				B00_IT_TCURF.TCURF_TCURR  = T001_WAERS  AND
				B00_IT_TCURF.TCURF_GDATU <= VBRK_ERDAT
		ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
		)
	--Add name of the user 
			LEFT JOIN A_V_USERNAME HEADER_USR_INFO
		ON  HEADER_USR_INFO.V_USERNAME_BNAME = VBRK_ERNAM

		LEFT JOIN A_V_USERNAME ITEM_USR_INFO
		ON  ITEM_USR_INFO.V_USERNAME_BNAME = VBRP_ERNAM

	EXEC SP_RENAME_FIELD 'B30_',B30_01_IT_INVOICE_DOCS



GO
