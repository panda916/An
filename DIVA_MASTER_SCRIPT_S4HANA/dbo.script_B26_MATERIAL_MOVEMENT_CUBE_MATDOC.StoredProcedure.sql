USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[script_B26_MATERIAL_MOVEMENT_CUBE_MATDOC]
AS

--DYNAMIC_SCRIPT_START
/*  Change history comments
	Update history 
	-------------------------------------------------------
	Date            | Who   |  Description 
	24-03-2022	| Thuan	| Remove MANDT field in join
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
	B00_MATDOC.*,
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
	CASE WHEN DBO.TRIM(MATDOC_SOBKZ)='E' THEN 'Orders on hand        ' 
	WHEN DBO.TRIM(MATDOC_SOBKZ)='K' THEN 'Consignment (vendor)  '
	WHEN DBO.TRIM(MATDOC_SOBKZ)='M' THEN 'Ret trans pkg vendor  '
	WHEN DBO.TRIM(MATDOC_SOBKZ)='O' THEN 'Parts prov vendor     '
	WHEN DBO.TRIM(MATDOC_SOBKZ)='P' THEN 'Pipeline material     '
	WHEN DBO.TRIM(MATDOC_SOBKZ)='Q' THEN 'Project stock         '
	WHEN DBO.TRIM(MATDOC_SOBKZ)='V' THEN 'Ret pkg w customer    '
	WHEN DBO.TRIM(MATDOC_SOBKZ)='W' THEN 'Consignment (customer)'
	WHEN DBO.TRIM(MATDOC_SOBKZ)='Y' THEN 'Shipping unit (whse)  '
	ELSE '                      ' END AS ZF_SOBKZ_DESC,--	Special Stock Indicator description
	CASE WHEN DBO.TRIM(MATDOC_KZBEW)=''  THEN 'Goods movemnt w/o reference                              ' 
	WHEN DBO.TRIM(MATDOC_KZBEW)='B' THEN 'Goods movement for purchase order                        '
	WHEN DBO.TRIM(MATDOC_KZBEW)='F' THEN 'Goods movement for production order                      '
	WHEN DBO.TRIM(MATDOC_KZBEW)='L' THEN 'Goods movement for deliver note                          '
	WHEN DBO.TRIM(MATDOC_KZBEW)='K' THEN 'Goods movement for kaban requirement                     '
	WHEN DBO.TRIM(MATDOC_KZBEW)='O' THEN 'Subsequent adjustment of material provided consumption   '
	WHEN DBO.TRIM(MATDOC_KZBEW)='W' THEN 'Subsequent adjustment of proportion/product unit material'
	ELSE '                      ' END AS ZF_KZBEW_DESC,--	Movement Indicator description
   CASE WHEN DBO.TRIM(MATDOC_SHKZG)='S' THEN MATDOC_DMBTR
	ELSE 0.0 END AS ZF_MATDOC_DMBTR_DEBIT	,--debit amount caculation
   CASE WHEN DBO.TRIM(MATDOC_SHKZG)='H' THEN MATDOC_DMBTR
	ELSE 0.0 END AS  ZF_MATDOC_DMBTR_CREDIT,--credit amount caculation
   CASE WHEN DBO.TRIM(MATDOC_SHKZG)='S' THEN MATDOC_DMBTR
	ELSE MATDOC_DMBTR*-1 END AS ZF_MATDOC_DMBTR_SIGNED,--signed amount caculation
   CASE WHEN DBO.TRIM(MATDOC_SHKZG)='S' THEN MATDOC_DMBTR*COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)*COALESCE(TCURX_FACTOR,1)
	ELSE MATDOC_DMBTR*-1*COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1)*COALESCE(TCURX_FACTOR,1)*COALESCE(TCURX_FACTOR,1) END AS ZF_MATDOC_DMBTR_SIGNED_CUC,--signed amount caculation
   CASE WHEN DBO.TRIM(MATDOC_SHKZG)='S' THEN MATDOC_MENGE
	ELSE MATDOC_MENGE*-1 END AS ZF_MATDOC_MENGE_S ,--Quantity caculation
	AM_COMPANY_CODE.BUKRS_MAPPING AS MATDOC_BUKRS_MAPPING
INTO B26_01_IT_MATERIAL_MOVEMENT
FROM B00_MATDOC 
-- Add T001_WAERS 

LEFT JOIN B00_03_IT_T001_RMV_DUP
ON MATDOC_BUKRS = ZF_COMPANY_CODE


--Add TCURX for T001_WAERS 

LEFT JOIN B00_TCURX 
	ON T001_WAERS=TCURX_CURRKEY
	
--Add the description of the transaction code

LEFT JOIN A_TSTCT 
	ON MATDOC_TCODE2=TSTCT_TCODE 

-- Add the description of movement types

LEFT JOIN A_T156T
	ON MATDOC_BWART=T156T_BWART AND 
		MATDOC_SOBKZ=T156T_SOBKZ AND 
		MATDOC_KZBEW=T156T_KZBEW AND
		MATDOC_KZZUG=T156T_KZZUG AND
		MATDOC_KZVBR=T156T_KZVBR

-- Add the definition of the document type

LEFT JOIN A_T003T 
	ON MATDOC_BLART=T003T_BLART
	
--Add the plant codes

LEFT JOIN A_T001W 
	ON MATDOC_WERKS=T001W_WERKS

--Add the storage locations

LEFT JOIN A_T001L 
	ON MATDOC_WERKS=T001L_WERKS AND 
		MATDOC_LGORT=T001L_LGORT

--Step 8/ Add the supplier name

LEFT JOIN A_LFA1 
	ON MATDOC_LIFNR=LFA1_LIFNR

-- Step 9/ Add currency factor from company currency to USD
LEFT JOIN B00_IT_TCURF TCURF_CUC
ON B00_03_IT_T001_RMV_DUP.T001_WAERS = TCURF_CUC.TCURF_FCURR
AND TCURF_CUC.TCURF_TCURR  = @currency  
AND TCURF_CUC.TCURF_GDATU = (
	SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
	FROM B00_IT_TCURF
	WHERE B00_03_IT_T001_RMV_DUP.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
			B00_IT_TCURF.TCURF_TCURR  = @currency  AND
			B00_IT_TCURF.TCURF_GDATU <= MATDOC_BUDAT
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
				B00_IT_TCURR.TCURR_GDATU <= MATDOC_BUDAT
		ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
		) 

 --Step 11/ Add the material description 
 LEFT JOIN A_MAKT 
	ON MATDOC_MATNR=MAKT_MATNR

 --Step 12/Get names of user from A_USER_ADDR 
 LEFT JOIN A_V_USERNAME 
	ON MATDOC_USNAM=V_USERNAME_BNAME

 --Step 13/ Add the material type and the material description
 LEFT JOIN A_MARA 
	ON MATDOC_MATNR=MARA_MATNR
 LEFT JOIN A_T134T 
	ON MARA_MTART=T134T_MTART
--Limit the company code
INNER JOIN AM_COMPANY_CODE ON MATDOC_BUKRS=COMPANY_CODE
WHERE MATDOC_BUKRS IN
(	
	SELECT DISTINCT SCOPE_CMPNY_CODE FROM AM_SCOPE

)

--Step 2 Create Good receipt cubes from the MAterial movement cube
EXEC SP_DROPTABLE 'B26_02_IT_GR_CUBE'
SELECT * 
INTO B26_02_IT_GR_CUBE
FROM B26_01_IT_MATERIAL_MOVEMENT
WHERE MATDOC_BLART = 'WE' AND MATDOC_BWART = '101'  AND MATDOC_SHKZG = 'S'
  AND MATDOC_KZZUG<>'X'

--Step 3 Create Material movement 
EXEC SP_DROPTABLE 'B26_03_IT_MATERIAL_DOC'

SELECT *
INTO B26_03_IT_MATERIAL_DOC 
FROM 
B26_01_IT_MATERIAL_MOVEMENT 
WHERE MATDOC_BLART = 'WL'

--Step 3 Rename the fields of the tables
EXEC SP_RENAME_FIELD 'B26_03_','B26_03_IT_MATERIAL_DOC'
EXEC SP_RENAME_FIELD 'B26_02_','B26_02_IT_GR_CUBE'
EXEC SP_RENAME_FIELD 'B26_01_','B26_01_IT_MATERIAL_MOVEMENT'






GO
