USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_BC13_T685A_SALES_CONDITION_TYPES]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START
EXEC SP_REMOVE_TABLES 'BC13_01_IT_T685A_SALES_CONDITION_TYPES'

SELECT A_T685A.*,
	T685T_VTEXT,
	DD07T_DDTEXT,
	A_T681B.T681B_VTEXT,
	-- Add T685A_KRECH description
	(
		CASE
			WHEN T685A_KRECH = 'A' THEN 'Percentage'	
			WHEN T685A_KRECH = 'B' THEN 'Fixed amount'	
			WHEN T685A_KRECH = 'C' THEN 'Quantity'	
			WHEN T685A_KRECH = 'D' THEN 'Gross weight'	
			WHEN T685A_KRECH = 'E' THEN 'Net weight'	
			WHEN T685A_KRECH = 'F' THEN 'Volume'	
			WHEN T685A_KRECH = 'G' THEN 'Formula'	
			WHEN T685A_KRECH = 'H' THEN 'Percentage included'	
			WHEN T685A_KRECH = 'I' THEN 'Percentage (travel expenses)'	
			WHEN T685A_KRECH = 'K' THEN 'Per mille'	
			WHEN T685A_KRECH = 'J' THEN 'Per mille'	
			WHEN T685A_KRECH = 'L' THEN 'Points'	
			WHEN T685A_KRECH = 'M' THEN 'Quantity - monthy price'	
			WHEN T685A_KRECH = 'N' THEN 'Quantity - yearly price'	
			WHEN T685A_KRECH = 'O' THEN 'Quantity - daily price'	
			WHEN T685A_KRECH = 'P' THEN 'Quantity - weekly price'	
			WHEN T685A_KRECH = 'Q' THEN 'Commodity Price'	
			WHEN T685A_KRECH = 'R' THEN 'Distance-dependent'	
			WHEN T685A_KRECH = 'S' THEN 'Number of shipping units'	
			WHEN T685A_KRECH = 'T' THEN 'Multi-dimensional'	
			WHEN T685A_KRECH = 'U' THEN 'Percentage FIN (CRM Only)'	
		END
	) AS ZF_T685A_KRECH_DESCRIPTION,
	-- Add Condition class description
	(
		CASE T685A_KOAID
			WHEN 'A' THEN 'Discount or surcharge'	
			WHEN 'B' THEN 'Prices'	
			WHEN 'C' THEN 'Expense reimbursement'	
			WHEN 'D' THEN 'Taxes'	
			WHEN 'E' THEN 'Extra pay'	
			WHEN 'F' THEN 'Fees or differential (only IS-OIL)'	
			WHEN 'G' THEN 'Tax Classification'	
			WHEN 'H' THEN 'Determining sales deal'	
			WHEN 'Q' THEN 'Totals record for fees (only IS-OIL)'	
			WHEN 'W' THEN 'Wage Withholding Tax'	
		END
	) AS ZF_T685A_KOAID_DESCRIPTION
INTO BC13_01_IT_T685A_SALES_CONDITION_TYPES
FROM A_T685A
-- Get condition type description
LEFT JOIN A_T685T
ON T685A_KSCHL = T685T_KSCHL
AND T685A_KAPPL = T685T_KAPPL
-- Get T685A_KAPPL-Applications description
LEFT JOIN A_T681B
ON T681B_KAPPL = T685A_KAPPL
-- Get the T685A_KMANU description from A_DD07T table
LEFT JOIN A_DD07T
ON T685A_KMANU = DD07T_DOMVALUE_L
WHERE DD07T_DOMNAME = 'KMANU'
AND T685T_SPRAS IN  ('E','EN')
AND T681B_SPRAS IN  ('E','EN')
AND  A_T681B.T681B_SPRAS IN ('E','EN')
GO
