USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU29A_Identify delivery documents that do not require/ copy from the sales order]
AS
--DYNAMIC_SCRIPT_START

--Objective: Identify delivery documents that do not require/ copy from the sales order
--Step 1: Identify delivery documents that are not in the table A_TVCPL 


EXEC SP_DROPTABLE SU29A_01_XT_LIPS_VGBEL_NOT_IN_VBFA_VBELV;

SELECT DISTINCT 
     B34_01_IT_DELIVERY_DOCS.*,
	 CASE B34_TVLK_AUFER 
	      WHEN ' ' THEN '-No preceding documents required'
		  WHEN 'X' THEN 'X-Sales order required'
		  WHEN 'B' THEN 'B-Purchase order required'
		  WHEN 'L' THEN 'L-Delivery for subcontracting'
		  WHEN 'P' THEN 'P-Project required'
		  WHEN 'U' THEN 'U-Stock transfer w/o previous activity'
		  WHEN 'R' THEN 'R-Return delivery to vendor'
		  WHEN 'O' THEN 'O-Goods movement through inb.deliv. / post.chge /outb. deliv.'
		  WHEN 'W' THEN 'W-Delivery from PP interface (work order)'
		  WHEN 'H' THEN 'H-Posting change with delivery' END AS ZF_TVLK_AUFER_DESC,
		  IIF(LEN(B34_TVLK_AUFER) = 0,'No','Yes') AS ZF_TVLK_AUFER_BLANK_OR_NOT
INTO SU29A_01_XT_LIPS_VGBEL_NOT_IN_VBFA_VBELV
FROM B34_01_IT_DELIVERY_DOCS

--Step 2: Identify sale/order document related to delivery documents that do not require/ copy from the sale order 


EXEC SP_DROPTABLE SU29A_02_XT_VBAP_VBELN_POSNR 

SELECT DISTINCT *
	INTO SU29A_02_XT_VBAP_VBELN_POSNR 
	FROM B33_01_IT_SALE_DOCUMENTS A
	JOIN SU29A_01_XT_LIPS_VGBEL_NOT_IN_VBFA_VBELV B
	ON B.B34_LIPS_VGBEL = A.B33_VBAK_VBELN AND B.B34_LIPS_VGPOS = A.B33_VBAP_POSNR
WHERE LEN(B.B34_TVLK_AUFER) = 0 

--Step 3: Identify billing documents related to delivery documents that do not require/ copy from the sale order

EXEC SP_DROPTABLE SU29A_03_XT_VBRP_VGBEL_VGPOS 
SELECT C.*,
       D.*
	INTO SU29A_03_XT_VBRP_VGBEL_VGPOS 
	FROM B36_01_IT_INVOICE_DOCS C
	JOIN SU29A_01_XT_LIPS_VGBEL_NOT_IN_VBFA_VBELV D
	ON D.B34_LIKP_VBELN = C.B36_VBRP_VGBEL AND D.B34_LIPS_POSNR = C.B36_VBRP_VGPOS
WHERE LEN(D.B34_TVLK_AUFER) = 0
   
-- Step 4: Change request: Get full list of delivery types
EXEC SP_DROPTABLE SU29A_04_RT_TVLK_LFART 
SELECT DISTINCT A_TVLK.TVLK_LFART,
		CASE 
			WHEN LEN(SU29A_01_XT_LIPS_VGBEL_NOT_IN_VBFA_VBELV.B34_LIKP_LFART) > 0 THEN 'Yes' 
			ELSE 'No' 
		END AS ZF_TVLK_LFART_USED_OR_NOT_USED,
		CASE A_TVLK.TVLK_AUFER 
	      WHEN ' ' THEN '-No preceding documents required'
		  WHEN 'X' THEN 'X-Sales order required'
		  WHEN 'B' THEN 'B-Purchase order required'
		  WHEN 'L' THEN 'L-Delivery for subcontracting'
		  WHEN 'P' THEN 'P-Project required'
		  WHEN 'U' THEN 'U-Stock transfer w/o previous activity'
		  WHEN 'R' THEN 'R-Return delivery to vendor'
		  WHEN 'O' THEN 'O-Goods movement through inb.deliv. / post.chge /outb. deliv.'
		  WHEN 'W' THEN 'W-Delivery from PP interface (work order)'
		  WHEN 'H' THEN 'H-Posting change with delivery' END AS ZF_TVLK_AUFER_DESC,
		  ZF_TVLK_AUFER_BLANK_OR_NOT
INTO SU29A_04_RT_TVLK_LFART
FROM A_TVLK		
LEFT JOIN SU29A_01_XT_LIPS_VGBEL_NOT_IN_VBFA_VBELV
ON A_TVLK.TVLK_LFART = SU29A_01_XT_LIPS_VGBEL_NOT_IN_VBFA_VBELV.B34_LIKP_LFART	

EXEC SP_UNNAME_FIELD 'B34_','SU29A_01_XT_LIPS_VGBEL_NOT_IN_VBFA_VBELV';
EXEC SP_RENAME_FIELD 'SU29A_01_','SU29A_01_XT_LIPS_VGBEL_NOT_IN_VBFA_VBELV';

EXEC SP_UNNAME_FIELD 'B33_','SU29A_02_XT_VBAP_VBELN_POSNR';
EXEC SP_UNNAME_FIELD 'B34_','SU29A_02_XT_VBAP_VBELN_POSNR';
EXEC SP_RENAME_FIELD 'SU29A_02_','SU29A_02_XT_VBAP_VBELN_POSNR';

EXEC SP_UNNAME_FIELD 'B34_','SU29A_03_XT_VBRP_VGBEL_VGPOS';
EXEC SP_UNNAME_FIELD 'B36_','SU29A_03_XT_VBRP_VGBEL_VGPOS';
EXEC SP_RENAME_FIELD 'SU29A_03_','SU29A_03_XT_VBRP_VGBEL_VGPOS';

EXEC SP_RENAME_FIELD 'SU29A_04_','SU29A_04_RT_TVLK_LFART';


GO
