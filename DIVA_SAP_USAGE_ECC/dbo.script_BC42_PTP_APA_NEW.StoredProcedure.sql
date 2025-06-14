USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_BC42_PTP_APA_NEW]
AS
/* Initialize parameters from globals table */
--DYNAMIC_SCRIPT_START
     DECLARE 	 
			 @CURRENCY NVARCHAR(MAX)			= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'currency')
			,@DATE1 NVARCHAR(MAX)				= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'date1')
			,@DATE2 NVARCHAR(MAX)				= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'date2')
			,@DOWNLOADDATE NVARCHAR(MAX)		= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'downloaddate')
			,@DATEFORMAT VARCHAR(3)             = (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'dateformat')
			,@EXCHANGERATETYPE NVARCHAR(MAX)	= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'exchangeratetype')
			,@LANGUAGE1 NVARCHAR(MAX)			= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'language1')
			,@LANGUAGE2 NVARCHAR(MAX)			= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'language2')
			,@YEAR NVARCHAR(MAX)				= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'year')
			,@ID NVARCHAR(MAX)					= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'id')
			,@LIMIT_RECORDS INT		            = CAST((SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS') AS INT)


/*Test mode*/

SET ROWCOUNT @LIMIT_RECORDS
EXEC SP_REMOVE_TABLES 'BC42_%'

/*Change history comments*/


  /*
  Title:	BC42_PTP_APA Accounts payable
  Description: Generates up to three cubes:
		- APA - Accounts Payable line items
		- APA-new - Accounts Payable line items incorporating new GL data. Dependent on APA and GLA-new
		- APA-lines - Counter GL line items for accounts payable (e.g. for and invoice that Cr Accounts Payable, this cube will give the corresponding debit line items)

    --------------------------------------------------------------
    Update history
    --------------------------------------------------------------
    Date		    | Who |	Description

	13-04-2016		  MW	First version for Sony  
	18-04-2016		  EH	Added back in ZF_Bucket - AP as this is required for overview routine
	04-05-2016		  EH    Added index on BSAK and added code to remove and then re-add BKPF PK index as this was clashing with BSIK_BSAK_BKPF and impacting performance
	11-05-2016		  MW	Added company code to AM_FSMC join. Added cost center name.
	06-02-2017		  JSM	Added database log table for the stored procedure and commented all the index query.
	19-03-2017		  CW    Update and standardisation for SID
	19-03-2017		  CW    Remove manual parameters to enable running from ETL 13
	28-07-2017        NP    Naming convention
	28-07-2017        Anh   Integration of information necessary for audit tests
	15-10-2020        Hau   Comment out T074T because SPNI don't have that table
  */

 
--Step 1/ Create a table from the cube B11_04_IT_PTP_APA

EXEC SP_DROPTABLE 'BC42_04_IT_PTP_APA'

SELECT
*
INTO BC42_04_IT_PTP_APA
FROM B11_04_IT_PTP_APA

--Step 2/ Create a table from the cube B11_05_IT_PTP_INVS_AND_CANCS

EXEC SP_DROPTABLE 'BC42_05_IT_PTP_INVS_AND_CANCS'

SELECT
*
INTO BC42_05_IT_PTP_INVS_AND_CANCS
FROM B11_05_IT_PTP_INVS_AND_CANCS

--Step 3/ Create a table from the cube B11_06_IT_PTP_INV


EXEC SP_DROPTABLE 'BC42_06_IT_PTP_INV'

SELECT
*
INTO BC42_06_IT_PTP_INV
FROM B11_06_IT_PTP_INV


--Step 4/ Create a table from the cube B11_07_IT_PTP_INV_CANC

EXEC SP_DROPTABLE 'BC42_07_IT_PTP_INV_CANC'

SELECT
*
INTO BC42_07_IT_PTP_INV_CANC
FROM B11_07_IT_PTP_INV_CANC

--Step 5/ Create a table from the cube B11_07_IT_PTP_INV_CANC

EXEC SP_DROPTABLE 'BC42_14_IT_AP_AGEING'

SELECT
*
INTO BC42_14_IT_AP_AGEING
FROM B11_14_IT_AP_AGEING

--Step 6/ Create a table from the cube B11_07_IT_PTP_INV_CANC

EXEC SP_DROPTABLE 'BC42_15_IT_INV_PAY'

SELECT
*
INTO BC42_15_IT_INV_PAY
FROM B11_15_IT_INV_PAY


/*Rename fields for Qlik*/


EXEC sp_UNNAME_FIELD 'B11_', 'BC42_05_IT_PTP_INVS_AND_CANCS'
EXEC sp_RENAME_FIELD 'BC42_', 'BC42_05_IT_PTP_INVS_AND_CANCS'

/*Remove temporary tables*/

--EXEC sp_droptable 'BC42_01_TT_RSEG'
--EXEC SP_DROPTABLE 'BC42_02_TT_JE_MULTIPLE_SUPP'
--EXEC SP_DROPTABLE 'BC42_03_TT_PTP_APA'

/* log cube creation*/

INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','BC42_05_IT_PTP_INVS_AND_CANCS',(SELECT COUNT(*) FROM BC42_05_IT_PTP_INVS_AND_CANCS) 
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','BC42_04_IT_PTP_APA',(SELECT COUNT(*) FROM BC42_04_IT_PTP_APA) 
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','BC42_06_IT_PTP_INV',(SELECT COUNT(*) FROM BC42_06_IT_PTP_INV) 
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','BC42_07_IT_PTP_INV_CANC',(SELECT COUNT(*) FROM BC42_07_IT_PTP_INV_CANC) 
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','BC42_08_IT_PTP_PAY',(SELECT COUNT(*) FROM BC42_08_IT_PTP_PAY) 
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','BC42_09_IT_PTP_PAY_CANC',(SELECT COUNT(*) FROM BC42_09_IT_PTP_PAY_CANC) 


/* log end of procedure*/

--EXEC SP_DROPTABLE 'BC42_04_IT_PTP_APA'
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL
GO
