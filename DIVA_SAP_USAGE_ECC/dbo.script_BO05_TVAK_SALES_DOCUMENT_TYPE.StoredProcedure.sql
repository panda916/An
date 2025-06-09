USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_BO05_TVAK_SALES_DOCUMENT_TYPE]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START
-- Step 1: Create cube for sales document type and add descriptions

EXEC SP_REMOVE_TABLES 'BO05_01_IT_TVAK_SALE_DOCUMENT_TYPE'

SELECT DISTINCT
	A_TVAK.*,
	TVAKT_BEZEI,
	TVHBT_BEZEI,
	A_TVLKT.TVLKT_VTEXT AS TVLKT_VTEXT_TVAK,
	A_TVFKT.TVFKT_VTEXT AS TVFKT_VTEXT_TVAK,
	A_TVFST.TVFST_VTEXT AS TVFST_VTEXT_TVAK,
	A.TVFKT_VTEXT AS TVFKT_VTEXT_TVAK_FKARA,
	-- Add TVAK_BEZOB-reference mandatory description
	(
		CASE
			WHEN LEN(TVAK_BEZOB) < 1 THEN 'No reference required'
			WHEN TVAK_BEZOB = 'A' THEN 'With reference to an inquiry'
			WHEN TVAK_BEZOB = 'B' THEN 'With reference to a quotation'
			WHEN TVAK_BEZOB = 'C' THEN 'With reference to a sales order'
			WHEN TVAK_BEZOB = 'E' THEN 'Scheduling agreement reference'
			WHEN TVAK_BEZOB = 'G' THEN 'With reference to a quantity contract'
			WHEN TVAK_BEZOB = 'M' THEN 'With ref.to billing document'
			ELSE ''
		END
	) AS ZF_TVAK_BEZOB_DESCRIPTION,
	CASE TVAK_VBTYP
		WHEN 'A' THEN	'Inquiry'
		WHEN 'B' THEN	'Quotation'
		WHEN 'C' THEN	'Order'
		WHEN 'D' THEN	'Item proposal'
		WHEN 'E' THEN	'Scheduling agreement'
		WHEN 'F' THEN	'Scheduling agreement with external service agent'
		WHEN 'G' THEN	'Contract'
		WHEN 'H'	THEN 'Returns'
		WHEN 'I'	THEN	'Order w/o charge'
		WHEN 'J'	THEN	'Delivery'
		WHEN 'K'	THEN	'Credit memo request'
		WHEN 'L'	THEN	'Debit memo request'
		WHEN 'M'	THEN	'Invoice'
		WHEN 'N'	THEN	'Invoice cancellation'
		WHEN 'O'	THEN	'Credit memo'
		WHEN 'P'	THEN	'Debit memo'
		WHEN 'Q'	THEN	'WMS transfer order'
		WHEN 'R'	THEN	'Goods movement'
		WHEN 'S'	THEN	'Credit memo cancellation'
		WHEN 'T'	THEN	'Returns delivery for order'
		WHEN 'U'	THEN	'Pro forma invoice'
		WHEN 'V'	THEN	'Purchase Order'
		WHEN 'W'	THEN	'Independent reqts plan'
		WHEN 'X'	THEN	'Handling unit'
		WHEN '0'	THEN	'Master contract'
		WHEN '1'	THEN	'Sales activities (CAS)'
		WHEN '2'	THEN	'External transaction'
		WHEN '3'	THEN	'Invoice list'
		WHEN '4'	THEN	'Credit memo list'
		WHEN '5'	THEN	'Intercompany invoice'
		WHEN '6'	THEN	'Intercompany credit memo'
		WHEN '7'	THEN	'Delivery/shipping notification'
		WHEN '8'	THEN	'Shipment'
		WHEN 'a'	THEN	'Shipment costs'
		WHEN 'b'	THEN	'CRM Opportunity'
		WHEN 'c'	THEN	'Unverified delivery'
		WHEN 'd'	THEN	'Trading Contract'
		WHEN 'e'	THEN	'Allocation table'
		WHEN 'f'	THEN	'Additional Billing Documents'
		WHEN 'g'	THEN	'Rough Goods Receipt (only IS-Retail)'
		WHEN 'h'	THEN	'Cancel Goods Issue'
		WHEN 'i'	THEN	'Goods receipt'
		WHEN 'j'	THEN	'JIT call'
		WHEN 'n'	THEN	'Reserved'
		WHEN 'o'	THEN	'Reserved'
		WHEN 'p'	THEN	'Goods Movement (Documentation)'
		WHEN 'q'	THEN	'Reserved'
		WHEN 'r'	THEN	'TD Transport (only IS-Oil)'
		WHEN 's'	THEN	'Load Confirmation, Reposting (Only IS-Oil)'
		WHEN 't'	THEN	'Gain / Loss (Only IS-Oil)'
		WHEN 'u'	THEN	'Reentry into Storage (Only IS-Oil)'
		WHEN 'v'	THEN	'Data Collation (only IS-Oil)'
		WHEN 'w'	THEN	'Reservation (Only IS-Oil)'
		WHEN 'x'	THEN	'Load Confirmation, Goods Receipt (Only IS-Oil)'
		WHEN '$'	THEN	'(AFS)'
		WHEN '+'	THEN	'Accounting Document (Temporary)'
		WHEN '-'	THEN	'Accounting Document (Temporary)'
		WHEN '#'	THEN	'Revenue Recognition (Temporary)'
		WHEN '~'	THEN	'Revenue Cancellation (Temporary)'
		WHEN '?'	THEN	'Revenue Recognition/New View (Temporary)'
		WHEN '' THEN	'Revenue Cancellation/New View (Temporary)'
		WHEN ':'	THEN	'Service Order'
		WHEN '.'	THEN	'Service Notification'
		WHEN '&'	THEN	'Warehouse Document'
		WHEN '*'	THEN	'Pick Order'
		WHEN ','	THEN	'Shipment Document'
		WHEN '^'	THEN	'Reserved'
		WHEN '|'	THEN	'Reserved'
		WHEN 'k'	THEN	'Agency Document' END AS ZF_TVAK_VBTYP_DESCRIPTION
INTO BO05_01_IT_TVAK_SALE_DOCUMENT_TYPE
FROM  A_TVAK
-- Get sales document type description
LEFT JOIN A_TVAKT
ON TVAK_AUART = TVAKT_AUART
-- Get screen sequence group for document header & item description
LEFT JOIN A_TVHBT
ON TVAK_KOPGR = TVHBT_BIFGR AND TVHBT_SPRAS='EN'
-- Get delivery types description
LEFT JOIN A_TVLKT
ON TVAK_LFARV = TVLKT_LFART
-- Get billing document type  for a delivery-related billing doc. description
LEFT JOIN A_TVFKT
ON TVAK_FKARV = TVFKT_FKART
-- Get billing type for an order-related billing document
LEFT JOIN A_TVFKT AS A
ON TVAK_FKARA = A.TVFKT_FKART
-- Get billing: block reason description
LEFT JOIN A_TVFST
ON TVAK_FAKSK = TVFST_FAKSP


GO
