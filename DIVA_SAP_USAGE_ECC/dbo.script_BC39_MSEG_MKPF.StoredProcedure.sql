USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[script_BC39_MSEG_MKPF]
WITH EXECUTE AS CALLER
AS

--DYNAMIC_SCRIPT_START

     DECLARE 	 
			 @currency nvarchar(max)			= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'currency')
			,@date1 nvarchar(max)				= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'date1')
			,@date2 nvarchar(max)				= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'date2')
			,@downloaddate nvarchar(max)		= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'downloaddate')
			,@exchangeratetype nvarchar(max)	= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'exchangeratetype')
			,@language1 nvarchar(max)			= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'language1')
			,@language2 nvarchar(max)			= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'language2')
			,@year nvarchar(max)				= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'year')
			,@id nvarchar(max)					= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'id')
			--,@ZV_LIMIT nvarchar(max)		    = (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'LIMIT_RECORDS')
			,@errormsg NVARCHAR(MAX)
			
DECLARE @dateformat varchar(3)
SET @dateformat   = (SELECT dbo.get_param('dateformat'))
SET DATEFORMAT @dateformat;


--Create the metarial movement cube
	EXEC SP_REMOVE_TABLES 'BC39_%'
EXEC SP_DROPTABLE BC39_01_IT_MSEG_MKPF
SELECT DISTINCT
	A_MSEG.*,A_MKPF.*,
	V_USERNAME_NAME_TEXT,--name of the user
	A_TSTCT.TSTCT_TTEXT ,-- description of the transaction code
	A_T003T.T003T_LTEXT ,-- definition of the document type
	A_T156T.T156T_BTEXT , -- description of movement types
	A_T001W.T001W_BWKEY , --Valuation Area
	A_T001W.T001W_NAME1  ,--Plant name
	A_T001L.T001L_LGOBE ,--Description of Storage Location
	A_LFA1.LFA1_NAME1 ,--Supplier name
	A_LFA1.LFA1_ERDAT ,--Supplier create date
	A_LFA1.LFA1_ERNAM ,--Supplier username
	A_MAKT.MAKT_MAKTX ,--Material Description
	A_MAKT.MAKT_MAKTG , --Material description in upper case for matchcodes	,
	A_MARA.MARA_MTART ,--Material type 
	T134T_MTBEZ ,--Material type description
		A_T156HT.T156HT_BTEXT,

		KNA1_KUNNR,
	KNA1_NAME1,
	KNA1_ERNAM,
	CSKT_LTEXT,
	CSKT_KTEXT,
	CEPCT_LTEXT,
	CEPCT_KTEXT,
	IIF(A_V_USERNAME.V_USERNAME_NAME_TEXT IS NULL, MKPF_USNAM, CONCAT(MKPF_USNAM, ' - ', A_V_USERNAME.V_USERNAME_NAME_TEXT)) AS MKPF_USNAM_AND_NAME_TEXT,

	CASE WHEN DBO.TRIM(MSEG_SOBKZ)='E' THEN 'Orders on hand        ' 
	WHEN DBO.TRIM(MSEG_SOBKZ)='K' THEN 'Consignment (vendor)  '
	WHEN DBO.TRIM(MSEG_SOBKZ)='M' THEN 'Ret trans pkg vendor  '
	WHEN DBO.TRIM(MSEG_SOBKZ)='O' THEN 'Parts prov vendor     '
	WHEN DBO.TRIM(MSEG_SOBKZ)='P' THEN 'Pipeline material     '
	WHEN DBO.TRIM(MSEG_SOBKZ)='Q' THEN 'Project stock         '
	WHEN DBO.TRIM(MSEG_SOBKZ)='V' THEN 'Ret pkg w customer    '
	WHEN DBO.TRIM(MSEG_SOBKZ)='W' THEN 'Consignment (customer)'
	WHEN DBO.TRIM(MSEG_SOBKZ)='Y' THEN 'Shipping unit (whse)  '
	ELSE '                      ' END AS ZF_MSEG_SOBKZ_DESC,--	Special Stock Indicator description
	CASE WHEN DBO.TRIM(MSEG_KZBEW)=''  THEN 'Goods movemnt w/o reference                              ' 
	WHEN DBO.TRIM(MSEG_KZBEW)='B' THEN 'Goods movement for purchase order                        '
	WHEN DBO.TRIM(MSEG_KZBEW)='F' THEN 'Goods movement for production order                      '
	WHEN DBO.TRIM(MSEG_KZBEW)='L' THEN 'Goods movement for deliver note                          '
	WHEN DBO.TRIM(MSEG_KZBEW)='K' THEN 'Goods movement for kaban requirement                     '
	WHEN DBO.TRIM(MSEG_KZBEW)='O' THEN 'Subsequent adjustment of material provided consumption   '
	WHEN DBO.TRIM(MSEG_KZBEW)='W' THEN 'Subsequent adjustment of proportion/product unit material'
	ELSE '                      ' END AS ZF_MSEG_KZBEW_DESC,--	Movement Indicator description
   CASE WHEN DBO.TRIM(MSEG_SHKZG)='S' THEN MSEG_DMBTR
	ELSE 0.0 END AS ZF_MSEG_DMBTR_DEBIT	,--debit amount caculation
   CASE WHEN DBO.TRIM(MSEG_SHKZG)='H' THEN MSEG_DMBTR
	ELSE 0.0 END AS  ZF_MSEG_DMBTR_CREDIT,--credit amount caculation
   CASE WHEN DBO.TRIM(MSEG_SHKZG)='S' THEN MSEG_DMBTR
	ELSE MSEG_DMBTR*-1 END AS ZF_MSEG_DMBTR_S,--signed amount caculation
   CASE WHEN DBO.TRIM(MSEG_SHKZG)='S' THEN MSEG_DMBTR*COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)*COALESCE(TCURX_FACTOR,1)
	ELSE MSEG_DMBTR*-1*COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)*COALESCE(TCURX_FACTOR,1) END AS ZF_MSEG_DMBTR_S_CUC,--signed amount caculation
    CASE WHEN DBO.TRIM(MSEG_SHKZG)='S' THEN MSEG_SALK3*COALESCE(TCURX_FACTOR,1)
	ELSE MSEG_SALK3*-1*COALESCE(TCURX_FACTOR,1) END AS ZF_MSEG_SALK3_S,
 CASE WHEN DBO.TRIM(MSEG_SHKZG)='S' THEN MSEG_SALK3*COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)*COALESCE(TCURX_FACTOR,1)
	ELSE MSEG_SALK3*-1*COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)*COALESCE(TCURX_FACTOR,1) END AS ZF_MSEG_SALK3_S_CUC,--signed amount caculation
  
  
  CASE WHEN DBO.TRIM(MSEG_SHKZG)='S' THEN MSEG_MENGE
	ELSE MSEG_MENGE*-1 END AS ZF_MSEG_MENGE_S --Quantity caculation
