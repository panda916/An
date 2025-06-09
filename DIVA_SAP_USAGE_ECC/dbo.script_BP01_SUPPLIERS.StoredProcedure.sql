USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE        PROCEDURE [dbo].[script_BP01_SUPPLIERS]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START
BEGIN

/*Change history comments*/

/*
	Title			:	BP01: Supplier
	  
	--------------------------------------------------------------
	Update history
	--------------------------------------------------------------
	Date		    | Who  |	Description
	06/10/2022        KHOA      First version for Sony ECC
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
					 ,@ZV_SAME_QUARTER_BY_BLDAT NVARCHAR(MAX) = ISNULL((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'ZV_SAME_QUARTER_BY_BLDAT'), '')
 
--Step 1/ Create cube for supplier
EXEC SP_DROPTABLE 'BP01_01_IT_SUPP'

SELECT DISTINCT
    A_T001.T001_WAERS AS ZF_T001_LFA1_WAERS,
	A_LFA1.LFA1_MANDT,	
	A_LFA1.LFA1_LIFNR,
	AM_SCOPE.SCOPE_BUSINESS_DMN_L1,
	AM_SCOPE.SCOPE_BUSINESS_DMN_L2,
	A_LFB1.LFB1_BUKRS,
	A_T001.T001_BUTXT, 						
	A_LFB1.LFB1_LIFNR, 						
	A_LFA1.LFA1_NAME1, 						
	A_LFA1.LFA1_LAND1, 						
	A_LFA1.LFA1_SORTL, 						
	A_LFA1.LFA1_KTOKK, 	
	A_LFA1.LFA1_XCPDK,
	A_T077Y.T077Y_TXT30,						
	A_LFB1.LFB1_AKONT, 						
	A_LFA1.LFA1_ERDAT, 	
	-- Add the year month for the supplier creation date
	CAST(RTRIM(YEAR(A_LFA1.LFA1_ERDAT)) AS VARCHAR(4)) + '-' + RIGHT('0' + RTRIM(MONTH(A_LFA1.LFA1_ERDAT)), 2) AS ZF_LFA1_ERDAT_YEAR_MONTH,	
	A_LFA1.LFA1_ERNAM, 						
	A_LFB1.LFB1_ZWELS, 						
	A_LFB1.LFB1_ZTERM,
	A_LFB1.LFB1_LOEVM,
	A_LFA1.LFA1_LOEVM,
	LFB1_TOGRU,
	LFB1_REPRF,
--Add information for sale organization
	A_LFM1.LFM1_EKORG,
	A_LFM1.LFM1_LEBRE,
	A_LFM1.LFM1_WEBRE,
	A_LFA1.LFA1_ORT01,
--Add a flag for checking supplier have no sale GR-Based Invoice Verification and Service-Based Invoice Verification	
	IIF(LFM1_LEBRE ='' AND LFM1_WEBRE='','X','') AS ZF_LFM1_LEBRE_WEBRE,
--Khoi:Add the 	Indicator: Account group for one-time accounts?
	T077K_XCPDS,
	CASE 
		WHEN T077K_XCPDS='X' THEN 'One time account group'
		WHEN T077K_XCPDS='' THEN 'Normal acccount group'
		WHEN T077K_XCPDS IS NULL THEN 'Account group not found in account group master data' 
		END AS ZF_T077K_XCPDS_DESC,
		T024E_EKOTX

INTO BP01_01_IT_SUPP
FROM A_LFA1
-- Include company code level supplier master data
LEFT JOIN A_LFB1
	ON A_LFA1.LFA1_LIFNR = A_LFB1.LFB1_LIFNR  
-- Company code information
LEFT JOIN A_T001 
	ON A_LFB1.LFB1_BUKRS = A_T001.T001_BUKRS
-- Add supplier account group text
LEFT JOIN A_T077Y 
	ON A_LFA1.LFA1_KTOKK = A_T077Y.T077Y_KTOKK
--KHOI-Add the information about purchasing organization
LEFT JOIN A_LFM1
	ON A_LFA1.LFA1_LIFNR=A_LFM1.LFM1_LIFNR
--
LEFT JOIN A_T077K
	ON T077K_KTOKK=LFA1_KTOKK

   -- Add information from the scope table concerning the business domain   
--Add purchase organization description
LEFT JOIN A_T024E ON LFM1_EKORG=T024E_EKORG

INNER JOIN AM_SCOPE                                         
ON   LFB1_BUKRS = AM_SCOPE.SCOPE_CMPNY_CODE
--/*Drop temporary tables*/
EXEC SP_RENAME_FIELD 'BP01_01_', 'BP01_01_IT_SUPP'

END

GO
