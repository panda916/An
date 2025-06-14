USE [DIVA_ASAP_TEST_DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<vinh.le@aufinia.com>
-- Create date: <March 5, 2021>
-- Description:	Check create/insert AM tables relate to GL accounts
-- =============================================
CREATE    PROCEDURE [dbo].[A_008_CREATE/UPDATE_AM_GL_MAPPING_TABLES_HANH]
AS
BEGIN
	/*
		Step 1: Create AM_GL_HIERARCHY table if it do not exist.
	*/
	PRINT 'Creating AM_GL_HIERARCHY table.'
	IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AM_GL_HIERARCHY')
		BEGIN
			CREATE TABLE [dbo].[AM_GL_HIERARCHY](
				[GL_L1] [nvarchar](100) NULL,
				[GL_L2] [nvarchar](100) NULL,
				[GL_L3] [nvarchar](100) NULL,
				[GL_L4] [nvarchar](100) NULL,
				[GL_ACCT] [nvarchar](100) NULL,
				[GL_TXT] [nvarchar](100) NULL
			)
		END

	-- Make sure the AM_GL_HIERARCHY table do not lose the leading zero.
	UPDATE AM_GL_HIERARCHY
	SET GL_ACCT = RIGHT(CONCAT('0000000000', GL_ACCT), 10)
	WHERE ISNUMERIC(GL_ACCT) = 1

	/*
		Step 2: Create AM_TANGO table if it do not exist.
	*/
	PRINT 'Creating AM_TANGO table.'
	IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AM_TANGO')
		BEGIN
			CREATE TABLE [dbo].[AM_TANGO](
				[TANGO_GL_ACCT] [nvarchar](100) NULL,
				[TANGO_ACCT] [nvarchar](100) NULL,
				[TANGO_ACCT_MAP_TXT] [nvarchar](100) NULL,
				[TANGO_ACCT_TXT] [nvarchar](100) NULL
			)
		END

	-- Make sure the AM_TANGO table do not lose the leading zero.
	UPDATE AM_TANGO
	SET TANGO_GL_ACCT = RIGHT(CONCAT('0000000000', TANGO_GL_ACCT), 10)
	WHERE ISNUMERIC(TANGO_GL_ACCT) = 1


	/*
		Step 3: Collect all Ledger account from BSEG, FAGLFLEXT and GTL0 tables.
	*/

	EXEC SP_REMOVE_TABLES 'A08_01_TT_ACTIVE_LEDGER_ACCOUNTS'
	SELECT DISTINCT T001_KTOPL, A.BSEG_HKONT
	INTO A08_01_TT_ACTIVE_LEDGER_ACCOUNTS
	FROM A_BSEG AS A
    LEFT JOIN A_T001 ON T001_BUKRS = BSEG_BUKRS
	--UNION
	--SELECT DISTINCT T001_KTOPL ,FAGLFLEXT_RACCT FROM A_FAGLFLEXT
	--LEFT JOIN A_T001 ON FAGLFLEXT_RBUKRS = T001_BUKRS
	--UNION
	--SELECT DISTINCT T001_KTOPL ,GLT0_RACCT FROM A_GLT0
	--LEFT JOIN A_T001 ON GLT0_BUKRS = T001_BUKRS


	/*
		Step 4: Only keep Ledger accounts do not exist in AM_GL_HIERARCHY or AM_TANGO
	*/
	EXEC SP_REMOVE_TABLES 'A08_02_TT_NEW_ACTIVE_LEDGER_ACCOUNTS'
	SELECT *
	INTO A08_02_TT_NEW_ACTIVE_LEDGER_ACCOUNTS
	FROM A08_01_TT_ACTIVE_LEDGER_ACCOUNTS
	WHERE NOT EXISTS (
		SELECT TOP 1 1
		FROM AM_GL_HIERARCHY
		WHERE A08_01_TT_ACTIVE_LEDGER_ACCOUNTS.BSEG_HKONT = AM_GL_HIERARCHY.GL_ACCT
	) 
	OR
	NOT EXISTS (
		SELECT TOP 1 1
		FROM AM_TANGO
		WHERE A08_01_TT_ACTIVE_LEDGER_ACCOUNTS.BSEG_HKONT = AM_TANGO.TANGO_GL_ACCT
	)


	/*
		Step 5: Get Ledger account descriptions.
	*/
	EXEC SP_REMOVE_TABLES 'A08_03_TT_NEW_ACTIVE_LEDGER_ACCOUNTS_AND_TEXT'
	SELECT A08_02_TT_NEW_ACTIVE_LEDGER_ACCOUNTS.*, A_SKAT.SKAT_TXT50
	INTO A08_03_TT_NEW_ACTIVE_LEDGER_ACCOUNTS_AND_TEXT
	FROM A08_02_TT_NEW_ACTIVE_LEDGER_ACCOUNTS
	LEFT JOIN A_SKAT
	ON A08_02_TT_NEW_ACTIVE_LEDGER_ACCOUNTS.T001_KTOPL = A_SKAT.SKAT_KTOPL AND
	   A08_02_TT_NEW_ACTIVE_LEDGER_ACCOUNTS.BSEG_HKONT = A_SKAT.SKAT_SAKNR

	/*
		Step 6: Insert new ledger accounts to AM_GL_HIERARCHY
	*/
	INSERT INTO [dbo].[AM_GL_HIERARCHY] ([GL_ACCT],[GL_TXT])
    SELECT DISTINCT BSEG_HKONT, SKAT_TXT50
	FROM A08_03_TT_NEW_ACTIVE_LEDGER_ACCOUNTS_AND_TEXT
	WHERE NOT EXISTS (
		SELECT TOP 1 1
		FROM AM_GL_HIERARCHY
		WHERE A08_03_TT_NEW_ACTIVE_LEDGER_ACCOUNTS_AND_TEXT.BSEG_HKONT = AM_GL_HIERARCHY.GL_ACCT
	)  

	/*
		Step 7: Insert new ledger account to AM_TANGO
	*/
	INSERT INTO [dbo].[AM_TANGO]([TANGO_GL_ACCT], [TANGO_ACCT_MAP_TXT])
	SELECT DISTINCT BSEG_HKONT, SKAT_TXT50
	FROM A08_03_TT_NEW_ACTIVE_LEDGER_ACCOUNTS_AND_TEXT
	WHERE NOT EXISTS (
		SELECT TOP 1 1
		FROM AM_TANGO
		WHERE A08_03_TT_NEW_ACTIVE_LEDGER_ACCOUNTS_AND_TEXT.BSEG_HKONT = AM_TANGO.TANGO_GL_ACCT
	)



	/*
		Step 8: Create AM_SPEND_CATEGORY table if it do not exist.
	*/
	PRINT 'Creating AM_SPEND_CATEGORY table.'
	IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AM_SPEND_CATEGORY')
		BEGIN
			CREATE TABLE [dbo].[AM_SPEND_CATEGORY](
				[SPCAT_GL_ACCNT] [nvarchar](100) NULL,
				[SPCAT_GL_TXT] [nvarchar](100) NULL,
				[SPCAT_SPEND_CAT_LEVEL_1] [nvarchar](100) NULL,
				[SPCAT_SPEND_CAT_LEVEL_2] [nvarchar](100) NULL,
				[SPCAT_SPEND_CAT_LEVEL_3] [nvarchar](100) NULL,
				[SPCAT_SPEND_CAT_LEVEL_4] [nvarchar](100) NULL,
				[SPCAT_SPEND_TYPE] [nvarchar](100) NULL
			)
		END

	-- Make sure the AM_SPEND_CATEGORY table do not lose the leading zero.
	UPDATE AM_SPEND_CATEGORY
	SET SPCAT_GL_ACCNT = RIGHT(CONCAT('0000000000', SPCAT_GL_ACCNT), 10)
	WHERE ISNUMERIC(SPCAT_GL_ACCNT) = 1

	/*
		Step 9: Collect all AP documents from BSEG table
	*/
	EXEC SP_REMOVE_TABLES 'A08_04_TT_AP_DOCS'
	SELECT DISTINCT BSEG_MANDT, BSEG_BUKRS, BSEG_GJAHR, BSEG_BELNR
	INTO A08_04_TT_AP_DOCS
	FROM A_BSEG
	WHERE BSEG_KOART = 'K'



	/*
		Step 10: Create list Ledger accounts only relate to AP documents. (Because we only use it for Spend overview dashboard)
	*/
	EXEC SP_REMOVE_TABLES 'A08_05_TT_SPEND_CATEGORY_ACCOUNTS'
	SELECT DISTINCT A_BSEG.BSEG_HKONT, T001_KTOPL
	INTO A08_05_TT_SPEND_CATEGORY_ACCOUNTS
	FROM A_BSEG
    LEFT JOIN A_T001 ON BSEG_BUKRS = T001_BUKRS
	INNER JOIN A08_04_TT_AP_DOCS
	ON A_BSEG.BSEG_BUKRS = A08_04_TT_AP_DOCS.BSEG_BUKRS AND
	   A_BSEG.BSEG_GJAHR = A08_04_TT_AP_DOCS.BSEG_GJAHR AND
	   A_BSEG.BSEG_BELNR = A08_04_TT_AP_DOCS.BSEG_BELNR
	
	
	
	/*
		Step 10: Add ledger account texts
	*/
	EXEC SP_REMOVE_TABLES 'A08_06_TT_SPEND_CATEGORY_ACCOUNTS_AND_TEXTS'
	SELECT DISTINCT A08_05_TT_SPEND_CATEGORY_ACCOUNTS.BSEG_HKONT, A_SKAT.SKAT_TXT50
	INTO A08_06_TT_SPEND_CATEGORY_ACCOUNTS_AND_TEXTS
	FROM A08_05_TT_SPEND_CATEGORY_ACCOUNTS
	LEFT JOIN A_SKAT
	ON A_SKAT.SKAT_KTOPL = A08_05_TT_SPEND_CATEGORY_ACCOUNTS.T001_KTOPL AND
	   A_SKAT.SKAT_SAKNR = A08_05_TT_SPEND_CATEGORY_ACCOUNTS.BSEG_HKONT



	/*
		Step 11: Insert ledger account to AM_SPEND_CATEGORY if it do not exist.
	*/
	INSERT INTO [dbo].[AM_SPEND_CATEGORY] ([SPCAT_GL_ACCNT],[SPCAT_GL_TXT])
	SELECT DISTINCT BSEG_HKONT, SKAT_TXT50
	FROM A08_06_TT_SPEND_CATEGORY_ACCOUNTS_AND_TEXTS
	WHERE NOT EXISTS (
		SELECT TOP 1 1
		FROM AM_SPEND_CATEGORY
		WHERE A08_06_TT_SPEND_CATEGORY_ACCOUNTS_AND_TEXTS.BSEG_HKONT = AM_SPEND_CATEGORY.SPCAT_GL_ACCNT
	)



	/*
		Step 12: Create AM_IRGR_GINI_ARDR_MAPPING table if it not exist.
	*/
	IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AM_IRGR_GINI_ARDR_MAPPING')
		BEGIN
			CREATE TABLE [dbo].[AM_IRGR_GINI_ARDR_MAPPING](
				[IRGR_GL_ACCT] [nvarchar](100) NULL,
				[IRGR_GL_TXT] [nvarchar](100) NULL,
				[IRGR_OR_GINI_OR_ARDR] [nvarchar](100) NULL
			)
		END

	-- Make sure the AM_IRGR_GINI_ARDR_MAPPING table do not lose the leading zero.
	UPDATE AM_IRGR_GINI_ARDR_MAPPING
	SET IRGR_GL_ACCT = RIGHT(CONCAT('0000000000', IRGR_GL_ACCT), 10)
	WHERE ISNUMERIC(IRGR_GL_ACCT) = 1



	/*
		Step 13: Insert AM_IRGR_GINI_ARDR_MAPPING table base on current entity and list IRGR accounts AM_IRGR_GL_ACCT.xlsx for Jesper's email on Tue 3/30/2021 3:22 PM.
				 Email Subject: "RE: AM_IRGR_GL_ACCT Mapping Tables for all regions"
				 Subroutine: 
								+ Create an AM_IRGR_GINI_ARDR_MAPPING_TEMP table to contain all IRGR accounts of current entity base on Jesper excel file.
								+ Only insert new items to AM_IRGR_GINI_ARDR_MAPPING from AM_IRGR_GINI_ARDR_MAPPING_TEMP 
	*/
	
	-- Create an AM_IRGR_GINI_ARDR_MAPPING_TEMP table to contain all IRGR accounts of current region base on Jesper excel file.
	EXEC SP_REMOVE_TABLES 'AM_IRGR_GINI_ARDR_MAPPING_TEMP'
	SELECT TOP 0 *
	INTO AM_IRGR_GINI_ARDR_MAPPING_TEMP
	FROM AM_IRGR_GINI_ARDR_MAPPING
	IF CHARINDEX('SPE', DB_NAME()) <> 0
		BEGIN
			INSERT INTO [dbo].[AM_IRGR_GINI_ARDR_MAPPING_TEMP] ([IRGR_GL_ACCT],[IRGR_GL_TXT],[IRGR_OR_GINI_OR_ARDR]) VALUES
			('0000200702', '', 'ARDR'), ('0000200708', '', 'ARDR'), ('0000200709', '', 'ARDR'), ('0000203000', '', 'ARDR'),
			('0000203001', '', 'ARDR'), ('0000203003', '', 'ARDR'), ('0000203004', '', 'ARDR'), ('0000203005', '', 'ARDR'),
			('0000203050', '', 'ARDR'), ('0000203100', '', 'ARDR'), ('0000203110', '', 'ARDR'), ('0000204000', '', 'ARDR'),
			('0000204100', '', 'ARDR'), ('0000220302', '', 'ARDR'), ('0000230025', '', 'ARDR'), ('0000290000', '', 'ARDR'),
			('0000290070', '', 'ARDR'), ('0000290080', '', 'ARDR'), ('0000290100', '', 'ARDR'), ('0000200702', '', 'ARDR'),
			('S200702', '', 'ARDR'), ('0000200708', '', 'ARDR'), ('S200708', '', 'ARDR'), ('0000200709', '', 'ARDR'),
			('S200709', '', 'ARDR'), ('0000203000', '', 'ARDR'), ('TZ203000', '', 'ARDR'), ('I203000', '', 'ARDR'),
			('S203000', '', 'ARDR'), ('0000203001', '', 'ARDR'), ('S203001', '', 'ARDR'), ('0000203003', '', 'ARDR'),
			('S203003', '', 'ARDR'), ('0000203004', '', 'ARDR'), ('S203004', '', 'ARDR'), ('0000203005', '', 'ARDR'),
			('I203005', '', 'ARDR'), ('S203005', '', 'ARDR'), ('0000203050', '', 'ARDR'), ('S203050', '', 'ARDR'),
			('0000203100', '', 'ARDR'), ('I203100', '', 'ARDR'), ('S203100', '', 'ARDR'), ('0000203110', '', 'ARDR'),
			('I203110', '', 'ARDR'), ('S203110', '', 'ARDR'), ('0000204000', '', 'ARDR'), ('TZ204000', '', 'ARDR'),
			('I204000', '', 'ARDR'), ('S204000', '', 'ARDR'), ('0000204100', '', 'ARDR'), ('S204100', '', 'ARDR'),
			('I204100', '', 'ARDR'), ('0000220302', '', 'ARDR'), ('I220302', '', 'ARDR'), ('S220302', '', 'ARDR'),
			('0000230025', '', 'ARDR'), ('I230025', '', 'ARDR'), ('S230025', '', 'ARDR'), ('0000290000', '', 'ARDR'),
			('I290000', '', 'ARDR'), ('S290000', '', 'ARDR'), ('0000290070', '', 'ARDR'), ('I290070', '', 'ARDR'),
			('S290070', '', 'ARDR'), ('0000290080', '', 'ARDR'), ('I290080', '', 'ARDR'), ('S290080', '', 'ARDR'),
			('0000290100', '', 'ARDR'), ('S290100', '', 'ARDR'), ('S200120', '', 'IRGR'), ('0000200120', '', 'IRGR'),
			('S200075', '', 'IRGR'), ('0000200075', '', 'IRGR')

		END
	ELSE IF CHARINDEX('SPNI', DB_NAME()) <> 0
		BEGIN
			INSERT INTO [dbo].[AM_IRGR_GINI_ARDR_MAPPING_TEMP] ([IRGR_GL_ACCT],[IRGR_GL_TXT],[IRGR_OR_GINI_OR_ARDR]) VALUES
			('0000625051', '', 'IRGR'),
			('0000990016', '', 'IRGR'),
			('0000305954', '', 'ARDR'),
			('0000305958', '', 'ARDR'),
			('0000305960', '', 'ARDR'),
			('0000305961', '', 'ARDR'),
			('0000305962', '', 'ARDR'),
			('0000305964', '', 'ARDR'),
			('0000305965', '', 'ARDR'),
			('0000305966', '', 'ARDR'),
			('0000305967', '', 'ARDR'),
			('0000305968', '', 'ARDR'),
			('0000350504', '', 'ARDR'),
			('0000305255', '', 'ARDR'),
			('0000305256', '', 'ARDR'),
			('0000305257', '', 'ARDR')
		END
	ELSE IF CHARINDEX('RUSSIA', DB_NAME()) <> 0 OR CHARINDEX('SCIS', DB_NAME()) <> 0
		BEGIN
			INSERT INTO [dbo].[AM_IRGR_GINI_ARDR_MAPPING_TEMP] ([IRGR_GL_ACCT],[IRGR_GL_TXT],[IRGR_OR_GINI_OR_ARDR]) VALUES
			('S120121','GOODS ISSUED NOT INVOICED SPARE PARTS','GINI'),
			('S120122','GOODS ISSUED NOT INVOICED RME','GINI'),
			('S120123','GOODS ISSUED NOT INVOICED PSE','GINI'),
			('S120124','GOODS ISSUED NOT INVOICED ITE','GINI'),
			('S120125','GOODS ISSUED NOT INVOICED CAV','GINI'),
			('S120126','GOODS ISSUED NOT INVOICED OWN PLANT','GINI'),
			('S120127','GOODS ISSUED NOT INVOICED SALESCO STYLE STORE','GINI'),
			('S213100','AP TRADE INVOICES TO BE RECEIVED','IRGR'),
			('S213105','AP TRADE INVOICES TO BE RECEIVED','IRGR'),
			('S213107','AP TRADE INVOICES TO BE RECEIVED (GR/IR - GENERAL)','IRGR'),
			('S213110','INVOICES TO BE RECEIVED SPARE PARTS','IRGR'),
			('S213120','AP TRADE CREDIT NOTES TO BE RECEIVED','IRGR'),
			('S223105','AP NON TRADE INVOICES TO BE RECEIVED GR/IR','IRGR')
		END
	ELSE IF CHARINDEX('TURKEY', DB_NAME()) <> 0 OR CHARINDEX('STURK', DB_NAME()) <> 0
		BEGIN
			INSERT INTO [dbo].[AM_IRGR_GINI_ARDR_MAPPING_TEMP] ([IRGR_GL_ACCT],[IRGR_GL_TXT],[IRGR_OR_GINI_OR_ARDR]) VALUES
			('A226010','Deferred revenue-current- General','ARDR'),
			('A226015','Deferred revenue-current-Advance Receipts','ARDR'),
			('A226060','Deferred revenue-current- Voucher','ARDR'),
			('A226080','Deferred revenue-current- Extended warranty','ARDR'),
			('A226100','Deferred revenue - current (not from customers)','ARDR'),
			('A226990','Deferred Revenue- FX translation','ARDR'),
			('A212100','Trade AP- invoice to be received- GRIR 1','IRGR'),
			('A212101','Trade AP- invoice to be received- GRIR 2','IRGR'),
			('A215070','AP-non trade, invoice to be received, GRIR','IRGR'),
			('A215080','AP-non trade,invoice to be received,direct GLentry','IRGR'),
			('A330010','Deferred revenue - General','ARDR'),
			('A330100','Deferred revenue- non-current (Not from Customers)','ARDR')
		END
	ELSE IF CHARINDEX('SOLA', DB_NAME()) <> 0
		BEGIN
			INSERT INTO [dbo].[AM_IRGR_GINI_ARDR_MAPPING_TEMP] ([IRGR_GL_ACCT],[IRGR_GL_TXT],[IRGR_OR_GINI_OR_ARDR]) VALUES
			('2211000310', '', 'IRGR'),
			('2211000311', '', 'IRGR'),
			('2211000320', '', 'IRGR'),
			('2211000321', '', 'IRGR'),
			('2211000345', '', 'ARDR'),
			('2225000000', '', 'ARDR'),
			('2225000005', '', 'ARDR')
			
		END

	-- Only insert new items to AM_IRGR_GINI_ARDR_MAPPING from AM_IRGR_GINI_ARDR_MAPPING_TEMP 
	INSERT INTO [dbo].[AM_IRGR_GINI_ARDR_MAPPING] ([IRGR_GL_ACCT],[IRGR_GL_TXT],[IRGR_OR_GINI_OR_ARDR])
	SELECT 
			AM_IRGR_GINI_ARDR_MAPPING_TEMP.IRGR_GL_ACCT, 
			AM_IRGR_GINI_ARDR_MAPPING_TEMP.IRGR_GL_TXT, 
			AM_IRGR_GINI_ARDR_MAPPING_TEMP.IRGR_OR_GINI_OR_ARDR
	FROM AM_IRGR_GINI_ARDR_MAPPING_TEMP
	WHERE NOT EXISTS (
						SELECT TOP 1 1 
						FROM AM_IRGR_GINI_ARDR_MAPPING 
						WHERE AM_IRGR_GINI_ARDR_MAPPING.IRGR_GL_ACCT = AM_IRGR_GINI_ARDR_MAPPING_TEMP.IRGR_GL_ACCT AND
								AM_IRGR_GINI_ARDR_MAPPING.IRGR_OR_GINI_OR_ARDR = AM_IRGR_GINI_ARDR_MAPPING_TEMP.IRGR_OR_GINI_OR_ARDR
						)
	EXEC SP_REMOVE_TABLES 'AM_IRGR_GINI_ARDR_MAPPING_TEMP'


	/*
		Step 14: Update descriptions for ledger accounts which are have blank in [IRGR_GL_TXT] column.
	*/
	DECLARE @CURRENT_KTOPL NVARCHAR(10)
	SELECT TOP 1 @CURRENT_KTOPL = T001_KTOPL 
	FROM A_BKPF
	LEFT JOIN A_T001
	ON A_BKPF.BKPF_BUKRS = A_T001.T001_BUKRS

	UPDATE AM_IRGR_GINI_ARDR_MAPPING
	SET IRGR_GL_TXT = A_SKAT.SKAT_TXT50
	FROM AM_IRGR_GINI_ARDR_MAPPING
	LEFT JOIN A_SKAT
	ON AM_IRGR_GINI_ARDR_MAPPING.IRGR_GL_ACCT = A_SKAT.SKAT_SAKNR AND
		SKAT_KTOPL = @CURRENT_KTOPL
	WHERE IRGR_GL_TXT = ''
	

	/*
		Step 15: Create AM_IRGR_MATERIAL_GROUP_HIERARCHY if it do not exist
	*/
	IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AM_IRGR_MATERIAL_GROUP_HIERARCHY')
		BEGIN
			CREATE TABLE [dbo].[AM_IRGR_MATERIAL_GROUP_HIERARCHY](
				[T023T_MATKL] [nvarchar](500) NULL,
				[T023T_WGBEZ] [nvarchar](500) NULL,
				[IRGR_SPEND_CAT_LEVEL_1] [nvarchar](500) NULL,
				[IRGR_SPEND_CAT_LEVEL_2] [nvarchar](500) NULL,
				[IRGR_SPEND_CAT_LEVEL_3] [nvarchar](500) NULL,
				[IRGR_SPEND_CAT_LEVEL_4] [nvarchar](500) NULL
			)
		END


	/*
		Step 16: Collect all material numbers relevant to IRGR accounts from BSEG table.
	*/

	/*
	INSERT INTO AM_IRGR_GINI_ARDR_MAPPING VALUES(
	'A215400', 'Concur Global Pay', 'IRGR '
	)
	*/



	SELECT 
		DISTINCT [(Z_Spend category level 1)], [(Z_Spend category level 2)], [(Z_Spend category level 3)]
	FROM AM_GPW_MAPPING_LEVEL
	WHERE [(APA-lines#Material group)] in 
	(
		SELECT DISTINCT T023T_MATKL
		FROM AM_IRGR_MATERIAL_GROUP_HIERARCHY
		WHERE IRGR_SPEND_CAT_LEVEL_1 IS NULL
	)

	SELECT DISTINCT T023T_MATKL
	FROM AM_IRGR_MATERIAL_GROUP_HIERARCHY
	WHERE IRGR_SPEND_CAT_LEVEL_1 IS NULL
	AND T023T_MATKL NOT IN 
		(
			SELECT DISTINCT [(APA-lines#Material group)]
			FROM AM_GPW_MAPPING_LEVEL
		)


	DROP TABLE AM_GPW_MAPPING_LEVEL


	DELETE FROM [AM_IRGR_GINI_ARDR_MAPPING]
	WHERE IRGR_GL_ACCT = 'A215400'



	EXEC SP_REMOVE_TABLES 'AM_IRGR_MATERIAL_GROUP_HIERARCHY'
	
	SELECT DISTINCT EKPO_MATKL, A_T023T.T023T_WGBEZ
	INTO A08_07_TT_IRGR_MATERIAL_GROUP
	FROM A_BSEG

	-- Step 1/ Get only  GL accounts related to GRIR
	INNER JOIN AM_IRGR_GINI_ARDR_MAPPING
	ON A_BSEG.BSEG_HKONT = AM_IRGR_GINI_ARDR_MAPPING.IRGR_GL_ACCT AND
		AM_IRGR_GINI_ARDR_MAPPING.IRGR_OR_GINI_OR_ARDR = 'IRGR'

	-- Step 2 / Get material group from PO line items
	INNER JOIN A_EKPO 
		ON BSEG_EBELN = EKPO_EBELN
		AND BSEG_EBELP = EKPO_EBELP

	-- Step 3 / Get material group descriptions
	LEFT JOIN A_T023T
		ON A_T023T.T023T_MATKL = A_EKPO.EKPO_MATKL 
	WHERE A_BSEG.BSEG_EBELN <> '' 
		AND A_EKPO.EKPO_MATKL <> ''

-- Question for Jesper.
-- Number of PO in BSEG table : 168, 126	
	SELECT DISTINCT BSEG_EBELN, BSEG_EBELP
	FROM A_BSEG

	-- Step 1/ Get only  GL accounts related to GRIR
	INNER JOIN AM_IRGR_GINI_ARDR_MAPPING
	ON A_BSEG.BSEG_HKONT = AM_IRGR_GINI_ARDR_MAPPING.IRGR_GL_ACCT AND
		AM_IRGR_GINI_ARDR_MAPPING.IRGR_OR_GINI_OR_ARDR = 'IRGR'
	WHERE BSEG_EBELN <> ''

-- Number of PO in BSEG found in EKPO table.
-- 39,919
-- Number of PO in BSEG only = 128,207
	SELECT DISTINCT BSEG_EBELN, BSEG_EBELP
	FROM A_BSEG

	-- Step 1/ Get only  GL accounts related to GRIR
	INNER JOIN AM_IRGR_GINI_ARDR_MAPPING
	ON A_BSEG.BSEG_HKONT = AM_IRGR_GINI_ARDR_MAPPING.IRGR_GL_ACCT AND
		AM_IRGR_GINI_ARDR_MAPPING.IRGR_OR_GINI_OR_ARDR = 'IRGR'
	INNER JOIN A_EKPO
		ON BSEG_EBELN = EKPO_EBELN
		AND BSEG_EBELP = EKPO_EBELP
	WHERE BSEG_EBELN <> ''


	SELECT 
		DISTINCT BSEG_EBELN, BSEG_EBELP, EKPO_MATNR, EKPO_MATNR, BSEG_HKONT
	FROM A_BSEG
	INNER JOIN A_BKPF 
			ON BKPF_BELNR = A_BSEG.BSEG_BELNR
			AND BKPF_BUKRS = A_BSEG.BSEG_BUKRS
			AND BKPF_GJAHR=  A_BSEG.BSEG_GJAHR
	-- Step 1/ Get only  GL accounts related to GRIR
	LEFT JOIN AM_IRGR_GINI_ARDR_MAPPING
	ON A_BSEG.BSEG_HKONT = AM_IRGR_GINI_ARDR_MAPPING.IRGR_GL_ACCT AND
		AM_IRGR_GINI_ARDR_MAPPING.IRGR_OR_GINI_OR_ARDR = 'IRGR'
	LEFT JOIN A_EKPO
		ON BSEG_EBELN = EKPO_EBELN
		AND BSEG_EBELP = EKPO_EBELP
	WHERE BSEG_EBELN <> ''
	AND EKPO_EBELN IS NULL
	AND BKPF_BLART = 'RE'


	/*
		Step 17: Insert to new items to AM_IRGR_MATERIAL_GROUP_HIERARCHY table
	*/
	INSERT INTO [dbo].[AM_IRGR_MATERIAL_GROUP_HIERARCHY](T023T_MATKL, T023T_WGBEZ,IRGR_SPEND_CAT_LEVEL_4)
	SELECT DISTINCT EKPO_MATKL, T023T_WGBEZ, T023T_WGBEZ
	FROM A08_07_TT_IRGR_MATERIAL_GROUP
	WHERE NOT EXISTS (SELECT TOP 1 1 FROM AM_IRGR_MATERIAL_GROUP_HIERARCHY WHERE A08_07_TT_IRGR_MATERIAL_GROUP.EKPO_MATKL = AM_IRGR_MATERIAL_GROUP_HIERARCHY.T023T_MATKL)

	SELECT *
	FROM [AM_IRGR_MATERIAL_GROUP_HIERARCHY]

-- Link between Rene file with IRGR material group

SELECT *
FROM [_Procurement_Category_Structure$]


SELECT 
	T023T_MATKL,
	T023T_WGBEZ,
	ISNULL( IRGR_SPEND_CAT_LEVEL_1, '') AS IRGR_SPEND_CAT_LEVEL_1,
	ISNULL( IRGR_SPEND_CAT_LEVEL_2, '') AS IRGR_SPEND_CAT_LEVEL_2,
	ISNULL( IRGR_SPEND_CAT_LEVEL_3, '') AS IRGR_SPEND_CAT_LEVEL_3,
	ISNULL( IRGR_SPEND_CAT_LEVEL_4, '') AS IRGR_SPEND_CAT_LEVEL_4
FROM [AM_IRGR_MATERIAL_GROUP_HIERARCHY]



UPDATE A
SET A.IRGR_SPEND_CAT_LEVEL_1 = B.[LEVEL 1],
	A.IRGR_SPEND_CAT_LEVEL_2 = B.[LEVEL 2],
	A.IRGR_SPEND_CAT_LEVEL_3 = B.[LEVEL 3]
FROM [AM_IRGR_MATERIAL_GROUP_HIERARCHY] A
INNER JOIN [_Procurement_Category_Structure$] B 
	ON A.T023T_MATKL = B.ID



	SELECT DISTINCT BSEG_EBELN, BSEG_EBELP, EKPO_MATKL, BSEG_HKONT
	FROM A_BSEG

	-- Step 1/ Get only  GL accounts related to GRIR
	INNER JOIN AM_IRGR_GINI_ARDR_MAPPING
	ON A_BSEG.BSEG_HKONT = AM_IRGR_GINI_ARDR_MAPPING.IRGR_GL_ACCT AND
		AM_IRGR_GINI_ARDR_MAPPING.IRGR_OR_GINI_OR_ARDR = 'IRGR'
	INNER JOIN A_EKPO
		ON BSEG_EBELN = EKPO_EBELN
		AND BSEG_EBELP = EKPO_EBELP
	WHERE BSEG_EBELN <> ''
	AND EKPO_MATKL = 'A03F'



	EXEC SP_REMOVE_TABLES 'A08_%'
END




GO
