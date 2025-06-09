USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_SU19_Identify delivery item categories that don't block overdelivery]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START

-- -- Script objective :Delivery item categories in the SAP system have been configured to prevent an over-delivery of a sales order.

-- Step 1:  Create table to check sales order is required as basis for delivery 
		EXEC SP_REMOVE_TABLES 'SU19_01_RT_LIKP_DELIVERY_TYPES_REQUIRE_AS_BASIS'

		SELECT DISTINCT
			A_TVLK.*,
			TVLKT_VTEXT,
			-- Add TVLK_AUFER description
			(
				CASE
					WHEN LEN(TVLK_AUFER) < 1	THEN 'No preceding documents required'
					WHEN TVLK_AUFER = 'X'	THEN 'Sales order required'
					WHEN TVLK_AUFER = 'B'	THEN 'Purchase order required'
					WHEN TVLK_AUFER = 'L'	THEN 'Delivery for subcontracting'
					WHEN TVLK_AUFER = 'P'	THEN 'Project required'
					WHEN TVLK_AUFER = 'U'	THEN 'Stock transfer w/o previous activity'
					WHEN TVLK_AUFER = 'R'	THEN 'Return delivery to vendor'
					WHEN TVLK_AUFER = 'O'	THEN 'Goods movement through inb.deliv. / post.chge /outb. deliv.'
					WHEN TVLK_AUFER = 'W'	THEN 'Delivery from PP interface (work order)'
					WHEN TVLK_AUFER = 'H'	THEN 'Posting change with delivery'
				END
			) AS ZF_TVLK_AUFER_DESCRIPTION,
			-- Add sales order is required as basis for delivery flag
			(
				CASE
					WHEN LEN(TVLK_AUFER) = 0 THEN 'Yes'
					ELSE 'No'
				END
			) AS ZF_TVLK_AUFER_REQUIRED_AS_BASIS_FLAG
		INTO SU19_01_RT_LIKP_DELIVERY_TYPES_REQUIRE_AS_BASIS
		FROM A_TVLK
		LEFT JOIN A_TVLKT
		ON TVLKT_SPRAS IN ('E', 'EN')
		AND TVLKT_LFART = TVLK_LFART
-- Step 2: Check error of Control for checking for overdelivery in TVLP table 

		EXEC SP_REMOVE_TABLES 'SU19_02_XT_TVLP_DELIVERY_OVERDELIVERY'
		SELECT 
		*,
		-- Add flag to show deliverys are over-delivery
		(
			CASE
				WHEN TVLP_UEBPR IN ('','A') THEN 'Yes'
				ELSE 'No'
			END
		) AS ZF_TVLP_UEBPR_OVER_DEL_ALLOWED 
		INTO SU19_02_XT_TVLP_DELIVERY_OVERDELIVERY
		FROM BO08_01_IT_DELIVERY_ITEM_CATEGORY

-- Step 3: Create cube for sales order. Just get sales order type is order(VBAP_VBTYV = C)
--Get only the lines have delivery

		EXEC SP_REMOVE_TABLES 'SU19_03_TT_VBAP_SALE_ORDER'
		SELECT *
		INTO SU19_03_TT_VBAP_SALE_ORDER
		FROM B33_01_IT_SALE_DOCUMENTS
		WHERE B33_VBAK_VBTYP = 'C'
		AND B33_VBAK_VBELN+B33_VBAP_POSNR IN
		(
	
			SELECT DISTINCT B34_LIPS_VGBEL+B34_LIPS_VGPOS FROM B34_01_IT_DELIVERY_DOCS
		)

-- Step 4: Create cube for SD document: Delivery: Item data, get only the line relate to sale orders

		EXEC SP_REMOVE_TABLES 'SU19_04_TT_LIKP_DELIVERY_DOCS'
		SELECT B34_01_IT_DELIVERY_DOCS.*,
			ZF_MARA_MATNR_DESC,
			TVPT_Description
		INTO SU19_04_TT_LIKP_DELIVERY_DOCS
		FROM B34_01_IT_DELIVERY_DOCS
		-- Get material description
		LEFT JOIN BC12_01_IT_MARA_VS_MAKT_ADD_MAKT_MAKTX
		ON B34_LIPS_MATNR = MARA_MATNR
		-- Get delivery item category description
		LEFT JOIN A_TVPT
		ON B34_LIPS_PSTYV = TVPT_PSTYV
		-- Get name text of person who created the object
		LEFT JOIN A_V_USERNAME
		ON B34_LIKP_ERNAM = V_USERNAME_BNAME
		WHERE B34_LIPS_VGBEL+B34_LIPS_VGPOS IN
		(
			SELECT DISTINCT B33_VBAK_VBELN+B33_VBAP_POSNR FROM B33_01_IT_SALE_DOCUMENTS
			WHERE B33_VBAK_VBTYP = 'C'
		)

