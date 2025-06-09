USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  StoredProcedure [dbo].[BC31_TVCPF_TVFK_TVFKT_TVAP_TVAPT_TVLK_TVLKT_TVAKT_TVAK]    Script Date: 3/27/2023 2:41:42 PM ******/
CREATE PROCEDURE [dbo].[script_BC31_TVCPF_TVFK_TVFKT_TVAP_TVAPT_TVLK_TVLKT_TVAKT_TVAK]
AS
--DYNAMIC_SCRIPT_START
---Objective: Create B cube table for SU29C 

EXEC SP_DROPTABLE BC31_01_IT_TVCPF_TVFK_TVFKT_TVAP_TVAPT_TVLK_TVLKT_TVAKT_TVAK;
SELECT TVCPF_FKARN+'-'+A.TVFKT_VTEXT AS ZF_TVCPF_FKARN_DESC,
       TVCPF_FKARN,
       TVCPF_AUARV+'-'+TVAKT_BEZEI AS ZF_TVCPF_AUARV_DESC,
	   TVCPF_AUARV,
	   TVCPF_LFARV+'-'+TVLKT_VTEXT AS ZF_TVCPF_LFARV_DESC,
	   TVCPF_FKARV,
	   A.TVFKT_VTEXT AS ZF_TVFKT_VTEXT_FKARN,
	   B.TVFKT_VTEXT AS ZF_TVFKT_VTEXT_FKARV,
	   TVCPF_PSTYV+'-'+TVAPT_VTEXT AS ZF_TVCPF_PSTYV_DESC,
	   TVCPF_PSTYV,
