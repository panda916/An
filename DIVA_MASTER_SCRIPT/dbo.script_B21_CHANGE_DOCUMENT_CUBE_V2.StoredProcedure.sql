USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Khoi
-- Create date: <Create Date,,>
-- Description:	Create the change document cubes
-- 23-03-2022	 Thuan	 Remove MANDT field in join
--Each Objectclas might have many change document cube
--List of cubes:
--		Objectclas is EINKBELEG:
--				PO approval
--				PO price change
--				PO creation date change
--				PO amount change
--				Release strategy Change
--		Objectclas is INCOMINGINVOICE:
--				Invoice approval
--				Release invoice required
--				Invoice quantity changes
--		Objectclas is IBAN:
--				IBAN change
--		Objectclas is KRED(changes To suppliers):
--				Change to release group
--				Supplier is blocked
--				Supplier payment terms
--		Objectclas is BELEG:
--				Change to payment method
--				Change to payment block
--		Objectclas is SACH (changes to Chart Of Accounts)
--		Objectclas is DEBI (Change to customer)
CREATE   PROCEDURE [dbo].[script_B21_CHANGE_DOCUMENT_CUBE_V2]
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
			--,@ZV_LIMIT nvarchar(max)		    = (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'LIMIT_RECORDS')
			,@errormsg NVARCHAR(MAX)
			
DECLARE @dateformat varchar(3)
SET @dateformat   = (SELECT dbo.get_param('dateformat'))
SET DATEFORMAT @dateformat;

BEGIN


--EXEC SP_REMOVE_TABLES 'B21_%'
--Step 1.1 EINKBELEG
--STep 1.1.1 Join CDPOS and CDHDR, add change description and get only neccesary changes
	EXEC SP_DROPTABLE 'B21_01_TT_CDHDR_CDPOS_EINKBELEG'
	SELECT DISTINCT A_CDHDR.*,A_CDPOS.*,
	CASE 
	WHEN CDPOS_TABNAME='EKKO' AND CDPOS_FNAME='FRGZU' AND CDHDR_CHANGE_IND='U' THEN '4_PO_APPROVALS'
	WHEN CDPOS_TABNAME='EKPO' AND CDPOS_FNAME='NETPR' AND CDHDR_CHANGE_IND='U' THEN '6_PO_PRICE_CHANGE'
	WHEN CDPOS_TABNAME='EKPO' or  CDPOS_FNAME='NETWR' AND CDHDR_CHANGE_IND='U' THEN '5_CHANGE_TO_PO_AMOUNT'
	WHEN CDPOS_FNAME='FRGSX' or  CDPOS_FNAME='FRGGR' AND CDHDR_CHANGE_IND='U' THEN '16_CHANGE_TO_RELEASE_STRATEGY'
	 END AS ZF_CHANGE_DESC,
	CASE 
	WHEN CDPOS_TABNAME='EKKO' AND CDPOS_FNAME='FRGZU' AND CDHDR_CHANGE_IND='U' THEN 4
	WHEN CDPOS_TABNAME='EKPO' AND CDPOS_FNAME='NETPR' AND CDHDR_CHANGE_IND='U' THEN 6
	WHEN CDPOS_TABNAME='EKPO' or  CDPOS_FNAME='NETWR' AND CDHDR_CHANGE_IND='U' THEN 5
	WHEN CDPOS_FNAME='FRGSX' or  CDPOS_FNAME='FRGGR' AND CDHDR_CHANGE_IND='U' THEN 16
	 END AS ZF_STAGE
	INTO B21_01_TT_CDHDR_CDPOS_EINKBELEG
	FROM A_CDHDR 
	INNER JOIN A_CDPOS
	ON	CDHDR_OBJECTCLAS=CDPOS_OBJECTCLAS AND
		CDHDR_OBJECTID=CDPOS_OBJECTID AND
		CDHDR_CHANGENR=CDPOS_CHANGENR
	WHERE CDHDR_OBJECTCLAS='EINKBELEG'
		AND CDPOS_TABNAME IN ('EKKO','EKPO')
		AND CDPOS_FNAME IN ('FRGZU','NETPR','NETWR','FRGSX','FRGGR') 
		AND CDHDR_CHANGE_IND='U'

