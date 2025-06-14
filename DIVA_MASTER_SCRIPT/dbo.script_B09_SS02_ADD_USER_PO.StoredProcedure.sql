USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--/****** Object:  StoredProcedure [dbo].[script_B09_SS02_ADD_USER_PO]    Script Date: 7/28/2023 12:51:45 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
-- =============================================
-- Author:		Khoi
-- Create date: <Create Date,,>
-- Description:	Create a sub script to add neccesary field for cube B09_13_IT_PTP_POS
-- 22-03-2022	   Thuan	Remove MANDT field in join
-- =============================================
CREATE     PROCEDURE [dbo].[script_B09_SS02_ADD_USER_PO]
AS

--DYNAMIC_SCRIPT_START
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
			--,@ZV_LIMIT nvarchar(max)		    = (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'LIMIT_RECORDS')
			,@errormsg NVARCHAR(MAX)
			
DECLARE @dateformat varchar(3)
SET @dateformat   = (SELECT dbo.get_param('dateformat'))
SET DATEFORMAT @dateformat;

--Step1 Add username,name of the user who create the supplier of the PO
--Add supplier create date,
EXEC SP_DROPTABLE B09_SS02_01_IT_PTP_POS

SELECT DISTINCT
	B09_EKKO_MANDT AS EKKO_MANDT,
	B09_EKPO_BUKRS AS EKPO_BUKRS,
	B09_SCOPE_BUSINESS_DMN_L1 AS SCOPE_BUSINESS_DMN_L1,
	B09_SCOPE_BUSINESS_DMN_L2 AS SCOPE_BUSINESS_DMN_L2,
	--B09_FSMC_ID AS FSMC_ID,
	--B09_FSMC_NAME AS FSMC_NAME,
	--B09_FSMC_CNTRY_CODE AS FSMC_CNTRY_CODE,
	--B09_FSMC_REGION AS FSMC_REGION,
	--B09_FSMC_CONTROLLING_AREA AS FSMC_CONTROLLING_AREA,
	--B09_FSMC_COMPANY_CODE AS FSMC_COMPANY_CODE,
	B09_T001_BUTXT AS T001_BUTXT,
	B09_EKKO_BSTYP AS EKKO_BSTYP,
	B09_ZF_EKKO_BSTYP_DESC AS ZF_EKKO_BSTYP_DESC,
	B09_EKKO_BSART AS EKKO_BSART,
	B09_EKKO_EBELN AS EKKO_EBELN,
	B09_EKPO_EBELP AS EKPO_EBELP,
	B09_EKPO_TXZ01 AS EKPO_TXZ01,
	B09_ZF_EKKO_AEDAT_YEAR AS ZF_EKKO_AEDAT_YEAR,
	B09_ZF_EKKO_AEDAT_FY AS ZF_EKKO_AEDAT_FY,
	B09_ZF_EKKO_AEDAT_YEAR_MONTH AS ZF_EKKO_AEDAT_YEAR_MONTH,
	B09_LFA1_KTOKK AS LFA1_KTOKK,
	B09_T077Y_TXT30 AS T077Y_TXT30,
	B09_EKKO_LIFNR AS EKKO_LIFNR,
	B09_LFA1_NAME1 AS LFA1_NAME1,
	B09_LFA1_LAND1 AS LFA1_LAND1,
	B09_COUNTRY_MAPPING_DESC AS COUNTRY_MAPPING_DESC,
	B09_EKPO_WERKS AS EKPO_WERKS,
	B09_T001W_NAME1 AS T001W_NAME1,
	B09_EKKO_EKORG AS EKKO_EKORG,
	B09_T024E_EKOTX AS T024E_EKOTX,
	B09_EKKO_RESWK AS EKKO_RESWK,
	B09_EKKO_EKGRP AS EKKO_EKGRP,
	B09_T024_EKNAM AS T024_EKNAM,
	B09_EKKO_BEDAT AS EKKO_BEDAT,
	B09_EKKO_AEDAT AS EKKO_AEDAT,
	B09_EKPO_EBELN AS EKPO_EBELN,
	B09_EKPO_MENGE AS EKPO_MENGE,
	B09_ZF_EKKO_AEDAT_Posting_DT AS ZF_EKKO_AEDAT_Posting_DT,
	B09_ZF_EKKO_AEDAT_CY_MONTH AS ZF_EKKO_AEDAT_CY_MONTH,
	B09_ZF_EKKO_AEDAT_FQ AS ZF_EKKO_AEDAT_FQ,
	B09_ZF_EKKO_AEDAT_FY_FQ AS ZF_EKKO_AEDAT_FY_FQ,
	B09_ZF_EKKO_AEDAT_FY_PER AS ZF_EKKO_AEDAT_FY_PER,
	B09_EKKO_ERNAM AS EKKO_ERNAM,
	B09_ZF_V_USERNAME_NAME_TEXT AS ZF_V_USERNAME_NAME_TEXT,
	B09_ZF_USR02_USTYP_DESC AS ZF_USR02_USTYP_DESC,
	B09_USR02_USTYP AS USR02_USTYP,
	B09_ZF_EKBE_ERNAM_1ST_GR_USER AS ZF_EKBE_ERNAM_1ST_GR_USER,
	B09_ZF_V_USERNAME_NAME_TEXT_1ST_GR AS ZF_V_USERNAME_NAME_TEXT_1ST_GR,
	B09_ZF_USR02_USTYP_1ST_GR AS ZF_USR02_USTYP_1ST_GR,
	B09_ZF_USR02_USTYP_DESC_GR AS ZF_USR02_USTYP_DESC_GR,
	B09_ZF_EKBE_ERNAM_1ST_INV_USER AS ZF_EKBE_ERNAM_1ST_INV_USER,
	B09_ZF_V_USERNAME_NAME_TEXT_1ST_INV AS ZF_V_USERNAME_NAME_TEXT_1ST_INV,
	B09_ZF_USR02_USTYP_1ST_INV AS ZF_USR02_USTYP_1ST_INV,
	B09_ZF_USR02_USTYP_DESC_INV AS ZF_USR02_USTYP_DESC_INV,
	B09_EKPO_MATNR AS EKPO_MATNR,
	B09_MAKT_MAKTX AS MAKT_MAKTX,
	B09_MARA_MTART AS MARA_MTART,
	B09_T134T_MTBEZ AS T134T_MTBEZ,
	B09_EKPO_MATKL AS EKPO_MATKL,
	B09_T023T_WGBEZ AS T023T_WGBEZ,
	B09_MARA_SPART AS MARA_SPART,
	B09_ZF_SPEND_TYPE AS ZF_SPEND_TYPE,
	B09_ZF_PO_CATEGORY AS ZF_PO_CATEGORY,
	B09_ZF_EKPO_MATNR_SPEND_CATEGORY AS ZF_EKPO_MATNR_SPEND_CATEGORY,
	B09_ZF_EKPO_MATNR_SPEND_CATEGORY_LEVEL1 AS ZF_EKPO_MATNR_SPEND_CATEGORY_LEVEL1,
	B09_ZF_EKPO_MATNR_SPEND_CATEGORY_LEVEL2 AS ZF_EKPO_MATNR_SPEND_CATEGORY_LEVEL2,
	B09_ZF_EKPO_MATNR_SPEND_CATEGORY_LEVEL3 AS ZF_EKPO_MATNR_SPEND_CATEGORY_LEVEL3,
	B09_EKKO_WAERS AS EKKO_WAERS,
	B09_EKPO_NETWR AS EKPO_NETWR,
	B09_EKPO_BRTWR AS EKPO_BRTWR,
	B09_ZF_EKPO_NETWR_TCURFA AS ZF_EKPO_NETWR_TCURFA,
	B09_T001_WAERS AS T001_WAERS,
	B09_ZF_EKPO_NETWR_COC AS ZF_EKPO_NETWR_COC,
	B09_AM_GLOBALS_CURRENCY AS AM_GLOBALS_CURRENCY,
	B09_ZF_EKPO_NETWR_CUC AS ZF_EKPO_NETWR_CUC,
	B09_EKPO_PSTYP AS EKPO_PSTYP,
	B09_EKPO_RETPO AS EKPO_RETPO,
	B09_EKPO_KNTTP AS EKPO_KNTTP,
	B09_T163I_KNTTX AS T163I_KNTTX,
	B09_ZF_EKKN_AUFNR_1ST_ASSET_ORDER AS ZF_EKKN_AUFNR_1ST_ASSET_ORDER,
	B09_ZF_EKKN_KOKRS_1ST_CONTR_AREA AS ZF_EKKN_KOKRS_1ST_CONTR_AREA,
	B09_ZF_EKKN_KOKRS_1ST_COST_CENT AS ZF_EKKN_KOKRS_1ST_COST_CENT,
	B09_ZF_CSKT_LTEXT_1ST_COST_CENT_DESC AS ZF_CSKT_LTEXT_1ST_COST_CENT_DESC,
	B09_ZF_EKKN_PRCTR_1ST_PROF_CENT AS ZF_EKKN_PRCTR_1ST_PROF_CENT,
	B09_ZF_CEPCT_MCTXT_1ST_PROF_CENTER_DESC AS ZF_CEPCT_MCTXT_1ST_PROF_CENTER_DESC,
	B09_ZF_EKKN_SAKTO_1ST_GL_ACC_NUM AS ZF_EKKN_SAKTO_1ST_GL_ACC_NUM,
	B09_SKAT_TXT50 AS SKAT_TXT50,
	B09_ZF_EKBE_BLDAT_1ST_INV_DATE AS ZF_EKBE_BLDAT_1ST_INV_DATE,
	B09_ZF_EKKO_AEDAT_MINUS_1ST_INV_DATE AS ZF_EKKO_AEDAT_MINUS_1ST_INV_DATE,
	B09_ZF_EKKO_AEDAT_PRIOR_1ST_INV_DATE AS ZF_EKKO_AEDAT_PRIOR_1ST_INV_DATE,
	B09_ZF_EKBE_CPUDT_1ST_GR_DATE AS ZF_EKBE_CPUDT_1ST_GR_DATE,
	B09_ZF_EKKO_AEDAT_MINUS_1ST_GR_DATE AS ZF_EKKO_AEDAT_MINUS_1ST_GR_DATE,
	B09_ZF_EKKO_AEDAT_PRIOR_1ST_GR_DATE AS ZF_EKKO_AEDAT_PRIOR_1ST_GR_DATE,
	B09_EKPO_WEPOS AS EKPO_WEPOS,
	B09_ZF_EKBE_VGABE_IS_A_GR AS ZF_EKBE_VGABE_IS_A_GR,
	B09_ZF_EKBE_DMBTR_IMM_GR_S_CUC AS ZF_EKBE_DMBTR_IMM_GR_S_CUC,
	B09_ZF_EKBE_DMBTR_IMM_GR_S AS ZF_EKBE_DMBTR_IMM_GR_S,
	B09_ZF_EKBE_WRBTR_IMM_GR_S_CUC AS ZF_EKBE_WRBTR_IMM_GR_S_CUC,
	B09_ZF_EKBE_WRBTR_IMM_GR_S AS ZF_EKBE_WRBTR_IMM_GR_S,
	B09_ZF_EKBE_MENGE_IMM_GR_S AS ZF_EKBE_MENGE_IMM_GR_S,
	B09_ZF_NUM_IMM_GRS AS ZF_NUM_IMM_GRS,
	B09_ZF_NUM_POS_WITH_IMM_GRS AS ZF_NUM_POS_WITH_IMM_GRS,
	B09_EKPO_REPOS AS EKPO_REPOS,
	B09_ZF_EKBE_DMBTR_IMM_INV_S AS ZF_EKBE_DMBTR_IMM_INV_S,
	B09_ZF_EKBE_DMBTR_IMM_INV_S_CUC AS ZF_EKBE_DMBTR_IMM_INV_S_CUC,
	B09_ZF_EKBE_WRBTR_IMM_INV_S AS ZF_EKBE_WRBTR_IMM_INV_S,
	B09_ZF_EKBE_WRBTR_IMM_INV_S_CUC AS ZF_EKBE_WRBTR_IMM_INV_S_CUC,
	B09_ZF_EKBE_MENGE_IMM_INV_S AS ZF_EKBE_MENGE_IMM_INV_S,
	B09_ZF_NUM_IMM_INVS AS ZF_NUM_IMM_INVS,
	B09_ZF_NUM_POS_WITH_IMM_INVS AS ZF_NUM_POS_WITH_IMM_INVS,
	B09_ZF_EKPO_LOEKZ_DEL AS ZF_EKPO_LOEKZ_DEL,
	B09_ZF_EKPO_KDAT_CONT_INVALID AS ZF_EKPO_KDAT_CONT_INVALID,
	B09_ZF_EKKO_BSTYP_LOEKZ_DESC AS ZF_EKKO_BSTYP_LOEKZ_DESC,
	B09_INTERCO_TXT AS INTERCO_TXT,
	B09_ZF_EKKO_AEDAT_CREATED_IN_PER AS ZF_EKKO_AEDAT_CREATED_IN_PER,
	B09_ZF_EKKO_BEDAT_DOC_DATE_IN_PER AS ZF_EKKO_BEDAT_DOC_DATE_IN_PER,
	B09_ZF_EKKO_EKBE_PO_WITH_GR_INV AS ZF_EKKO_EKBE_PO_WITH_GR_INV,
	B09_ZF_EKPO_NETWR_EQ_IMM_GR_VAL AS ZF_EKPO_NETWR_EQ_IMM_GR_VAL,
	B09_ZF_EKBE_WRBTR_UNDER_OVER_INV AS ZF_EKBE_WRBTR_UNDER_OVER_INV,
	B09_T163Y_PTEXT AS T163Y_PTEXT,
	B09_T161T_BATXT AS T161T_BATXT,
	B09_ZF_EKKN_AUFNR_1ST_ASSET_ORDER_DESC AS ZF_EKKN_AUFNR_1ST_ASSET_ORDER_DESC,
	B09_ZF_V_USERNAME_NAME_DESC AS ZF_V_USERNAME_NAME_DESC,
	B09_ZF_MAP_PO_GR_INV AS ZF_MAP_PO_GR_INV,
	COALESCE (B08_06_IT_PTP_SMD.B08_LFA1_ERNAM,'')	AS LFA1_ERNAM, --User who create the supplier,
	COALESCE (B08_06_IT_PTP_SMD.B08_LFA1_ERDAT,'')	AS LFA1_ERDAT, --Supplier create date,
	V_USERNAME_NAME_TEXT AS V_USERNAME_NAME_TEXT_LFA1 ,--Supplier user name,
	CONCAT(B09_EKKO_EBELN,'-',B09_EKPO_EBELP) AS 'ZF_DOCUMENT_NUMBER'
	INTO B09_SS02_01_IT_PTP_POS
FROM B09_13_IT_PTP_POS
LEFT JOIN 	B08_06_IT_PTP_SMD
		ON  B09_EKKO_LIFNR = B08_06_IT_PTP_SMD.B08_LFB1_LIFNR 
		AND B09_EKPO_BUKRS = B08_06_IT_PTP_SMD.B08_LFB1_BUKRS
LEFT JOIN A_V_USERNAME
		ON B08_LFA1_ERNAM=V_USERNAME_BNAME 
WHERE B09_EKPO_BUKRS IN
(
	SELECT * FROM AM_COMPANY_CODE
) AND
--	B09_ZF_EKKO_BEDAT_DOC_DATE_IN_PER = 'X'
--          AND 	B09_ZF_EKPO_LOEKZ_DEL='' AND
          		B09_EKKO_BSTYP	= 'F' 
          AND		B09_EKPO_RETPO <> 'X'
          AND		B09_EKPO_PSTYP <> '7'
--Step 2 Rename the fields
EXEC SP_RENAME_FIELD 'B09_SS02_', B09_SS02_01_IT_PTP_POS
GO
