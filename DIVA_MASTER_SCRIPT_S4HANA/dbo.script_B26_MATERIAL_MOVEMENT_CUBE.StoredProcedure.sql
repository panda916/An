USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_B26_MATERIAL_MOVEMENT_CUBE]
AS

--DYNAMIC_SCRIPT_START
/*  Change history comments
	Update history 
	-------------------------------------------------------
	Date            | Who   |  Description 
	24-03-2022	| Thuan	| Remove MANDT field in join
	13-09-2024	| HL	| Add fields for SAP USAGE
*/

/* Initiate the log */  
--Create database log table if it does not exist
IF OBJECT_ID('_DatabaseLogTable', 'U') IS NULL BEGIN CREATE TABLE [dbo].[_DatabaseLogTable] ([Database] nvarchar(max) NULL,[Object] nvarchar(max) NULL,[Object Type] nvarchar(max) NULL,[User] nvarchar(max) NULL,[Date] date NULL,[Time] time NULL,[Description] nvarchar(max) NULL,[Table] nvarchar(max),[Rows] int) END

--Log start of procedure
INSERT INTO [dbo].[_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure started',NULL,NULL

/* Initialize parameters from globals table */

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
			,@ZV_LIMIT nvarchar(max)		    = (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'ZV_LIMIT')
			,@errormsg NVARCHAR(MAX)
			
DECLARE @dateformat varchar(3)
SET @dateformat   = (SELECT dbo.get_param('dateformat'))
SET DATEFORMAT @dateformat;

--Create the metarial movement cube
	EXEC SP_REMOVE_TABLES 'B26_%'

EXEC SP_DROPTABLE B26_01_IT_MATERIAL_MOVEMENT
SELECT DISTINCT
	A_MSEG.*,A_MKPF.*,
	V_USERNAME_NAME_TEXT,--name of the user
	A_TSTCT.TSTCT_TTEXT ,-- description of the transaction code
	A_T003T.T003T_LTEXT ,-- definition of the document type
	A_T156T.T156T_BTEXT , -- description of movement types
	B00_03_IT_T001_RMV_DUP.T001_BUTXT, -- Company code
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
	CASE WHEN DBO.TRIM(MSEG_SOBKZ)='E' THEN 'Orders on hand        ' 
	WHEN DBO.TRIM(MSEG_SOBKZ)='K' THEN 'Consignment (vendor)  '
	WHEN DBO.TRIM(MSEG_SOBKZ)='M' THEN 'Ret trans pkg vendor  '
	WHEN DBO.TRIM(MSEG_SOBKZ)='O' THEN 'Parts prov vendor     '
	WHEN DBO.TRIM(MSEG_SOBKZ)='P' THEN 'Pipeline material     '
	WHEN DBO.TRIM(MSEG_SOBKZ)='Q' THEN 'Project stock         '
	WHEN DBO.TRIM(MSEG_SOBKZ)='V' THEN 'Ret pkg w customer    '
	WHEN DBO.TRIM(MSEG_SOBKZ)='W' THEN 'Consignment (customer)'
	WHEN DBO.TRIM(MSEG_SOBKZ)='Y' THEN 'Shipping unit (whse)  '
	ELSE '                      ' END AS ZF_SOBKZ_DESC,--	Special Stock Indicator description
	CASE WHEN DBO.TRIM(MSEG_KZBEW)=''  THEN 'Goods movemnt w/o reference                              ' 
	WHEN DBO.TRIM(MSEG_KZBEW)='B' THEN 'Goods movement for purchase order                        '
	WHEN DBO.TRIM(MSEG_KZBEW)='F' THEN 'Goods movement for production order                      '
	WHEN DBO.TRIM(MSEG_KZBEW)='L' THEN 'Goods movement for deliver note                          '
	WHEN DBO.TRIM(MSEG_KZBEW)='K' THEN 'Goods movement for kaban requirement                     '
	WHEN DBO.TRIM(MSEG_KZBEW)='O' THEN 'Subsequent adjustment of material provided consumption   '
	WHEN DBO.TRIM(MSEG_KZBEW)='W' THEN 'Subsequent adjustment of proportion/product unit material'
	ELSE '                      ' END AS ZF_KZBEW_DESC,--	Movement Indicator description
   CASE WHEN DBO.TRIM(MSEG_SHKZG)='S' THEN MSEG_DMBTR
	ELSE 0.0 END AS ZF_MSEG_DMBTR_DEBIT	,--debit amount caculation
   CASE WHEN DBO.TRIM(MSEG_SHKZG)='H' THEN MSEG_DMBTR
	ELSE 0.0 END AS  ZF_MSEG_DMBTR_CREDIT,--credit amount caculation
   CASE WHEN DBO.TRIM(MSEG_SHKZG)='S' THEN MSEG_DMBTR *COALESCE(TCURX_FACTOR,1)
	ELSE MSEG_DMBTR*-1  *COALESCE(TCURX_FACTOR,1) END AS ZF_MSEG_DMBTR_SIGNED,--signed amount caculation
   CASE WHEN DBO.TRIM(MSEG_SHKZG)='S' THEN MSEG_DMBTR*COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)*COALESCE(TCURX_FACTOR,1)
	ELSE MSEG_DMBTR*-1*COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)*COALESCE(TCURX_FACTOR,1)*COALESCE(TCURX_FACTOR,1) END AS ZF_MSEG_DMBTR_SIGNED_CUC,--signed amount caculation
   CASE WHEN DBO.TRIM(MSEG_SHKZG)='S' THEN MSEG_MENGE
	ELSE MSEG_MENGE*-1 END AS ZF_MSEG_MENGE_S ,--Quantity caculation
	-- Hanh Lam: Added ZF_MSEG_SALK3_S, ZF_MSEG_SALK3_S_CUC from SAP USAGE
   CASE WHEN DBO.TRIM(MSEG_SHKZG)='S' THEN MSEG_SALK3*COALESCE(TCURX_FACTOR,1)
	ELSE MSEG_SALK3*-1*COALESCE(TCURX_FACTOR,1) END AS ZF_MSEG_SALK3_S,
   CASE WHEN DBO.TRIM(MSEG_SHKZG)='S' THEN MSEG_SALK3*COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)*COALESCE(TCURX_FACTOR,1)
	ELSE MSEG_SALK3*-1*COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)*COALESCE(TCURX_FACTOR,1) END AS ZF_MSEG_SALK3_S_CUC,--signed amount caculation
	AM_COMPANY_CODE.BUKRS_MAPPING AS MSEG_BUKRS_MAPPING
