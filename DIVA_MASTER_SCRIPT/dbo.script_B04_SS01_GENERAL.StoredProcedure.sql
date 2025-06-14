USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROCEDURE [dbo].[script_B04_SS01_GENERAL]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START

/* Initiate the log */  
--Create database log table if it does not exist
IF OBJECT_ID('_DatabaseLogTable', 'U') IS NULL BEGIN CREATE TABLE [dbo].[_DatabaseLogTable] ([Database] nvarchar(max) NULL,[Object] nvarchar(max) NULL,[Object Type] nvarchar(max) NULL,[User] nvarchar(max) NULL,[Date] date NULL,[Time] time NULL,[Description] nvarchar(max) NULL,[Table] nvarchar(max),[Rows] int) END

--Log start of procedure
INSERT INTO [dbo].[_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure started',NULL,NULL

/* Initialize parameters from globals table */

     DECLARE 	 
			 @currency nvarchar(max)			= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'currency')
			,@date1 nvarchar(max)				= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'date1')
			,@date2 nvarchar(max)				= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'date2')
			,@downloaddate nvarchar(max)		= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'downloaddate')
			,@exchangeratetype nvarchar(max)	= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'exchangeratetype')
			,@language1 nvarchar(max)			= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'language1')
			,@language2 nvarchar(max)			= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'language2')
			,@year nvarchar(max)				= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'year')
			,@id nvarchar(max)					= (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'id')
			,@ZV_LIMIT nvarchar(max)		    = (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'ZV_LIMIT')
			,@errormsg NVARCHAR(MAX)
			
DECLARE @dateformat varchar(3)
SET @dateformat   = (SELECT dbo.get_param('dateformat'))
SET DATEFORMAT @dateformat;

/* Create GL and Spend detail table */
EXEC SP_DROPTABLE 'B04_12_TT_SPEND_CATEGORY'
SELECT DISTINCT SPCAT_GL_ACCNT, 
	SPCAT_SCIS_DESCRIPTION,
	SPCAT_SPEND_CAT_LEVEL_1,
	SPCAT_SPEND_CAT_LEVEL_2,
	SPCAT_SPEND_CAT_LEVEL_3,
	SPCAT_SPEND_CAT_LEVEL_4,
	SPCAT_SPEND_TYPE
INTO B04_12_TT_SPEND_CATEGORY
FROM AM_SPEND_CATEGORY

CREATE INDEX SPCAT_GL_ACCNT ON B04_12_TT_SPEND_CATEGORY(SPCAT_GL_ACCNT)

EXEC SP_DROPTABLE 'B04_13_IT_GL_DETAIL'
SELECT DISTINCT TB_RCLNT GL_MANDT,
	TB_BUKRS GL_BUKRS,
	ISNULL(TB_RACCT, SPCAT_GL_ACCNT) GL_ACCT,
	SPCAT_SCIS_DESCRIPTION,
	SPCAT_SPEND_CAT_LEVEL_1,
	SPCAT_SPEND_CAT_LEVEL_2,
	SPCAT_SPEND_CAT_LEVEL_3,
	SPCAT_SPEND_CAT_LEVEL_4,
	SPCAT_SPEND_TYPE,
	SKAT_TXT50 AS SKAT_TXT50,
	TANGO_ACCT AS TANGO_ACCT,
	TANGO_ACCT_TXT AS TANGO_ACCT_TXT,
	B02_04_IT_FIN_COA.B02_ZF_GR_IR_ACCOUNT AS ZF_GR_IR_ACCOUNT,
	B02_04_IT_FIN_COA.B02_INTERCO_TXT,
	A_SKA1.SKA1_XBILK,               
	A_SKA1.SKA1_GVTYP,
	AM_GL_BANK_ACC.GL_BANK_TEXT1,
	B00_SKAT.SKAT_TXT20,
	GL_TXT,
	GL_L4,
	GL_L3,
	GL_L2,
	GL_L1,
	CASE 
		WHEN TANGO_ACCT IS NOT NULL AND [Tango AC] IS NOT NULL	THEN [Group]
		WHEN TANGO_ACCT IS NOT NULL AND [Tango AC] IS  NULL THEN 00
		ELSE NULL
	END AS ZF_TANGO_20F_GROUP,  
	CASE 
		WHEN TANGO_ACCT IS NOT NULL AND [Tango AC] IS NOT NULL	THEN Mapping
		WHEN TANGO_ACCT IS NOT NULL AND [Tango AC] IS  NULL THEN '00 Not mapped to 20F'
		ELSE NULL
	END AS ZF_TANGO_20F_MAPPING,
			CASE 
				WHEN TANGO_ACCT IS NOT NULL AND [Tango AC] IS NOT NULL	THEN [Tango Account Name (Japanese)]
				ELSE NULL
			END AS ZF_TANGO_ACCT_JAPAN, 
		  	CASE 
				WHEN TANGO_ACCT IS NOT NULL AND [Tango AC] IS NOT NULL	THEN [Tango Account Name (English)]
				ELSE NULL
			END AS ZF_TANGO_ACCT_ENGLISH,
	CAST('' AS nvarchar(MAX)) B04_ZF_TOTAL_BAL_FLAG,-- New flag for total balance is zero
	CAST('' AS NVARCHAR(MAX)) B04_ZF_DEBIT_CREDIT_FLAG-- new flag for debit credit blance is zero

