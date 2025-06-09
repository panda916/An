USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_SU24_Identify sales document item categories that don't control items, quantities, pricing or billing]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START

-- Script objective: Identify sales document item categories that don't cnotrol items, quantities, pricing or billing

-- Step 1: select data from BO09_01_IT_SALE_DOCUMENT_ITEM_CATEGORY (sale document item category cube)
-- and add some flag to check description or setting of sale document item category

EXEC SP_REMOVE_TABLES 'SU24_%'

EXEC SP_REMOVE_TABLES 'SU24_01_XT_TVAP_SALE_DOC_ITEM_CATEGORIES_SETTING'

		SELECT DISTINCT 
		TVAP_PSTYV,
		TVAPT_VTEXT,
		TVAP_PRSFD,
		TVAP_FEHGR,
		TVAP_FKREL,
		ZF_TVAP_PRSFD_DESCRIPTION,
		ZF_TVAP_FKREL_DESCRIPTION,
		TVUVT_BEZEI,
		-- Add flag to show sale document category have description or not
		(
			CASE
				WHEN LEN(TVAPT_VTEXT) > 0 THEN 'Yes'
				ELSE 'No'
			END
		) AS ZF_TVAPT_VTEXT_EQ_BLANK_FLAG,
		-- Add flag to show sale document category have category description but don't have setting Relevant for Billing, Carry out pricing and Incompleteness procedure for sales document 
		(
			CASE
				WHEN  LEN(TVAP_PRSFD) >0 AND LEN(TVAP_FEHGR+TVAP_FKREL) = 0  THEN 'Yes'
				ELSE 'No'
			END
		) AS ZF_TVAP_PRFSD_FEHGR_FKREL_BLG_CONT
		INTO SU24_01_XT_TVAP_SALE_DOC_ITEM_CATEGORIES_SETTING
		FROM BO09_01_IT_TVAP_SALE_DOCUMENT_ITEM_CATEGORY

--Phase 2 Get the Sale order and Invoice cube, 
--VBRP_NETWR/VBRP_FKIMG to VBAP_NETWR/VBAP_ZMENG

-- Step 2: Create cube for sales order. 
--Get only the cases have invoices

EXEC SP_REMOVE_TABLES 'SU24_02_TT_VBAP_SALE_ORDER'
		SELECT *
		INTO SU24_02_TT_VBAP_SALE_ORDER
		FROM B28_01_IT_SALE_DOCUMENTS
		WHERE B28_VBAK_VBELN+B28_VBAP_POSNR IN
		(
			SELECT DISTINCT B30_VBRP_AUBEL+B30_VBRP_AUPOS FROM B30_01_IT_INVOICE_DOCS
		)
-- Step 2: Create SD invoices cube
--Get only the cases relate to sale orders
EXEC SP_REMOVE_TABLES 'SU24_03_TT_SD_INV'
		SELECT DISTINCT B30_01_IT_INVOICE_DOCS.*,
			V_USERNAME_NAME_TEXT,
			(
				CASE B30_VBRK_FKTYP			
					WHEN 'A' THEN 'Order-related billing document'	
					WHEN 'B' THEN 'Order-related billing document for rebate settlement'	
					WHEN 'C' THEN 'Order-related billing document for partial rebate settlement'	
					WHEN 'D' THEN 'Periodic billing document'	
					WHEN 'E' THEN 'Periodic billing with active invoice accrual'	
					WHEN 'F' THEN 'Accrual'	
					WHEN 'I' THEN 'Delivery-related billing document for inter-company billing'	
					WHEN 'K' THEN 'Order-related billing document for rebate correction'	
					WHEN 'L' THEN 'Delivery-related billing document'	
					WHEN 'P' THEN 'Down payment request'	
					WHEN 'R' THEN 'Invoice list'	
					WHEN 'U' THEN 'Billing request'	
					WHEN 'W' THEN 'POS billing document'	
					WHEN 'X' THEN 'Billing using general interface'	
					WHEN 'S' THEN 'CRM Billing Document'	
					WHEN 'N' THEN 'Provisional or Differential Billing Document'	
					WHEN 'O' THEN 'Final Billing Document'	
				END
			) AS ZF_VBRK_FKTYP_DESCRIPTION
		INTO SU24_03_TT_SD_INV
		FROM B30_01_IT_INVOICE_DOCS
		-- Get Person who Created the Object name
		LEFT JOIN A_V_USERNAME
		ON B30_VBRK_ERNAM = V_USERNAME_BNAME
		-- get VBAP_ZMENG and ZF_VBAP_NETWR_S from SU24_02 to compare with NETWR and FKIMG in SU24_03 to add flag 'ZF_NETWR_FKIMG_ZMENG_SAME'
		WHERE B30_VBRP_AUBEL+B30_VBRP_AUPOS IN 
		(
			SELECT DISTINCT B28_VBAK_VBELN+B28_VBAP_POSNR FROM B28_01_IT_SALE_DOCUMENTS
		)

--Step 3 To compare between Target quantity in sales units and the actual delivery unit,
--Net value of the order item 	 and Net value of the billing item
-- In billing cube,sum total NETWR,FKIMG group by VBRP_AUBEL,VBRP_AUBEL
--Then link back to sale document to do compare  

--Step 3.1 Summarize VBRK-VBRP base on VBRP_AUBEL,VBRP_AUPOS
EXEC SP_DROPTABLE 'SU24_04_TT_VBRK_VBRP_GROUP_BY_AUBEL_AUPOS'

SELECT B30_VBRP_AUPOS,B30_VBRP_AUBEL,
		SUM (B30_ZF_VBRP_NETWR_S_CUC) AS ZF_ZF_VBRP_NETWR_S_CUC_SUM,
		SUM (B30_VBRP_FKIMG) AS ZF_VBRP_FKIMG_SUM
