USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC  [dbo].[script_B00_TCURR_TCURF]
WITH EXECUTE AS CALLER
AS

--DYNAMIC_SCRIPT_START
/*Change history comments*/

/*
	Title			:	B00: TCURR_TCURF
	  
	--------------------------------------------------------------
	Update history
	--------------------------------------------------------------
	Date		    | Who |	Description
	19/10/2022        KHOA   First version
*/


/* Initialize parameters from globals table */
 
     DECLARE  
                      @CURRENCY NVARCHAR(MAX)                 = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'currency')
                     ,@DATE1 NVARCHAR(MAX)                           = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date1')
                     ,@DATE2 NVARCHAR(MAX)                           = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date2')
                     ,@DOWNLOADDATE NVARCHAR(MAX)             = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'downloaddate')
                     ,@DATEFORMAT VARCHAR(3)             = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'dateformat')
                     ,@EXCHANGERATETYPE NVARCHAR(MAX)  = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'exchangeratetype')
                     ,@LANGUAGE1 NVARCHAR(MAX)                = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language1')
                     ,@LANGUAGE2 NVARCHAR(MAX)                = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language2')
                     ,@YEAR NVARCHAR(MAX)                     = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'year')
                     ,@ID NVARCHAR(MAX)                       = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'id')
                     ,@LIMIT_RECORDS INT                    = CAST((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS') AS INT)
					 ,@ZV_EXCHANGE_RATE_TYPE NVARCHAR(MAX) = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'exchangeratetype')
 
/*--Step 1
--  Unique list of exchange rate conversion factors:
	-- During the conversion from document currency to house currency, the following formula will be applied:
	     PO amount in document currency (EKPO_NETWR) * (PO exchange rate (EKKO_WKURS)* (exchange rate factor (TCURX_FACTOR)/Exchange rate conversion factor (TCURR_FFACT)))
-- Only the exchange rate conversion factors 'M' (average) and those that are effective (GDATU) are used
-- Only the exchange rates to (TCURR_TCURR) house currency (T001_WAERS) for company codes in scope are kept
-- $$ to be checked: why is the exchange rate table used for purchase orders but not for BSAK_WRBTR?
*/	
 
EXEC SP_DROPTABLE 'B00_IT_TCURF'
SELECT TCURF_FCURR,
        TCURF_TCURR,
        CONVERT(DATE,CAST(99999999-TCURF_GDATU AS NVARCHAR), 112) TCURF_GDATU,
        TCURF_FFACT,
        TCURF_TFACT,
		TCURF_KURST
INTO B00_IT_TCURF
FROM A_TCURF
WHERE TCURF_KURST = @ZV_EXCHANGE_RATE_TYPE AND TCURF_GDATU < 90000000 


EXEC SP_DROPTABLE 'B00_IT_TCURR'
SELECT TCURR_FCURR,
        TCURR_TCURR,
        CONVERT(DATE,CAST(99999999-TCURR_GDATU AS NVARCHAR), 112) TCURR_GDATU,
        TCURR_FFACT,
        TCURR_TFACT,
		TCURR_KURST,
		IIF(TCURR_UKURS > 0 , TCURR_UKURS, -(1/TCURR_UKURS)) AS TCURR_UKURS
INTO B00_IT_TCURR
FROM A_TCURR
WHERE TCURR_GDATU < 90000000 AND TCURR_KURST = @ZV_EXCHANGE_RATE_TYPE  
	ORDER BY TCURR_GDATU
GO