--Step 1.1.2 Add other information	
	EXEC SP_DROPTABLE B21_02_IT_CDHDR_CDPOS_EINKBELEG
		SELECT B21_01_TT_CDHDR_CDPOS_EINKBELEG.*,
		V_USERNAME_NAME_TEXT,	
	DDFTX_SCRTEXT_L,	--field name
	DD02T_DDTEXT		--table name
	INTO B21_02_IT_CDHDR_CDPOS_EINKBELEG
	FROM B21_01_TT_CDHDR_CDPOS_EINKBELEG
	LEFT JOIN A_V_USERNAME
	ON CDHDR_USERNAME=V_USERNAME_BNAME
	LEFT JOIN B00_DD02T_ENGLISH ON 
		CDPOS_TABNAME = B00_DD02T_ENGLISH.DD02T_TABNAME
	LEFT JOIN B00_DDFTX_ENGLISH ON 
         CDPOS_TABNAME = B00_DDFTX_ENGLISH.DDFTX_TABNAME
        AND CDPOS_FNAME = B00_DDFTX_ENGLISH.DDFTX_FIELDNAME
--STEP 1.2 INCOMINGINVOICE
--Step 1.2.1 Join CDPOS and CDHDR, add change description and get only neccesary changes
	EXEC SP_DROPTABLE 'B21_03_TT_CDHDR_CDPOS_INCOMINGINVOICE'
	SELECT DISTINCT A_CDHDR.*,A_CDPOS.*,
	CASE 
		WHEN CDPOS_FNAME='FRGKZ' AND CDHDR_CHANGE_IND='U' THEN '10_RELEASE_OF_INVOICE_REQUIRED'
		WHEN CDPOS_FNAME='WRBTR' AND CDHDR_CHANGE_IND='U' THEN '9_CHANGE_TO_MM_INVOICE_VALUE'
	 END AS ZF_CHANGE_DESC,
	CASE
		WHEN CDPOS_FNAME='FRGKZ' AND CDHDR_CHANGE_IND='U' THEN 10
		WHEN CDPOS_FNAME='WRBTR' AND CDHDR_CHANGE_IND='U' THEN 9
		END AS ZF_STAGE
	INTO B21_03_TT_CDHDR_CDPOS_INCOMINGINVOICE
	FROM A_CDHDR 
	INNER JOIN A_CDPOS
	ON	CDHDR_MANDANT=CDPOS_MANDANT AND
		CDHDR_OBJECTCLAS=CDPOS_OBJECTCLAS AND
		CDHDR_OBJECTID=CDPOS_OBJECTID AND
		CDHDR_CHANGENR=CDPOS_CHANGENR
	WHERE CDHDR_OBJECTCLAS='INCOMINGINVOICE'
		AND CDPOS_FNAME IN ('FRGKZ','WRBTR') 
		AND CDPOS_TABNAME IN ('RSEG','RBKP')
		AND CDHDR_CHANGE_IND='U'
--Step 1.2.2 Add other information	
	EXEC SP_DROPTABLE 'B21_04_IT_CDHDR_CDPOS_INCOMINGINVOICE'

		SELECT B21_03_TT_CDHDR_CDPOS_INCOMINGINVOICE.*,
		V_USERNAME_NAME_TEXT,	
	DDFTX_SCRTEXT_L,	--field name
	DD02T_DDTEXT		--table name
	INTO B21_04_IT_CDHDR_CDPOS_INCOMINGINVOICE
	FROM B21_03_TT_CDHDR_CDPOS_INCOMINGINVOICE
	LEFT JOIN A_V_USERNAME
	ON CDHDR_USERNAME=V_USERNAME_BNAME
	LEFT JOIN B00_DD02T_ENGLISH ON 
		CDPOS_TABNAME = B00_DD02T_ENGLISH.DD02T_TABNAME
	LEFT JOIN B00_DDFTX_ENGLISH ON 
         CDPOS_TABNAME = B00_DDFTX_ENGLISH.DDFTX_TABNAME
        AND CDPOS_FNAME = B00_DDFTX_ENGLISH.DDFTX_FIELDNAME

