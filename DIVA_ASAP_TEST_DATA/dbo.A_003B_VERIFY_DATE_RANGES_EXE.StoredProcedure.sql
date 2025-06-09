USE [DIVA_ASAP_TEST_DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--ALTER PROCEDURE [dbo].[A_003B_VERIFY_DATE_RANGES]
CREATE PROCEDURE [dbo].[A_003B_VERIFY_DATE_RANGES_EXE]
  WITH EXECUTE AS CALLER
  AS
  BEGIN


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
  Title					:	Check tables that are scoped on Year or Date


-- $$All tables containing dates should be added here
-- $$Actual date fields should be used rather than year where possible
-- $$A version of this script should be created to create the list of months - because it might be 
-- that a file inbetween the upper and lower dates is omitted.
-- 
								
  --------------------------------------------------------------
  Update history
  --------------------------------------------------------------
  Date			| Who		|	Description
  17-05-2016	  MW			First version for Sony
  12-09-2017	  CW			Naming convention and removal of some tables that are obsolete


  */






-- Step 1/ Create a table that will hold the date ranges

EXEC SP_DROPTABLE 'A003B_01_RT_DATE_RANGE'

CREATE TABLE A003B_01_RT_DATE_RANGE(
	SCRIPT VARCHAR(50) NULL,
	TABLE_NAME VARCHAR(50) NULL,
	GROUP_TYPE VARCHAR(50) NULL,
	YEAR_LOWER_LIMIT VARCHAR(MAX) NULL,
	YEAR_UPPER_LIMIT VARCHAR(MAX) NULL,
	DATE_LOWER_LIMIT VARCHAR(MAX) NULL,
	DATE_UPPER_LIMIT VARCHAR(MAX) NULL
) ON [PRIMARY]

-- Step 2/ Insert into the date range table the upper and lower dates from change log table

IF EXISTS(SELECT * FROM SYSOBJECTS WHERE XTYPE = 'U' AND NAME='A_CDHDR')
INSERT INTO A003B_01_RT_DATE_RANGE
SELECT
	'Changes'           AS SCRIPT,		
	'CDHDR'             AS TABLE_NAME,    
	'CD'		        AS GROUP_TYPE,
	''			        AS YEAR_LOWER_LIMIT,
	''			        AS YEAR_UPPER_LIMIT, 
	MIN(CDHDR_UDATE)	AS DATE_LOWER_LIMIT,
	MAX(CDHDR_UDATE)	AS DATE_UPPER_LIMIT

FROM A_CDHDR

-- Step 3/ Insert into the date range table the upper and lower dates from ANLC table
-- $$ Commented out because table does not exist

/*
IF EXISTS(SELECT * FROM sysobjects WHERE xtype = 'u' AND name='ANLC')
insert into #xxTemp
Select
	'Finance'		AS [Script],
	'ANLC'			AS [Table Name],
	'A_MD'			AS [Group],
	Min(ANLC_GJAHR)	AS [Year (lower limit)],
	Max(ANLC_GJAHR)	AS [Year (upper limit)],
	''			AS [Date (lower limit)],
	''		AS [Date (upper limit)]
From A_ANLC
*/

-- Step 4/ Insert into the date range table the upper and lower dates from BKPF table

IF EXISTS(SELECT * FROM SYSOBJECTS WHERE XTYPE = 'U' AND NAME='A_BKPF')
INSERT INTO A003B_01_RT_DATE_RANGE
SELECT
	'Finance'           AS SCRIPT,		
	'BKPF'              AS TABLE_NAME,    
	'FI'		        AS GROUP_TYPE,
	MIN(BKPF_GJAHR)   AS YEAR_LOWER_LIMIT,
	MAX(BKPF_GJAHR)   AS YEAR_UPPER_LIMIT, 
	''					AS DATE_LOWER_LIMIT,
	''					AS DATE_UPPER_LIMIT

FROM A_BKPF

-- Step 5/ Insert into the date range table the upper and lower dates from BSAD table

/* Table not imported into the database

IF EXISTS(SELECT * FROM SYSOBJECTS WHERE XTYPE = 'U' AND NAME='A_BSAD')
INSERT INTO A003B_01_RT_DATE_RANGE
SELECT
	'Finance'           AS SCRIPT,		
	'BSAD'              AS TABLE_NAME,    
	'FI'		        AS GROUP_TYPE,
	''					AS YEAR_LOWER_LIMIT,
	''					AS YEAR_UPPER_LIMIT, 
	'MIN(BSAD_BUDAT)'	AS DATE_LOWER_LIMIT,
	'MAX(BSAD_BUDAT)'	AS DATE_UPPER_LIMIT

FROM A_BSAD

*/

-- Step 6/ Insert into the date range table the upper and lower dates from BSEC table

/* Table not imported into the database

IF EXISTS(SELECT * FROM SYSOBJECTS WHERE XTYPE = 'U' AND NAME='A_BSEC')
INSERT INTO A003B_01_RT_DATE_RANGE
SELECT
	'Finance'           AS SCRIPT,		
	'BSAD'              AS TABLE_NAME,    
	'FI'		        AS GROUP_TYPE,
	'MIN(BSEC_GJAHR)'	AS YEAR_LOWER_LIMIT,
	'MAX(BSEC_GJAHR)'	AS YEAR_UPPER_LIMIT, 
	''					AS DATE_LOWER_LIMIT,
	''					AS DATE_UPPER_LIMIT

FROM A_BSEC

*/

-- Step 7/ Insert into the date range table the upper and lower dates from BSEG table


IF EXISTS(SELECT * FROM SYSOBJECTS WHERE XTYPE = 'U' AND NAME='A_BSEG')
INSERT INTO A003B_01_RT_DATE_RANGE
SELECT
	'Finance'           AS SCRIPT,		
	'BSEG'              AS TABLE_NAME,    
	'FI'		        AS GROUP_TYPE,
	MIN(BSEG_GJAHR)		AS YEAR_LOWER_LIMIT,
	MAX(BSEG_GJAHR)		AS YEAR_UPPER_LIMIT, 
	''					AS DATE_LOWER_LIMIT,
	''					AS DATE_UPPER_LIMIT

FROM A_BSEG


-- Step 8/ Insert into the date range table the upper and lower dates from BSET table

/* Table not imported into the database

IF EXISTS(SELECT * FROM SYSOBJECTS WHERE XTYPE = 'U' AND NAME='A_BSET')
INSERT INTO A003B_01_RT_DATE_RANGE
SELECT
	'Tax'	            AS SCRIPT,		
	'BSET'              AS TABLE_NAME,    
	'FI'		        AS GROUP_TYPE,
	'MIN(BSET_GJAHR)'	AS YEAR_LOWER_LIMIT,
	'MAX(BSET_GJAHR)'	AS YEAR_UPPER_LIMIT, 
	''					AS DATE_LOWER_LIMIT,
	''					AS DATE_UPPER_LIMIT

FROM A_BSET

*/


-- Step 9/ Insert into the date range table the upper and lower dates from BSEC table

IF EXISTS(SELECT * FROM SYSOBJECTS WHERE XTYPE = 'U' AND NAME='A_FEBKO')
INSERT INTO A003B_01_RT_DATE_RANGE
SELECT
	'Finance'           AS SCRIPT,		
	'FEBKO'             AS TABLE_NAME,    
	'FI'		        AS GROUP_TYPE,
	''					AS YEAR_LOWER_LIMIT,
	''					AS YEAR_UPPER_LIMIT, 
	CAST(MIN(FEBKO_AZDAT) AS VARCHAR(14))	AS DATE_LOWER_LIMIT,
	CAST(MAX(FEBKO_AZDAT) AS VARCHAR(14))	AS DATE_UPPER_LIMIT

FROM A_FEBKO


-- Step 10/ Insert into the date range table the upper and lower dates from BSEC table

IF EXISTS(SELECT * FROM SYSOBJECTS WHERE XTYPE = 'U' AND NAME='A_FEBEP')
INSERT INTO A003B_01_RT_DATE_RANGE
SELECT
	'Finance'           AS SCRIPT,		
	'FEBEP'             AS TABLE_NAME,    
	'FI'		        AS GROUP_TYPE,
	MIN(FEBEP_GJAHR)	AS YEAR_LOWER_LIMIT,
	MAX(FEBEP_GJAHR)	AS YEAR_UPPER_LIMIT, 
	''					AS DATE_LOWER_LIMIT,
	''					AS DATE_UPPER_LIMIT

FROM A_FEBEP


/*Remove temporary tables*/

-- None

/* log cube creation*/

INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Cube completed','A003B_01_RT_DATE_RANGE', (SELECT COUNT(*) FROM A003B_01_RT_DATE_RANGE) 


/* log end of procedure*/


INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL






END










GO