INTO B04_13_IT_GL_DETAIL
FROM B00_TB
LEFT JOIN B04_12_TT_SPEND_CATEGORY B
ON B.SPCAT_GL_ACCNT = TB_RACCT
LEFT JOIN AM_TANGO
		ON RIGHT(CONCAT('0000000000',TB_RACCT), 10) = RIGHT(CONCAT('0000000000',TANGO_GL_ACCT), 10)
LEFT JOIN B02_04_IT_FIN_COA
		ON     TB_BUKRS = B02_04_IT_FIN_COA.B02_T001_BUKRS AND
		       TB_RACCT = B02_04_IT_FIN_COA.B02_SKB1_SAKNR
LEFT JOIN A_T001
		ON TB_BUKRS = T001_BUKRS
LEFT JOIN A_SKA1                                            
       ON A_SKA1.SKA1_KTOPL = T001_KTOPL AND               
        A_SKA1.SKA1_SAKNR = TB_RACCT
LEFT JOIN AM_GL_BANK_ACC                                       
       ON AM_GL_BANK_ACC.GL_BANK_ACC_HKONT = TB_RACCT AND
			AM_GL_BANK_ACC.GL_BANK_ACC_BUKRS = TB_BUKRS
LEFT JOIN B00_SKAT                                             
       ON B00_SKAT.SKAT_KTOPL = T001_KTOPL AND               
		  B00_SKAT.SKAT_SAKNR = TB_RACCT
LEFT JOIN AM_GL_HIERARCHY
	   ON RIGHT(CONCAT('0000000000',TB_RACCT), 10) = RIGHT(CONCAT('0000000000',GL_ACCT), 10)

-- Add some field in AM 20F account mapping. This is request from Jesper ( 27-11-2020)

LEFT JOIN DIVA_MASTER_SCRIPT..AM_20F_ACCOUNT
ON RIGHT(CONCAT('0000000000',B02_04_IT_FIN_COA.B02_TANGO_ACCT), 10) = RIGHT(CONCAT('0000000000',[Tango AC]), 10)

--Step 2 Update 2 flag 

-- Balance is 0
UPDATE B04_13_IT_GL_DETAIL
SET B04_ZF_TOTAL_BAL_FLAG='X'
WHERE GL_ACCT IN 
(
	SELECT B03_SKB1_SAKNR
		FROM B03_03_IT_FIN_TB
		GROUP BY B03_SKB1_SAKNR,B03_TB_RYEAR
		HAVING SUM(B03_TB_HSL_TOT_MOV)=0 AND SUM(B03_TB_KSL_TOT_MOV)=0
)

--Debit-credit not 0, balance is 0
UPDATE B04_13_IT_GL_DETAIL
SET B04_ZF_DEBIT_CREDIT_FLAG='Debit-credit not 0, balance is 0'
WHERE GL_ACCT IN 
(
	SELECT B03_SKB1_SAKNR
		FROM B03_03_IT_FIN_TB
		GROUP BY B03_SKB1_SAKNR,B03_TB_RYEAR
		HAVING SUM(B03_TB_HSL_TOT_MOV)=0 AND SUM(B03_TB_HSL_DEBIT_MOV)<>0 AND SUM(B03_TB_HSL_CREDIT_MOV)<>0 AND
			   SUM(B03_TB_KSL_TOT_MOV)=0 AND SUM(B03_TB_KSL_DEBIT_MOV)<>0 AND SUM(B03_TB_KSL_CREDIT_MOV)<>0
)

--Debit-credit is 0
UPDATE B04_13_IT_GL_DETAIL
SET B04_ZF_DEBIT_CREDIT_FLAG='Debit-credit is 0'
WHERE GL_ACCT IN 
(
	SELECT B03_SKB1_SAKNR
		FROM B03_03_IT_FIN_TB
		GROUP BY B03_SKB1_SAKNR,B03_TB_RYEAR
		HAVING SUM(B03_TB_HSL_DEBIT_MOV)=0 AND SUM(B03_TB_HSL_CREDIT_MOV)=0
		   AND SUM(B03_TB_KSL_DEBIT_MOV)=0 AND SUM(B03_TB_KSL_CREDIT_MOV)=0
)

/* log end of procedure*/
EXEC SP_REMOVE_TABLES '%_TT_%'

INSERT INTO [dbo].[_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL
GO