-- Step 1.3  CDHDR_OBJECTCLAS='IBAN'
--Step 1.3.1 Join CDPOS and CDHDR, add change description and get only neccesary changes
	EXEC SP_DROPTABLE 'B21_05_TT_CDHDR_CDPOS_IBAN'
	SELECT DISTINCT A_CDHDR.*,A_CDPOS.*,
	'3_CHANGE_TO_IBAN' ZF_CHANGE_DESC,
	3 AS ZF_STAGE
	INTO B21_05_TT_CDHDR_CDPOS_IBAN
	FROM A_CDHDR 
	INNER JOIN A_CDPOS
	ON	CDHDR_MANDANT=CDPOS_MANDANT AND
		CDHDR_OBJECTCLAS=CDPOS_OBJECTCLAS AND
		CDHDR_OBJECTID=CDPOS_OBJECTID AND
		CDHDR_CHANGENR=CDPOS_CHANGENR
	WHERE CDHDR_OBJECTCLAS='IBAN'


--Step 1.3.2 Add other information	
	EXEC SP_DROPTABLE B21_06_IT_CDHDR_CDPOS_IBAN

		 SELECT B21_05_TT_CDHDR_CDPOS_IBAN.*,
		 LFBK_LIFNR,
	V_USERNAME_NAME_TEXT,	
	DDFTX_SCRTEXT_L,	--field name
	DD02T_DDTEXT		--table name
	INTO B21_06_IT_CDHDR_CDPOS_IBAN
	FROM B21_05_TT_CDHDR_CDPOS_IBAN
	LEFT JOIN A_V_USERNAME
	ON CDHDR_USERNAME=V_USERNAME_BNAME
	LEFT JOIN B00_DD02T_ENGLISH ON 
		CDPOS_TABNAME = B00_DD02T_ENGLISH.DD02T_TABNAME
	LEFT JOIN B00_DDFTX_ENGLISH ON 
         CDPOS_TABNAME = B00_DDFTX_ENGLISH.DDFTX_TABNAME
        AND CDPOS_FNAME = B00_DDFTX_ENGLISH.DDFTX_FIELDNAME
	LEFT JOIN A_LFBK  
		ON  REPLACE(CDHDR_OBJECTID,' ','') LIKE '%'+CONCAT(LFBK_BANKS,LFBK_BANKL,LFBK_BANKN,LFBK_BKONT)+'%'