--Step 5: 1 sale order can have many delivery lines, 
-- To compare between Target quantity in sales units and the actual delivery unit
-- In delivery cube,sum total LIPS_LFIMG group by LIPS_VGBEL,LIPS_VGPOS
--Then link back to sale document to  do compare 
--Step 5.1 Summarize LIKP-LIPS base on LIPS_VGBEL,LIPS_VGPOS
		EXEC SP_DROPTABLE SU19_05_TT_LIKP_LIPS_SUMMARY_VGBEL_VGPOS

		SELECT
			LIPS_VGBEL,LIPS_VGPOS,
			SUM(LIPS_LFIMG) AS ZF_TOTAL_LIPS_LFIMG
		INTO SU19_05_TT_LIKP_LIPS_SUMMARY_VGBEL_VGPOS
		FROM SU19_04_TT_LIKP_DELIVERY_DOCS
		GROUP BY	
			LIPS_VGBEL,
			LIPS_VGPOS

--Step 5.2 Link back to sale document cube, to get the target quantity
--then compare between actual quantity and target quantity
--Get only the case where actual quantity higher than target quantity
		EXEC SP_DROPTABLE SU19_06_TT_LIKP_LIPS_COMPARE_VBAK_VBAP

		SELECT SU19_05_TT_LIKP_LIPS_SUMMARY_VGBEL_VGPOS.*,
				B33_VBAK_VBELN,
				B33_VBAP_POSNR,
				B33_VBAP_ZMENG
		INTO SU19_06_TT_LIKP_LIPS_COMPARE_VBAK_VBAP
		FROM SU19_05_TT_LIKP_LIPS_SUMMARY_VGBEL_VGPOS
		LEFT JOIN SU19_03_TT_VBAP_SALE_ORDER
		ON LIPS_VGBEL=B33_VBAK_VBELN AND
		   LIPS_VGPOS=B33_VBAP_POSNR
		WHERE ZF_TOTAL_LIPS_LFIMG>B33_VBAP_ZMENG

--Remove temporary table
EXEC SP_DROPTABLE SU19_05_TT_LIKP_LIPS_SUMMARY_VGBEL_VGPOS

--Step 5.3 Get the delivery where actual quantity higher than target quantity
		EXEC SP_REMOVE_TABLES 'SU19_07_XT_LIKP_DELIVERY_DOCS_LFIMG_HIGHER_ZMENG'

		SELECT * 
		INTO SU19_07_XT_LIKP_DELIVERY_DOCS_LFIMG_HIGHER_ZMENG
		FROM
		SU19_04_TT_LIKP_DELIVERY_DOCS
		WHERE LIPS_VGBEL+LIPS_VGPOS IN
		(
			SELECT DISTINCT LIPS_VGBEL+LIPS_VGPOS FROM SU19_06_TT_LIKP_LIPS_COMPARE_VBAK_VBAP
		)

		EXEC SP_DROPTABLE SU19_04_TT_LIKP_DELIVERY_DOCS
--Step 5.4 Get the sale document where actual quantity higher than target quantity

		EXEC SP_DROPTABLE 'SU19_08_XT_VBAP_SALE_ORDER_LFIMG_HIGHER_ZMENG'
		
		SELECT *
		INTO SU19_08_XT_VBAP_SALE_ORDER_LFIMG_HIGHER_ZMENG
		FROM SU19_03_TT_VBAP_SALE_ORDER
		WHERE B33_VBAP_POSNR+B33_VBAK_VBELN IN 
		(
			SELECT DISTINCT B33_VBAP_POSNR+B33_VBAK_VBELN FROM SU19_06_TT_LIKP_LIPS_COMPARE_VBAK_VBAP

		)

		EXEC SP_DROPTABLE SU19_03_TT_VBAP_SALE_ORDER
		EXEC SP_DROPTABLE SU19_06_TT_LIKP_LIPS_COMPARE_VBAK_VBAP


-- Unname the fields
EXEC SP_UNNAME_FIELD 'B33_', 'SU19_08_XT_VBAP_SALE_ORDER_LFIMG_HIGHER_ZMENG'
-- Rename the fiedls
EXEC SP_RENAME_FIELD 'SU19_01_', 'SU19_01_RT_LIKP_DELIVERY_TYPES_REQUIRE_AS_BASIS'
EXEC SP_RENAME_FIELD 'SU19_02_', 'SU19_02_XT_TVLP_DELIVERY_OVERDELIVERY'
EXEC SP_RENAME_FIELD 'SU19_07_', 'SU19_07_XT_LIKP_DELIVERY_DOCS_LFIMG_HIGHER_ZMENG'
EXEC SP_RENAME_FIELD 'SU19_08_', 'SU19_08_XT_VBAP_SALE_ORDER_LFIMG_HIGHER_ZMENG'

GO
