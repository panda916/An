USE [DIVA_TEST_PROGRESS]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--ALTER PROCEDURE [dbo].[A_005G_CREATE_EXCHANGE_RATES]
CREATE PROCEDURE [dbo].[A_005G_UPDATE_EXCHANGE_RATES]
WITH EXEC AS CALLER
AS
-- BEGIN


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

  /*
   
    
    --------------------------------------------------------------
    Update history
    --------------------------------------------------------------
    Date		  Who |	Description
    11-09-2017	  CW	Create exchange rates table
	
  */


-- Step 1/ This table was imported from the Oanda website.

-- The structure of the table is as shown below.

-- The AM_EXCHNG table is used to convert from company currency to custom currency
-- This table should have as many different FROM curerncies as there are company currencies in the data
-- imported.

-- Conversion from document currency to company currency is done using the formula: (not with the 
-- AM_EXCHNG table because this table may not contain all from currencies for document currencies)
-- Document currency * Exchange rate * TCURX_FACTOR (multiplication factor for exotic document currencies)/ TCURR_FFACT (exchange rate conversion factor for from currency units - related to house currency)

/*Definition of the exchange rates table, AM_EXCHNG

	  EXCHNG_FROM
      ,EXCHNG_TO]
      ,EXCHNG_CC_LENGTH
      ,EXCHNG_INV_RATIO
      ,EXCHNG_RATIO
      ,EXCHNG_FIN_DOC_NR
      ,EXCHNG_CMPNY_CODES_NR
      ,EXCHNG_FIN_DOC_NR_CC
      ,EXCHNG_PURCHS_DOC_NR
      ,EXCHNG_PURCHS_BILL_DOC_NR
      ,EXCHNG_SALES_DOC_NR
      ,EXCHNG_SALES_BILL_DOC_NR
   

 */


/* log cube creation*/

INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','AM_EXCHNG',(SELECT COUNT(*) FROM AM_EXCHNG) 


/* log end of procedure*/


INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL



-- END




GO