-- Step 1.4 CDHDR_OBJECTCLAS='Kred'
--Step 1.4.1 Join CDPOS and CDHDR, add change description and get only neccesary changes
	EXEC SP_DROPTABLE 'TEMP1'
	SELECT DISTINCT A_CDHDR.*,A_CDPOS.*,
	CASE
		WHEN CDPOS_TABNAME='LFA1' AND CDPOS_FNAME IN ('LOEVM','SPERR','SPERM','SPERZ') AND CDHDR_CHANGE_IND='U' THEN '11_SUPPLIER_IS_BLOCKED'
		WHEN CDPOS_TABNAME='LFB1' AND CDPOS_FNAME IN ('LOEVM','SPERR','ZAHLS') AND CDHDR_CHANGE_IND='U' THEN '11_SUPPLIER_IS_BLOCKED'
		WHEN CDPOS_TABNAME='LFB1' AND CDPOS_FNAME='ZTERM' AND CDHDR_CHANGE_IND='U' THEN '12_SUPPLIER_PAYMENT_TERMS'
		WHEN CDPOS_TABNAME='LFB1' AND CDPOS_FNAME='FRGRP' AND CDHDR_CHANGE_IND='U' THEN '15_CHANGE_TO_RELEASE_GROUP'
		END AS 
		ZF_CHANGE_DESC,
	CASE
		WHEN CDPOS_TABNAME='LFA1' AND CDPOS_FNAME IN ('LOEVM','SPERR','SPERM','SPERZ') AND CDHDR_CHANGE_IND='U' THEN 11
		WHEN CDPOS_TABNAME='LFB1' AND CDPOS_FNAME IN ('LOEVM','SPERR','ZAHLS') AND CDHDR_CHANGE_IND='U' THEN 11
		WHEN CDPOS_TABNAME='LFB1' AND CDPOS_FNAME='ZTERM' AND CDHDR_CHANGE_IND='U' THEN 12
		WHEN CDPOS_TABNAME='LFB1' AND CDPOS_FNAME='FRGRP' AND CDHDR_CHANGE_IND='U' THEN 15
		END AS 
		ZF_STAGE
	INTO TEMP1
	FROM A_CDHDR 
	INNER JOIN A_CDPOS
	ON	CDHDR_MANDANT=CDPOS_MANDANT AND
		CDHDR_OBJECTCLAS=CDPOS_OBJECTCLAS AND
		CDHDR_OBJECTID=CDPOS_OBJECTID AND
		CDHDR_CHANGENR=CDPOS_CHANGENR
	WHERE CDHDR_OBJECTCLAS='KRED'
	AND CDPOS_TABNAME IN ('LFA1','LFB1') 
	AND CDPOS_FNAME IN ('LOEVM','SPERR','SPERM','SPERZ','ZAHLS','ZTERM','FRGRP')
	AND CDHDR_CHANGE_IND='U'
--Limit down the number of change, get only the necessary company code
	EXEC SP_DROPTABLE 'B21_07_TT_CDHDR_CDPOS_KRED'

	SELECT * 
	INTO B21_07_TT_CDHDR_CDPOS_KRED
	FROM TEMP1
	WHERE CDPOS_TABKEY NOT IN
	(
		SELECT  CDPOS_TABKEY FROM
		TEMP1
		WHERE CDPOS_TABNAME='LFB1' AND RIGHT(CDPOS_TABKEY,4) NOT IN 
		(
			SELECT * FROM AM_COMPANY_CODE
		)
	)
--Step 1.4.2 Add other information	
EXEC SP_DROPTABLE B21_08_IT_CDHDR_CDPOS_KRED

		SELECT B21_07_TT_CDHDR_CDPOS_KRED.*,
				V_USERNAME_NAME_TEXT,	
			DDFTX_SCRTEXT_L,	--field name
			DD02T_DDTEXT		--table name
			INTO B21_08_IT_CDHDR_CDPOS_KRED
			FROM B21_07_TT_CDHDR_CDPOS_KRED
	LEFT JOIN A_V_USERNAME
	ON CDHDR_USERNAME=V_USERNAME_BNAME
	LEFT JOIN B00_DD02T_ENGLISH ON 
		CDPOS_TABNAME = B00_DD02T_ENGLISH.DD02T_TABNAME
	LEFT JOIN B00_DDFTX_ENGLISH ON 
         CDPOS_TABNAME = B00_DDFTX_ENGLISH.DDFTX_TABNAME
        AND CDPOS_FNAME = B00_DDFTX_ENGLISH.DDFTX_FIELDNAME