INTO SU24_04_TT_VBRK_VBRP_GROUP_BY_AUBEL_AUPOS
FROM SU24_03_TT_SD_INV
GROUP BY B30_VBRP_AUBEL,B30_VBRP_AUPOS

--Step 3.2 Link to sale document to do compare

EXEC SP_DROPTABLE 'SU24_05_TT_VBRK_VBRP_COMPARE_VBAP_VBAK'

SELECT  B30_VBRP_AUPOS,
		B30_VBRP_AUBEL,
		ZF_ZF_VBRP_NETWR_S_CUC_SUM,
		ZF_VBRP_FKIMG_SUM,
		B28_VBAP_POSNR,
		B28_VBAK_VBELN,
		B28_VBAP_ZMENG,
		B28_ZF_VBAP_NETWR_S_CUC,
		CASE 
			WHEN ZF_ZF_VBRP_NETWR_S_CUC_SUM>B28_ZF_VBAP_NETWR_S_CUC THEN 'Higher'
			WHEN ZF_ZF_VBRP_NETWR_S_CUC_SUM=B28_ZF_VBAP_NETWR_S_CUC THEN 'Equal'
			WHEN ZF_ZF_VBRP_NETWR_S_CUC_SUM<B28_ZF_VBAP_NETWR_S_CUC THEN 'Lower'
        END AS ZF_COMPARE_VBRP_VBAP_NETWR,
		CASE 
			WHEN ZF_VBRP_FKIMG_SUM>B28_VBAP_ZMENG THEN 'Higher'
			WHEN ZF_VBRP_FKIMG_SUM=B28_VBAP_ZMENG THEN 'Equal'
			WHEN ZF_VBRP_FKIMG_SUM<B28_VBAP_ZMENG THEN 'Lower'
        END AS ZF_COMPARE_VBRP_VBAP_FKIMG_ZMENG
INTO SU24_05_TT_VBRK_VBRP_COMPARE_VBAP_VBAK
FROM SU24_04_TT_VBRK_VBRP_GROUP_BY_AUBEL_AUPOS
LEFT JOIN SU24_02_TT_VBAP_SALE_ORDER
ON B30_VBRP_AUPOS=B28_VBAP_POSNR AND 
   B30_VBRP_AUBEL=B28_VBAK_VBELN

--Remove table
EXEC SP_DROPTABLE SU24_04_TT_VBRK_VBRP_GROUP_BY_AUBEL_AUPOS

--Step 3.3 Add back the flag to sale order
EXEC SP_DROPTABLE 'SU24_06_RT_VBAK_VBAP_ADD_FLAG'

SELECT A.* ,
	   ZF_COMPARE_VBRP_VBAP_NETWR,
	   ZF_COMPARE_VBRP_VBAP_FKIMG_ZMENG,
	   IIF(LEN(TVAP_FEHGR)>0,'Yes','No') AS ZF_TVAP_FEHGR_IS_SET,
	   IIF(LEN(TVAP_PRSFD)>0,'Yes','No') AS ZF_TVAP_PRSFD_IS_SET
INTO SU24_06_RT_VBAK_VBAP_ADD_FLAG 
FROM SU24_02_TT_VBAP_SALE_ORDER AS A
LEFT JOIN SU24_05_TT_VBRK_VBRP_COMPARE_VBAP_VBAK AS B
	ON A.B28_VBAP_POSNR=B.B28_VBAP_POSNR AND
		A.B28_VBAK_VBELN=B.B28_VBAK_VBELN
LEFT JOIN SU24_01_XT_TVAP_SALE_DOC_ITEM_CATEGORIES_SETTING
ON TVAP_PSTYV = B28_VBAP_PSTYV

--Step 3.4 Add back the flag to SD invoice
EXEC SP_DROPTABLE 'SU24_07_RT_VBRK_VBRP_ADD_FLAG'

SELECT DISTINCT
	   A.* ,
	   B.ZF_COMPARE_VBRP_VBAP_NETWR,
	   B.ZF_COMPARE_VBRP_VBAP_FKIMG_ZMENG,
	   ZF_TVAP_FEHGR_IS_SET,
	   ZF_TVAP_PRSFD_IS_SET
INTO SU24_07_RT_VBRK_VBRP_ADD_FLAG
FROM SU24_03_TT_SD_INV AS A
LEFT JOIN SU24_05_TT_VBRK_VBRP_COMPARE_VBAP_VBAK AS B
	ON A.B30_VBRP_AUBEL=B.B30_VBRP_AUBEL AND
		A.B30_VBRP_AUPOS=B.B30_VBRP_AUPOS
LEFT JOIN SU24_06_RT_VBAK_VBAP_ADD_FLAG AS C
ON C.B28_VBAK_VBELN = A.B30_VBRP_AUBEL
AND C.B28_VBAP_POSNR = A.B30_VBRP_AUPOS

-- Remove temporary table
EXEC SP_REMOVE_TABLES 'SU24_%[_]TT[_]%'

-- Unname the fields
EXEC SP_UNNAME_FIELD 'B28_', 'SU24_06_RT_VBAK_VBAP_ADD_FLAG'
EXEC SP_UNNAME_FIELD 'B30_', 'SU24_07_RT_VBRK_VBRP_ADD_FLAG'

-- Rename the fields
EXEC SP_RENAME_FIELD 'SU24_01_', 'SU24_01_XT_TVAP_SALE_DOC_ITEM_CATEGORIES_SETTING'
EXEC SP_RENAME_FIELD 'SU24_06_', 'SU24_06_RT_VBAK_VBAP_ADD_FLAG'
EXEC SP_RENAME_FIELD 'SU24_07_', 'SU24_07_RT_VBRK_VBRP_ADD_FLAG'


GO
