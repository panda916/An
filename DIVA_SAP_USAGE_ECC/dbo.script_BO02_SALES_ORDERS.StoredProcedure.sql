USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE          PROCEDURE [dbo].[script_BO02_SALES_ORDERS]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START
/* Initiate the log */  
--Create database log table if it does not exist
IF OBJECT_ID('LOG_SP_EXECUTION', 'U') IS NULL BEGIN CREATE TABLE [DBO].[LOG_SP_EXECUTION] ([DATABASE] NVARCHAR(MAX) NULL,[OBJECT] NVARCHAR(MAX) NULL,[OBJECT_TYPE] NVARCHAR(MAX) NULL,[USER] NVARCHAR(MAX) NULL,[DATE] DATE NULL,[TIME] TIME NULL,[DESCRIPTION] NVARCHAR(MAX) NULL,[TABLE] NVARCHAR(MAX),[ROWS] INT) END

--Log start of procedure
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Procedure started',NULL,NULL

/* Initialize parameters from globals table */

     DECLARE 	 
			 @CURRENCY NVARCHAR(MAX)			= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'currency')
			,@DATE1 NVARCHAR(MAX)				= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date1')
			,@DATE2 NVARCHAR(MAX)				= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date2')
			,@DOWNLOADDATE NVARCHAR(MAX)		= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'downloaddate')
			,@DATEFORMAT VARCHAR(3)             = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'dateformat')
			,@EXCHANGERATETYPE NVARCHAR(MAX)	= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'exchangeratetype')
			,@LANGUAGE1 NVARCHAR(MAX)			= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language1')
			,@LANGUAGE2 NVARCHAR(MAX)			= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language2')
			,@YEAR NVARCHAR(MAX)				= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'year')
			,@ID NVARCHAR(MAX)					= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'id')
			,@LIMIT_RECORDS INT		            = CAST((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS') AS INT)


/*Test mode*/

SET ROWCOUNT @LIMIT_RECORDS


/*Change history comments*/

/*Change history comments*/

/*
	Title			:	BO02: SALE ORDERS
	  
	--------------------------------------------------------------
	Update history
	--------------------------------------------------------------
	Date		    | Who |	Description
	12/10/2022        KHOA   First version
*/


-- Step 1: create sale orders cube
EXEC SP_DROPTABLE 'BO02_01_IT_SOS'

	SELECT
		A_VBAK.VBAK_MANDT,
		A_VBAK.VBAK_AUART,
		VBAP_PSTYV,
		AM_SCOPE.SCOPE_BUSINESS_DMN_L1,
		AM_SCOPE.SCOPE_BUSINESS_DMN_L2,
		A_VBAK.VBAK_BUKRS_VF,
		A_VBAK.VBAK_KUNNR,
		A_VBAK.VBAK_VBTYP,
		A_VBAK.VBAK_VBKLT,
		A_VBAK.VBAK_VBELN,
		A_VBAP.VBAP_POSNR,
		A_VBAP.VBAP_ZMENG,
		A_VBAK.VBAK_AEDAT,
		A_VBAP.VBAP_WERKS,
		A_VBAP.VBAP_VGBEL,
		A_VBAP.VBAP_VGPOS,
		A_T001W.T001W_NAME1,
		A_VBAK.VBAK_VKORG,
		A_VBAK.VBAK_VKGRP,
		A_VBAK.VBAK_AUDAT,
		A_VBAP.VBAP_VBELN,
		A_VBAK.VBAK_ERNAM,
		A_V_USERNAME.V_USERNAME_NAME_TEXT,
		T001_BUTXT,
		KNA1_NAME1,
		A_TVAPT.TVAPT_VTEXT,
		A_VBAK.VBAK_WAERK, -- document currency		
		CASE 
			WHEN VBAK_VBTYP='A'	THEN 'Inquiry'
			WHEN VBAK_VBTYP='B' THEN 'Quotation'
			WHEN VBAK_VBTYP='C'	THEN 'Order'
			WHEN VBAK_VBTYP='D'	THEN 'Item proposal'
			WHEN VBAK_VBTYP='E'	THEN 'Scheduling agreement'
			WHEN VBAK_VBTYP='F'	THEN 'Scheduling agreement with external service agent'
			WHEN VBAK_VBTYP='G' THEN 'Contract'
			WHEN VBAK_VBTYP='H'	THEN 'Returns'
			WHEN VBAK_VBTYP='I'	THEN 'Order w/o charge'
			WHEN VBAK_VBTYP='J'	THEN 'Delivery'
			WHEN VBAK_VBTYP='K'	THEN 'Credit memo request'
			WHEN VBAK_VBTYP='L'	THEN 'Debit memo request'
			WHEN VBAK_VBTYP='M'	THEN 'Invoice'
			WHEN VBAK_VBTYP='N'	THEN 'Invoice cancellation'
			WHEN VBAK_VBTYP='O'	THEN 'Credit memo'
			WHEN VBAK_VBTYP='P'	THEN 'Debit memo'
			WHEN VBAK_VBTYP='Q'	THEN 'WMS transfer order'
			WHEN VBAK_VBTYP='R'	THEN 'Goods movement'
			WHEN VBAK_VBTYP='S'	THEN 'Credit memo cancellation'
			WHEN VBAK_VBTYP='T'	THEN 'Returns delivery for order'
			WHEN VBAK_VBTYP='U'	THEN 'Pro forma invoice'
			WHEN VBAK_VBTYP='V'	THEN 'Purchase Order'
			WHEN VBAK_VBTYP='W'	THEN 'Independent reqts plan'
			WHEN VBAK_VBTYP='X'	THEN 'Handling unit'
			WHEN VBAK_VBTYP='0'	THEN 'Master contract'
			WHEN VBAK_VBTYP='1'	THEN 'Sales activities (CAS)'
			WHEN VBAK_VBTYP='2'	THEN 'External transaction'
			WHEN VBAK_VBTYP='3'	THEN 'Invoice list'
			WHEN VBAK_VBTYP='4'	THEN 'Credit memo list'
			WHEN VBAK_VBTYP='5'	THEN 'Intercompany invoice'
			WHEN VBAK_VBTYP='6'	THEN 'Intercompany credit memo'
			WHEN VBAK_VBTYP='7'	THEN 'Delivery/shipping notification'
			WHEN VBAK_VBTYP='8'	THEN 'Shipment'
			WHEN VBAK_VBTYP='a'	THEN 'Shipment costs'
			WHEN VBAK_VBTYP='b'	THEN 'CRM Opportunity'
			WHEN VBAK_VBTYP='c'	THEN 'Unverified delivery'
			WHEN VBAK_VBTYP='d' THEN 'Trading Contract'
			WHEN VBAK_VBTYP='e'	THEN 'Allocation table'
			WHEN VBAK_VBTYP='f'	THEN 'Additional Billing Documents'
			WHEN VBAK_VBTYP='g'	THEN 'Rough Goods Receipt (only IS-Retail)'
			WHEN VBAK_VBTYP='h'	THEN 'Cancel Goods Issue'
			WHEN VBAK_VBTYP='i'	THEN 'Goods receipt'
			WHEN VBAK_VBTYP='j'	THEN 'JIT call'
			WHEN VBAK_VBTYP='n'	THEN 'Reserved'
			WHEN VBAK_VBTYP='o'	THEN 'Reserved'
			WHEN VBAK_VBTYP='p'	THEN 'Goods Movement (Documentation)'
			WHEN VBAK_VBTYP='q'	THEN 'Reserved'
			WHEN VBAK_VBTYP='r'	THEN 'TD Transport (only IS-Oil)'
			WHEN VBAK_VBTYP='s'	THEN 'Load Confirmation, Reposting (Only IS-Oil)'
			WHEN VBAK_VBTYP='t'	THEN 'Gain / Loss (Only IS-Oil)'
			WHEN VBAK_VBTYP='u'	THEN 'Reentry into Storage (Only IS-Oil)'
			WHEN VBAK_VBTYP='v'	THEN 'Data Collation (only IS-Oil)'
			WHEN VBAK_VBTYP='w'	THEN 'Reservation (Only IS-Oil)'
			WHEN VBAK_VBTYP='x'	THEN 'Load Confirmation, Goods Receipt (Only IS-Oil)'
			WHEN VBAK_VBTYP='$'	THEN '(AFS)'
			WHEN VBAK_VBTYP='+'	THEN 'Accounting Document (Temporary)'
			WHEN VBAK_VBTYP='-'	THEN 'Accounting Document (Temporary)'
			WHEN VBAK_VBTYP='#'	THEN 'Revenue Recognition (Temporary)'
			WHEN VBAK_VBTYP='~'	THEN 'Revenue Cancellation (Temporary)'
			WHEN VBAK_VBTYP='?'	THEN 'Revenue Recognition/New View (Temporary)'
			WHEN VBAK_VBTYP IS NULL	THEN 'Revenue Cancellation/New View (Temporary)'
			WHEN VBAK_VBTYP=':'	THEN 'Service Order'
			WHEN VBAK_VBTYP='.'	THEN 'Service Notification'
			WHEN VBAK_VBTYP='&'	THEN 'Warehouse Document'
			WHEN VBAK_VBTYP='*'	THEN 'Pick Order'
			WHEN VBAK_VBTYP=','	THEN 'Shipment Document'
			WHEN VBAK_VBTYP='^'	THEN 'Reserved'
			WHEN VBAK_VBTYP='|'	THEN 'Reserved'
			WHEN VBAK_VBTYP='k'	THEN 'Agency Document' END AS ZF_VBAK_VBTYP_DESC,
		CONVERT(MONEY,VBAP_NETWR * ISNULL(TCURX_DOC.TCURX_FACTOR,1)) AS ZF_VBAP_NETWR_S, --document amount
		CONVERT(MONEY,VBAP_NETWR *
		COALESCE(CAST(TCURR_COC.TCURR_UKURS AS FLOAT),1) * 
		COALESCE(TCURF_COC.TCURF_TFACT,1) / COALESCE(TCURF_COC.TCURF_FFACT,1) *
		COALESCE(CAST(TCURR_CUC.TCURR_UKURS AS FLOAT),1) * 
		COALESCE(TCURF_CUC.TCURF_TFACT,1) / COALESCE(TCURF_CUC.TCURF_FFACT,1) *
		ISNULL(TCURX_DOC.TCURX_FACTOR,1)
		) AS ZF_VBAP_NETWR_S_CUC, -- document mount to USD
		A_TVPT.TVPT_Description,
		A_TVAKT.TVAKT_BEZEI
	INTO BO02_01_IT_SOS
    
	FROM A_VBAK

	-- Select from PO header/line items
	INNER JOIN A_VBAP
	ON  A_VBAK.VBAK_VBELN = A_VBAP.VBAP_VBELN
	--Add the company code description
	LEFT JOIN A_T001 ON VBAK_BUKRS_VF=T001_BUKRS
	-- Add user account names
	LEFT JOIN A_V_USERNAME 
		ON  A_VBAK.VBAK_ERNAM = A_V_USERNAME.V_USERNAME_BNAME
	-- Add descriptions of plant codes
	LEFT JOIN A_T001W
		ON A_VBAP.VBAP_WERKS = A_T001W.T001W_WERKS  
	-- Add currency factor from doc currency to local currency
    LEFT JOIN B00_IT_TCURF TCURF_COC
        ON A_VBAK.VBAK_WAERK = TCURF_COC.TCURF_FCURR
        AND TCURF_COC.TCURF_TCURR  = A_T001.T001_WAERS 
        AND TCURF_COC.TCURF_GDATU = (
            SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
            FROM B00_IT_TCURF
            WHERE A_VBAK.VBAK_WAERK = B00_IT_TCURF.TCURF_FCURR AND 
                    B00_IT_TCURF.TCURF_TCURR  = A_T001.T001_WAERS AND
                    B00_IT_TCURF.TCURF_GDATU <= A_VBAP.VBAP_ERDAT
            ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
            )
	
	-- Add exchange rate from doc currency to local currency
    LEFT JOIN B00_IT_TCURR TCURR_COC
        ON A_VBAK.VBAK_WAERK = TCURR_COC.TCURR_FCURR
        AND TCURR_COC.TCURR_TCURR  = A_T001.T001_WAERS  
        AND TCURR_COC.TCURR_GDATU = (
            SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
            FROM B00_IT_TCURR
            WHERE A_VBAK.VBAK_WAERK = B00_IT_TCURR.TCURR_FCURR AND 
                    B00_IT_TCURR.TCURR_TCURR  = A_T001.T001_WAERS  AND
                    B00_IT_TCURR.TCURR_GDATU <= A_VBAP.VBAP_ERDAT
            ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
            ) 

	-- Add the currency conversion factor: for document currency
	LEFT JOIN B00_TCURX TCURX_DOC
		ON 
		 A_VBAK.VBAK_WAERK = TCURX_DOC.TCURX_CURRKEY
	-- Add currency factor from local currency to USD
	LEFT JOIN B00_IT_TCURF TCURF_CUC
			ON A_T001.T001_WAERS = TCURF_CUC.TCURF_FCURR
			AND TCURF_CUC.TCURF_TCURR  = @currency
			AND TCURF_CUC.TCURF_GDATU = (
				SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
				FROM B00_IT_TCURF
				WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
						B00_IT_TCURF.TCURF_TCURR  = @currency AND
						B00_IT_TCURF.TCURF_GDATU <= A_VBAP.VBAP_ERDAT
				ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
				)
    
    -- Add exchange rate from local currency to USD
    LEFT JOIN B00_IT_TCURR TCURR_CUC
        ON A_T001.T001_WAERS = TCURR_CUC.TCURR_FCURR
        AND TCURR_CUC.TCURR_TCURR  = @currency 
        AND TCURR_CUC.TCURR_GDATU = (
            SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
            FROM B00_IT_TCURR
            WHERE A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
                    B00_IT_TCURR.TCURR_TCURR  = @currency AND
                    B00_IT_TCURR.TCURR_GDATU <= A_VBAP.VBAP_ERDAT
            ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
            ) 
   -- Add information from the scope table concerning the business domain   
	INNER JOIN AM_SCOPE                                         
		ON   VBAK_BUKRS_VF = AM_SCOPE.SCOPE_CMPNY_CODE
	--Add customer name
			LEFT JOIN A_KNA1 ON VBAK_KUNNR=KNA1_KUNNR
	--Add category description
	LEFT JOIN A_TVAPT
	ON TVAPT_PSTYV=VBAP_PSTYV AND TVAPT_SPRAS='EN'
	LEFT JOIN A_TVPT
	ON VBAP_PSTYV = A_TVPT.TVPT_PSTYV
	LEFT JOIN A_TVAKT
	ON VBAK_AUART = TVAKT_AUART
	WHERE TVAKT_SPRAS IN ('E','EN')
EXEC SP_RENAME_FIELD 'BO02_01_', 'BO02_01_IT_SOS'
	
GO