--Step 1.5 BELEG
--Step 1.5.1  Join CDPOS and CDHDR, add change description and get only neccesary changes
EXEC SP_DROPTABLE B21_09_TT_CDHDR_CDPOS_BELEG 

	SELECT DISTINCT A_CDHDR.*,A_CDPOS.*,
	CASE
		WHEN CDPOS_FNAME = 'ZLSCH' AND CDHDR_CHANGE_IND='U' THEN '13_CHANGE_TO_PAYMENT_METHOD'
		WHEN CDPOS_FNAME='ZLSPR'  AND CDHDR_CHANGE_IND='U' THEN '14_CHANGE_TO_PAYMENT_BLOCK'
		WHEN CDPOS_FNAME = 'WRBTR' AND CDPOS_TABNAME IN ('BSAK','BSIK')  AND CDHDR_CHANGE_IND='U'  THEN '9_CHANGE_TO_FI_INVOICE_VALUE'
		END 
		ZF_CHANGE_DESC,
	CASE
		WHEN CDPOS_FNAME = 'ZLSCH' AND CDHDR_CHANGE_IND='U' THEN 13
		WHEN CDPOS_FNAME='ZLSPR'  AND CDHDR_CHANGE_IND='U' THEN 14
		WHEN CDPOS_FNAME = 'WRBTR' AND CDPOS_TABNAME IN ('BSAK','BSIK')  AND CDHDR_CHANGE_IND='U'  THEN 9
		END 
		ZF_STAGE
	INTO B21_09_TT_CDHDR_CDPOS_BELEG
	FROM A_CDHDR 
	INNER JOIN A_CDPOS
	ON	CDHDR_MANDANT=CDPOS_MANDANT AND
		CDHDR_OBJECTCLAS=CDPOS_OBJECTCLAS AND
		CDHDR_OBJECTID=CDPOS_OBJECTID AND
		CDHDR_CHANGENR=CDPOS_CHANGENR
	WHERE CDHDR_OBJECTCLAS='BELEG'
	AND CDPOS_FNAME IN ('WRBTR','ZLSPR','ZLSCH','SPERZ')
	AND CDHDR_CHANGE_IND='U'
	AND CDPOS_TABNAME IN ('BSAK','BSIK')
		 
--Step 1.5.2 Add other information	
EXEC SP_DROPTABLE B21_10_IT_CDHDR_CDPOS_BELEG

		SELECT B21_09_TT_CDHDR_CDPOS_BELEG.*,
				V_USERNAME_NAME_TEXT,	
			DDFTX_SCRTEXT_L,	--field name
			DD02T_DDTEXT		--table name
			INTO B21_10_IT_CDHDR_CDPOS_BELEG
			FROM B21_09_TT_CDHDR_CDPOS_BELEG
	LEFT JOIN A_V_USERNAME
	ON CDHDR_USERNAME=V_USERNAME_BNAME
	LEFT JOIN B00_DD02T_ENGLISH ON 
		CDPOS_TABNAME = B00_DD02T_ENGLISH.DD02T_TABNAME
	LEFT JOIN B00_DDFTX_ENGLISH ON 
         CDPOS_TABNAME = B00_DDFTX_ENGLISH.DDFTX_TABNAME
        AND CDPOS_FNAME = B00_DDFTX_ENGLISH.DDFTX_FIELDNAME

--Step 1.6.1 Get REGUH bank change
EXEC SP_DROPTABLE B21_11_TT_REGUH_BANK

	SELECT DISTINCT A_CDHDR.*,A_CDPOS.*,
	'16_PAYMENT_BANK_CHANGE' AS ZF_DESC_CHANGE,
		16 AS ZF_STAGE 
		INTO B21_11_TT_REGUH_BANK
	FROM A_CDHDR 
	INNER JOIN A_CDPOS
	ON	CDHDR_MANDANT=CDPOS_MANDANT AND
		CDHDR_OBJECTCLAS=CDPOS_OBJECTCLAS AND
		CDHDR_OBJECTID=CDPOS_OBJECTID AND
		CDHDR_CHANGENR=CDPOS_CHANGENR
	WHERE CDPOS_TABNAME='REGUH' AND CDPOS_FNAME='ZBNKN' AND CDHDR_CHANGE_IND='U'

--Step 1.6.2 Add  other information
EXEC SP_DROPTABLE B21_12_IT_REGUH_BANK

		SELECT B21_11_TT_REGUH_BANK.*,
				V_USERNAME_NAME_TEXT,	
			DDFTX_SCRTEXT_L,	--field name
			DD02T_DDTEXT		--table name
			INTO B21_12_IT_REGUH_BANK
			FROM B21_11_TT_REGUH_BANK
	LEFT JOIN A_V_USERNAME
	ON CDHDR_USERNAME=V_USERNAME_BNAME
	LEFT JOIN B00_DD02T_ENGLISH ON 
		CDPOS_TABNAME = B00_DD02T_ENGLISH.DD02T_TABNAME
	LEFT JOIN B00_DDFTX_ENGLISH ON 
         CDPOS_TABNAME = B00_DDFTX_ENGLISH.DDFTX_TABNAME
        AND CDPOS_FNAME = B00_DDFTX_ENGLISH.DDFTX_FIELDNAME