INTO B26_01_IT_MATERIAL_MOVEMENT
FROM
	(
			SELECT * FROM A_MSEG 
			WHERE MSEG_BUKRS 
			IN
			(
				SELECT DISTINCT B09_EKPO_BUKRS FROM B09_13_IT_PTP_POS
			)
		)  AS A_MSEG 
	JOIN A_MKPF 
	ON  MSEG_MJAHR= MKPF_MJAHR AND 
		MSEG_MBLNR=MKPF_MBLNR

--Limit the company code
INNER JOIN AM_COMPANY_CODE ON MSEG_BUKRS=COMPANY_CODE


-- Thuan updated : 20240201 Remove link AM_COMPANY_CODE from MSEG.

LEFT JOIN B00_03_IT_T001_RMV_DUP
ON MSEG_BUKRS = ZF_COMPANY_CODE

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

-- Step 9/ Add currency factor from company currency to USD
LEFT JOIN B00_IT_TCURF TCURF_CUC
ON B00_03_IT_T001_RMV_DUP.T001_WAERS = TCURF_CUC.TCURF_FCURR
AND TCURF_CUC.TCURF_TCURR  = @currency  
AND TCURF_CUC.TCURF_GDATU = (
	SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
	FROM B00_IT_TCURF
	WHERE B00_03_IT_T001_RMV_DUP.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
			B00_IT_TCURF.TCURF_TCURR  = @currency  AND
			B00_IT_TCURF.TCURF_GDATU <= MKPF_BUDAT
	ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
	)
-- Step 10/ Add exchange rate from company currency to USD
LEFT JOIN B00_IT_TCURR TCURR_CUC
	ON B00_03_IT_T001_RMV_DUP.T001_WAERS = TCURR_CUC.TCURR_FCURR
	AND TCURR_CUC.TCURR_TCURR  = @currency  
	AND TCURR_CUC.TCURR_GDATU = (
		SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
		FROM B00_IT_TCURR
		WHERE B00_03_IT_T001_RMV_DUP.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
				B00_IT_TCURR.TCURR_TCURR  = @currency  AND
				B00_IT_TCURR.TCURR_GDATU <= MKPF_BUDAT
		ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
		) 

 --Step 11/ Add the material description 
 LEFT JOIN A_MAKT 
	ON MSEG_MATNR=MAKT_MATNR

 --Step 12/Get names of user from A_USER_ADDR 
 LEFT JOIN A_V_USERNAME 
	ON MKPF_USNAM=V_USERNAME_BNAME

 --Step 13/ Add the material type and the material description
 LEFT JOIN A_MARA 
	ON MSEG_MATNR=MARA_MATNR
 LEFT JOIN A_T134T 
	ON MARA_MTART=T134T_MTART



--Step 2 Create Good receipt cubes from the MAterial movement cube
EXEC SP_DROPTABLE 'B26_02_IT_GR_CUBE'
SELECT * 
INTO B26_02_IT_GR_CUBE
FROM B26_01_IT_MATERIAL_MOVEMENT
WHERE MKPF_BLART = 'WE' AND MSEG_BWART = '101'  AND MSEG_SHKZG = 'S'
  AND MSEG_KZZUG<>'X'

--Step 3 Create Material movement 
EXEC SP_DROPTABLE 'B26_03_IT_MATERIAL_DOC'

SELECT *
INTO B26_03_IT_MATERIAL_DOC 
FROM 
B26_01_IT_MATERIAL_MOVEMENT 
WHERE MKPF_BLART = 'WL'

--Step 3 Rename the fields of the tables
EXEC SP_RENAME_FIELD 'B26_03_','B26_03_IT_MATERIAL_DOC'
EXEC SP_RENAME_FIELD 'B26_02_','B26_02_IT_GR_CUBE'
EXEC SP_RENAME_FIELD 'B26_01_','B26_01_IT_MATERIAL_MOVEMENT'
GO