--	   IIF(LEN(TRIM(TVAK_CPFREE)) = 0, 'No','Yes') AS ZF_TVAK_CPFREE_DESC,
	   --Add description code for TVLK_AUFER
	   CASE TVLK_AUFER 
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
	    --Add description code for TVCPF_KNPRS
	   CASE TVCPF_KNPRS
	      WHEN 'A' THEN 'A-Copy price components and redetermine scales'
		  WHEN 'B' THEN 'B-Carry out new pricing'
          WHEN 'C' THEN 'C-Copy manual pricing elements and redetermine the others'
          WHEN 'D' THEN 'D-Copy pricing elements unchanged'
          WHEN 'E' THEN 'E-Adopt price components and fix values'
          WHEN 'F' THEN 'F-Copy pricing elements, turn value and fix'
          WHEN 'G' THEN 'G-Copy pricing elements unchanged and redetermine taxes'
          WHEN 'H' THEN 'H-Redetermine freight conditions'
          WHEN 'I' THEN 'I-Redetermine rebate conditions'
          WHEN 'J' THEN 'J-Redetermine confirmed purch. net price / value (KNTYP=d)'
          WHEN 'K' THEN 'K-Adopt price components and cose. Redetermine taxes.'
          WHEN 'M' THEN 'M-Copy pricing elements, turn value'
          WHEN 'N' THEN 'N-Transfer pricing components unchanged, new cost'
          WHEN 'O' THEN 'O-Redetermine variant conditions (KNTYP=O)'
          WHEN 'Q' THEN 'Q-Redetermine calculation conditions (KNTYP=Q)'
          WHEN 'R' THEN 'R-Apply Price Parts and Bonus Conditions'
          WHEN 'U' THEN 'U-Redetermine precious metal conditions (KNTYP=U)'
          WHEN 'X' THEN 'X-Customer reserve X'
          WHEN 'Y' THEN 'Y-Customer reserve Y'
          WHEN 'Z' THEN 'Z-Customer reserve Z'
          WHEN '1' THEN '1-Customer reserve 1'
          WHEN '2' THEN '2-Customer reserve 2'
		  WHEN '3' THEN '3-Customer reserve 3'
     	  WHEN '4' THEN '4-Customer reserve 4'
		  WHEN '5' THEN '5-Customer reserve 5'
		  WHEN '6' THEN '6-Customer reserve 6'
		  WHEN '7' THEN	'7-Customer reserve 7'
		  WHEN '8' THEN '8-Customer reserve 8'
     	  WHEN '9' THEN '9-Customer reserve 9'
		  WHEN 'S' THEN 'S-Ship & Debit (IBU HiTec)' END AS ZF_TVCPF_KNPRS_DESC,
		--Add description code for TVCPF_FKMGK
	   CASE TVCPF_FKMGK	    
	        WHEN    'A'	THEN 'A-Order quantity less invoiced quantity'
			WHEN	'B'	THEN	'B-Delivery quantity less invoiced quantity'
			WHEN	'C'	THEN	'C-Order quantity'
			WHEN	'D'	THEN	'D-Delivery quantity'
			WHEN	'E'	THEN	'E-Goods receipt quantity less invoiced quantity'
			WHEN	'F'	THEN	'F-Invoice receipt quantity less invoiced quantity'
			WHEN	'G'	THEN	'G-Cumulative batch quantity minus invoiced quantity'
			WHEN	'H'	THEN	'H-Cumul.batch quantity'
			WHEN	'I'	THEN	'I-Purchase quantity minus quantity already billed,' END AS ZF_TVCPF_FKMGK_DESC,
	   --Add description code for TVCPF_POSVO
	   IIF(LEN(TRIM(TVCPF_POSVO)) = 0,'No','Yes') AS ZF_TVCPF_POSVO_DESC,
	   --Add description code for TVCPF_HINEU
	   IIF(LEN(TRIM(TVCPF_HINEU)) = 0,'No','Yes') AS ZF_TVCPF_HINEU_DESC,
	   --Add description code for TVCPF_PFKUR
	   CASE TVCPF_PFKUR
	       WHEN	'A'	THEN	'A-Copy from sales order'
			WHEN	'B'	THEN	'B-Price exchange rate = Accouting rate'
			WHEN	'C'	THEN	'C-Exchange rate determination according to billing date'
			WHEN	'D'	THEN	'D-Exchange rate determination according to pricing date'
			WHEN	'E'	THEN	'E-Exchange rate determination according to current date'
			WHEN	'F'	THEN	'F-Exch.rate determination accord.to date of services rendered'
			WHEN	'NULL'	THEN	'Null' END AS ZF_TVCPF_PFKUR_DESC,
	   --Add description code for TVCPF_ORDNR_FI
	   CASE TVCPF_ORDNR_FI
	       WHEN 'A'	THEN 'A-Order quantity less invoiced quantity'
           WHEN 'B'	THEN 'B-Delivery quantity less invoiced quantity'
		   WHEN 'C'	THEN 'C-Order quantity'
           WHEN 'D' THEN 'D-Delivery quantity'
		   WHEN 'E'	THEN 'E-Goods receipt quantity less invoiced quantity'
		   WHEN 'F' THEN 'F-Invoice receipt quantity less invoiced quantity'
		   WHEN 'G'	THEN 'G-Cumulative batch quantity minus invoiced quantity'
		   WHEN 'H' THEN 'H-Cumul.batch quantity'
		   WHEN 'I'	THEN 'I-Purchase quantity minus quantity already billed' END AS ZF_TVCPF_ORDNR_FI_DESC,
	    --Add description code for TVCPF_PRSQU
		CASE TVCPF_PRSQU
		   WHEN 'NULL' THEN	'Order'
		   WHEN 'A'	THEN 'A-Purchase order'
		   WHEN 'B'	THEN 'B-Purchase order/delivery'
		   WHEN 'C'	THEN 'C-Not used'
		   WHEN 'D'	THEN 'D-Delivery'
		   WHEN 'E' THEN 'E-Delivery/order'
		   WHEN 'F'	THEN 'F-Shipment costs'
		   WHEN 'G'	THEN 'G-External' END AS ZF_TVCPF_PRSQU_DESC,
		 --Add description code for TVFK_TXTLF
		 IIF(LEN(TRIM(TVFK_TXTLF)) = 0, 'No','Yes') AS ZF_TVFK_TXTLF_DESC,
		 --Add description code for TVFK_J_1ACPDEL
		 IIF(LEN(TRIM(TVFK_J_1ACPDEL)) = 0, 'No','Yes') AS ZF_TVFK_J_1ACPDEL_DESC
INTO BC31_01_IT_TVCPF_TVFK_TVFKT_TVAP_TVAPT_TVLK_TVLKT_TVAKT_TVAK
FROM A_TVCPF
--Add billing document types copy texts 
LEFT JOIN A_TVFK
ON TVFK_FKART = TVCPF_FKARN
--Add billing document types texts
LEFT JOIN A_TVFKT AS A
ON A.TVFKT_FKART = TVCPF_FKARN
--Add billing document types texts (reference billing document type) 
LEFT JOIN A_TVFKT AS B
ON B.TVFKT_FKART = TVCPF_FKARV
--Add sales document item categories 
LEFT JOIN A_TVAP
ON TVAP_PSTYV = TVCPF_PSTYV
--Add sales document item categories texts 
LEFT JOIN A_TVAPT
ON TVAPT_PSTYV = TVCPF_PSTYV
--Add delivery document types 
LEFT JOIN A_TVLK
ON TVLK_LFART = TVCPF_LFARV 
--Add delivery document types descriptions
LEFT JOIN A_TVLKT
ON TVLKT_LFART = TVCPF_FKARV
--Add sale order document types
LEFT JOIN A_TVAKT
ON TVAKT_AUART=TVCPF_AUARV
--Add sale order document types descriptions 
LEFT JOIN A_TVAK
ON TVAK_AUART=TVCPF_AUARV



GO