--- Step 1.7 Supplier bank account number 
-- The fields LFBK_BANKN is the one of the main key in LFBK, which is not allowed to change
--To get the change of this field, user has to delete and then inserted the new values to LFBK
--All the delete(E) and insert(I) will be record in CDPOS and CDHDR
--THe CDPOS_TABKEY contains all the mainkey, if someone changes LFBK_BANKN,the last part will be changed and all the remains is the same.
--STep 1.7.1 Get all the change relate to LFBK(Insert and Delete only)


	EXEC SP_DROPTABLE 'B21_13_TT_CDHDR_CDPOS_LFBK'

	SELECT *,

	IIF(B.CDPOS_CHNGIND <> 'U', DBO.TRIM(REVERSE(SUBSTRING(REVERSE(B.CDPOS_TABKEY), 1, CHARINDEX(' ', REVERSE(B.CDPOS_TABKEY))))), '') ZF_LFBK_BANKN,--	LFBK_BANNK
	IIF(B.CDPOS_CHNGIND <> 'U', DBO.TRIM(REPLACE(B.CDPOS_TABKEY, DBO.TRIM(REVERSE(SUBSTRING(REVERSE(B.CDPOS_TABKEY), 1, CHARINDEX(' ', REVERSE(B.CDPOS_TABKEY))))),'')), '') ZF_OTHER_KEY--Other keys
	INTO B21_13_TT_CDHDR_CDPOS_LFBK
	FROM A_CDHDR A
		INNER JOIN A_CDPOS B ON B.CDPOS_CHANGENR = A.CDHDR_CHANGENR
							AND B.CDPOS_OBJECTID = A.CDHDR_OBJECTID
							AND B.CDPOS_OBJECTCLAS = A.CDHDR_OBJECTCLAS
	WHERE CDPOS_TABNAME IN ('LFBK')
		  AND CDHDR_OBJECTID <> ''
		  AND CDPOS_CHNGIND <> 'U' AND CDHDR_OBJECTCLAS='KRED'
--STep 1.7.2 Add other information 

EXEC SP_DROPTABLE B21_14_TT_CDHDR_CDPOS_LFBK_ADD_INFO

		SELECT B21_13_TT_CDHDR_CDPOS_LFBK.*,
				V_USERNAME_NAME_TEXT,	
			DDFTX_SCRTEXT_L,	--field name
			DD02T_DDTEXT		--table name
			INTO B21_14_TT_CDHDR_CDPOS_LFBK_ADD_INFO
			FROM B21_13_TT_CDHDR_CDPOS_LFBK
	LEFT JOIN A_V_USERNAME
	ON CDHDR_USERNAME=V_USERNAME_BNAME
	LEFT JOIN B00_DD02T_ENGLISH ON 
		CDPOS_TABNAME = B00_DD02T_ENGLISH.DD02T_TABNAME
	LEFT JOIN B00_DDFTX_ENGLISH ON 
         CDPOS_TABNAME = B00_DDFTX_ENGLISH.DDFTX_TABNAME
        AND CDPOS_FNAME = B00_DDFTX_ENGLISH.DDFTX_FIELDNAME

