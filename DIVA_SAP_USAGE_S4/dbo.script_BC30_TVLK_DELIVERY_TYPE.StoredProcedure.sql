USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_BC30_TVLK_DELIVERY_TYPE]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START
EXEC SP_REMOVE_TABLES 'BC30_01_IT_TVLK_DELIVERY_DOCS'
SELECT
	A_TVLK.*,
	A_TVLKT.TVLKT_VTEXT AS ZF_TVLK_LFART_DESCRIPTION,
	-- Add TVLK_AUFER-A sales order is required as basis for delivery description
	(
		CASE
			WHEN TVLK_AUFER = ''  THEN 'No preceding documents required'
			WHEN TVLK_AUFER = 'X' THEN 'Sales order required'
			WHEN TVLK_AUFER = 'B' THEN 'Purchase order required'
			WHEN TVLK_AUFER = 'L' THEN 'Delivery for subcontracting'
			WHEN TVLK_AUFER = 'P' THEN 'Project required'
			WHEN TVLK_AUFER = 'U' THEN 'Stock transfer w/o previous activity'
			WHEN TVLK_AUFER = 'R' THEN 'Return delivery to vendor'
			WHEN TVLK_AUFER = 'O' THEN 'Goods movement through inb.deliv. / post.chge /outb. deliv.'
			WHEN TVLK_AUFER = 'W' THEN 'Delivery from PP interface (work order)'
			WHEN TVLK_AUFER = 'H' THEN 'Posting change with delivery'
		END
	) AS ZF_TVLK_AUFER_DESCRIPTION
INTO BC30_01_IT_TVLK_DELIVERY_DOCS
FROM A_TVLK
-- Get delivery type description
LEFT JOIN A_TVLKT
ON TVLK_LFART = TVLKT_LFART


GO