INTO BC39_01_IT_MSEG_MKPF
FROM
		 A_MSEG 
	JOIN A_MKPF 
	ON  MSEG_MJAHR= MKPF_MJAHR AND 
		MSEG_MBLNR=MKPF_MBLNR
-- Add T001_WAERS 

LEFT JOIN A_T001 
	ON MSEG_BUKRS=T001_BUKRS

--Add TCURX for T001_WAERS 

LEFT JOIN B00_TCURX 
	ON T001_WAERS=TCURX_CURRKEY
	
--Add the description of the transaction code

LEFT JOIN A_TSTCT 
	ON MKPF_TCODE2=TSTCT_TCODE 

-- Add the description of movement types

LEFT JOIN A_T156T
	ON MSEG_BWART=T156T_BWART AND 
		MSEG_SOBKZ=T156T_SOBKZ AND 
		MSEG_KZBEW=T156T_KZBEW AND
		MSEG_KZZUG=T156T_KZZUG AND
		MSEG_KZVBR=T156T_KZVBR

-- Add the definition of the document type

LEFT JOIN A_T003T 
	ON MKPF_BLART=T003T_BLART
	
--Add the plant codes

LEFT JOIN A_T001W 
	ON MSEG_WERKS=T001W_WERKS

--Add the storage locations

LEFT JOIN A_T001L 
	ON MSEG_WERKS=T001L_WERKS AND 
		MSEG_LGORT=T001L_LGORT

--Step 8/ Add the supplier name

LEFT JOIN A_LFA1 
	ON MSEG_LIFNR=LFA1_LIFNR
--Get customer name from KNA1 table
LEFT JOIN A_KNA1
ON A_KNA1.KNA1_KUNNR = A_MSEG.MSEG_KUNNR

-- Add currency factor from company currency to USD

LEFT JOIN B00_IT_TCURF TCURF_CUC
ON A_T001.T001_WAERS = TCURF_CUC.TCURF_FCURR
AND TCURF_CUC.TCURF_TCURR  = @currency  
AND TCURF_CUC.TCURF_GDATU = (
	SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
	FROM B00_IT_TCURF
	WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
			B00_IT_TCURF.TCURF_TCURR  = @currency  AND
			B00_IT_TCURF.TCURF_GDATU <= MKPF_BUDAT
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
				B00_IT_TCURR.TCURR_GDATU <= MKPF_BUDAT
		ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
		) 

 --Step 12/ Add the material description 
 LEFT JOIN A_MAKT 
	ON MSEG_MATNR=MAKT_MATNR

 --Step 14/Get names of user from A_USER_ADDR 
 LEFT JOIN A_V_USERNAME 
	ON MKPF_USNAM=V_USERNAME_BNAME

 --Step 16/ Add the material type and the material description
 LEFT JOIN A_MARA 
	ON MSEG_MATNR=MARA_MATNR
 LEFT JOIN A_T134T 
	ON MARA_MTART=T134T_MTART
--Get material group - desription
LEFT JOIN A_T023T
ON A_T023T.T023T_MATKL = A_MARA.MARA_MATKL
--Get cost center description
LEFT JOIN A_CSKT
ON A_CSKT.CSKT_KOSTL = A_MSEG.MSEG_KOSTL
AND A_CSKT.CSKT_KOKRS = A_MSEG.MSEG_KOKRS
--Get profit center description
LEFT JOIN A_CEPCT
ON	A_MSEG.MSEG_BUKRS = A_CEPCT.CEPCT_KOKRS AND
	A_MSEG.MSEG_KOKRS = A_CEPCT.CEPCT_KOKRS AND
	A_MSEG.MSEG_PRCTR = A_CEPCT.CEPCT_PRCTR 
--Get movement type - text
LEFT JOIN A_T156HT
	ON MSEG_BWART=A_T156HT.T156HT_BWART AND A_T156HT.T156HT_SPRAS='EN'

--Limit the company code
WHERE MSEG_BUKRS IN
(
	SELECT DISTINCT SCOPE_CMPNY_CODE FROM AM_SCOPE
)
GO