--Step 1.7.3 Get the list of (CDHDR_OBJECTID,CDHDR_CHANGENR,CDHDR_OBJECTCLAS )that insert has delete,
--has the same ZF_OTHER_KEY , but different ZF_LFBK_BANKN

	EXEC SP_DROPTABLE 'B21_15_TT_CHANGE_LFBK_INSERT'
	SELECT
	DISTINCT A.CDHDR_OBJECTID, A.CDHDR_CHANGENR, A.CDHDR_OBJECTCLAS 
	INTO B21_15_TT_CHANGE_LFBK_INSERT
	FROM B21_14_TT_CDHDR_CDPOS_LFBK_ADD_INFO A
	WHERE CDPOS_CHNGIND = 'I'
		AND CDPOS_FNAME = 'KEY'
		AND EXISTS(SELECT * FROM B21_13_TT_CDHDR_CDPOS_LFBK B WHERE 
			A.CDHDR_OBJECTCLAS = B.CDHDR_OBJECTCLAS
			AND A.CDHDR_OBJECTID = B.CDHDR_OBJECTID
			AND A.ZF_OTHER_KEY = B.ZF_OTHER_KEY
			AND B.CDPOS_CHNGIND IN ('D', 'E'))

--Step 1.7.4 Get the list of delete that relate to the list of insert, so we can has a table that contains the list of insert and delete for the same key

	EXEC SP_DROPTABLE 'B21_16_TT_CHANGE_LFBK_INSERT_DEL'
	SELECT DISTINCT A.*
	INTO B21_16_TT_CHANGE_LFBK_INSERT_DEL
	FROM B21_14_TT_CDHDR_CDPOS_LFBK_ADD_INFO A
	INNER JOIN B21_15_TT_CHANGE_LFBK_INSERT B ON B.CDHDR_CHANGENR = A.CDHDR_CHANGENR
													AND B.CDHDR_OBJECTCLAS = B.CDHDR_OBJECTCLAS
													AND B.CDHDR_OBJECTID = B.CDHDR_OBJECTID
	ORDER BY A.CDHDR_OBJECTID, A.CDHDR_CHANGENR, A.CDHDR_OBJECTCLAS
--Step 1.7.5 Combine insert and delete values to 1 row, to limit down the table 
	EXEC SP_DROPTABLE 'B21_17_IT_CHANGE_LFBK_INSERT_DEL'
	SELECT DISTINCT A.*,
	A.ZF_LFBK_BANKN ZF_LFBK_BANKN_NEW,
	B.ZF_LFBK_BANKN ZF_LFBK_BANKN_OLD
	INTO B21_17_IT_CHANGE_LFBK_INSERT_DEL
	FROM B21_16_TT_CHANGE_LFBK_INSERT_DEL A
	LEFT JOIN B21_16_TT_CHANGE_LFBK_INSERT_DEL B ON A.CDHDR_OBJECTCLAS = B.CDHDR_OBJECTCLAS
															AND A.CDHDR_OBJECTID = B.CDHDR_OBJECTID
															AND A.CDHDR_CHANGENR = B.CDHDR_CHANGENR
															AND B.CDPOS_FNAME <> 'KEY' AND B.CDPOS_CHNGIND = 'E'
	WHERE A.CDPOS_CHNGIND = 'I' AND A.ZF_LFBK_BANKN <> B.ZF_LFBK_BANKN



--Step 2 Remove all the tt table
EXEC SP_REMOVE_TABLES 'TEMP1'
EXEC SP_REMOVE_TABLES '%_TT_%'
--Step 3 Rename the fields 
EXEC SP_RENAME_FIELD 'B21_02_',B21_02_IT_CDHDR_CDPOS_EINKBELEG
EXEC SP_RENAME_FIELD 'B21_04_',B21_04_IT_CDHDR_CDPOS_INCOMINGINVOICE
EXEC SP_RENAME_FIELD 'B21_06_', B21_06_IT_CDHDR_CDPOS_IBAN
EXEC SP_RENAME_FIELD 'B21_08_',B21_08_IT_CDHDR_CDPOS_KRED
EXEC SP_RENAME_FIELD 'B21_10_', B21_10_IT_CDHDR_CDPOS_BELEG 
EXEC SP_RENAME_FIELD 'B21_12_',B21_12_IT_REGUH_BANK
EXEC SP_RENAME_FIELD 'B21_17_',B21_17_IT_CHANGE_LFBK_INSERT_DEL

END



GO
