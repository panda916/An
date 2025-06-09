USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_BO09_SALE_DOCUMENT_ITEM_CATEGORY]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START
EXEC SP_REMOVE_TABLES 'BO09_01_IT_TVAP_SALE_DOCUMENT_ITEM_CATEGORY'

-- Create sale document item category cube
SELECT 
	A_TVAP.*,
	TVAPT_VTEXT,
	-- Add TVAP_PRSFD- Carry out pricing description
	(
			CASE
				WHEN TVAP_PRSFD = '' THEN 'No pricing'
				WHEN TVAP_PRSFD = 'X' THEN 'Pricing standard'
				WHEN TVAP_PRSFD = 'A' THEN 'Pricing for empties'
				WHEN TVAP_PRSFD = 'B' THEN 'Pricing for free goods (100% discount)'
			END
	) AS ZF_TVAP_PRSFD_DESCRIPTION,
	CASE 
	
		WHEN TVAP_FKREL=''	THEN  'Not relevant for billing'	
		WHEN TVAP_FKREL='A'	THEN  '	Delivery-related billing document'
		WHEN TVAP_FKREL='B'	THEN  '	Relevant for order-related billing - status acc.to order qty'
		WHEN TVAP_FKREL='C'	THEN  '	Relevant for ord.-related billing - status acc.to target qty'
		WHEN TVAP_FKREL='D'	THEN  '	Relevant for pro forma'
		WHEN TVAP_FKREL='F'	THEN  '	Order-related billing doc. - status according to invoice qty'
		WHEN TVAP_FKREL='G'	THEN  '	Order-related billing of the delivery quantity'
		WHEN TVAP_FKREL='H'	THEN  '	Delivery-related billing - no zero quantities'
		WHEN TVAP_FKREL='I'	THEN  '	Order-relevant billing - billing plan'
		WHEN TVAP_FKREL='J'	THEN  '	Relevant for deliveries across EU countries'
		WHEN TVAP_FKREL='K'	THEN  '	Delivery-related invoices for partial quantity'
		WHEN TVAP_FKREL='L'	THEN  '	Pro forma - no zero quantities'
		WHEN TVAP_FKREL='M'	THEN  '	Delivery-related invoices-no zero qtys (incl main batch itm)'
		WHEN TVAP_FKREL='N'	THEN  '	Pro forma - no zero quantities (including main batch items)'
		WHEN TVAP_FKREL='P'	THEN  '	Delivery-related invoices for CSFG - No batch split items'
		WHEN TVAP_FKREL='Q'	THEN  '	Delivery-related invoices for CRM'
		WHEN TVAP_FKREL='R'	THEN  '	Delivery-related invoices for CRM - No zero quantities'
		WHEN TVAP_FKREL='S'	THEN  '	IBS-DI: Order-Related Bill. Doc. with DP w/o Billing Plan'
		WHEN TVAP_FKREL='T'	THEN  '	Delivery-Related Invoices for CRM with IB in CRM'
		WHEN TVAP_FKREL='U'	THEN  '	Delivery-Rel. Invoices for CRM with IB in CRM - No Zero Qtys'
		WHEN TVAP_FKREL='V'	THEN  '	Delivery-Related ICB of Stock Transport Orders in CRM' END AS ZF_TVAP_FKREL_DESCRIPTION,
	TVUVT_BEZEI
INTO BO09_01_IT_TVAP_SALE_DOCUMENT_ITEM_CATEGORY
FROM A_TVAP
LEFT JOIN A_TVAPT
-- Get TVAP_PSTYV-sales document item category description
ON TVAP_PSTYV = TVAPT_PSTYV
-- Get TVAP_FEHGR-Incompleteness procedure for sales document description
LEFT JOIN A_TVUVT
ON TVAP_FEHGR = TVUVT_FEHGR
WHERE TVUVT_SPRAS IN ('E','EN')
GO
