USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_BC41_FIN_AP_AUTOMAPPING_NEW]
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
       @CURRENCY NVARCHAR(MAX)      = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'currency')
      ,@DATE1 NVARCHAR(MAX)       = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date1')
      ,@DATE2 NVARCHAR(MAX)       = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date2')
      ,@DOWNLOADDATE NVARCHAR(MAX)    = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'downloaddate')
      ,@DATEFORMAT VARCHAR(3)             = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'dateformat')
      ,@EXCHANGERATETYPE NVARCHAR(MAX)  = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'exchangeratetype')
      ,@LANGUAGE1 NVARCHAR(MAX)     = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language1')
      ,@LANGUAGE2 NVARCHAR(MAX)     = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language2')
      ,@YEAR NVARCHAR(MAX)        = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'year')
      ,@ID NVARCHAR(MAX)          = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'id')
      ,@LIMIT_RECORDS INT               = CAST((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS') AS INT)
      ,@ZV_LFA1_KTOKK_PERS INT                = CAST((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'ZV_LFA1_KTOKK_PERS') AS INT)


  /*Change history comments*/

  /*
    Title     : [BC41B_FIN_AP_DOC_TYPES_FILL_BUCKET]
    Description     : Table updated by this script: BC41_02_RT_FIN_AP_INV_PAY_FLAGS
              - DV06 should be reloaded after running this script
              Table produced by this script: BC41_02_IT
              Table is used to create the P2P cube
    
    --------------------------------------------------------------
    Update history
    --------------------------------------------------------------
    Date          | Who     | Description
    DD-MM-YYYY        Initials    Initial version
    27-11-2020        Vinh Le     Create first version of AP mapping automatically
  */


	  /*Test mode*/

	  SET ROWCOUNT @LIMIT_RECORDS

	  /*
	  Select the mapping table from the original cube, rename it to match with the old table in SAP USAGE. 
	  At the same time, try to unname the prefix of the fields from the original cube then rename. 
	  */

	EXEC SP_REMOVE_TABLES 'BC41_03_IT_FIN_AP_INV_PAY_FLAGS_NEW'
	SELECT 
	*
	INTO BC41_03_IT_FIN_AP_INV_PAY_FLAGS_NEW
	FROM B07_03_IT_FIN_AP_INV_PAY_FLAGS

	
	EXEC SP_UNNAME_FIELD 'B07B_', 'BC41_03_IT_FIN_AP_INV_PAY_FLAGS'
	EXEC SP_RENAME_FIELD 'BC41B_', 'BC41_03_IT_FIN_AP_INV_PAY_FLAGS'
	EXEC SP_REMOVE_TABLES '%_TT_%'

GO
