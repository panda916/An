USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[A_019_CREATE/UPDATE_AM_AR_AP_CLEARING]
AS
BEGIN
	/*
		Step 1: Create AM_AR_CLEARING and AM_AP_CLEARING if it do not exists
	*/
	PRINT 'Creating AM_AR_CLEARING table.'
	IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE 'AM_AR_CLEARING')
		BEGIN
			CREATE TABLE [dbo].[AM_AR_CLEARING](
				[ZF_ACCOUNTS] [nvarchar](100) NULL,
				[SKAT_TXT50] [nvarchar](1000) NULL,
				[SKAT_TXT20] [nvarchar](1000) NULL,
				[ZF_AR_CLEARING] [nvarchar](100) NULL
			)
		END

	PRINT 'Creating AM_AP_CLEARING table.'
	IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE 'AM_AP_CLEARING')
		BEGIN
			CREATE TABLE [dbo].[AM_AP_CLEARING](
				[ZF_ACCOUNTS] [nvarchar](100) NULL,
				[SKAT_TXT50] [nvarchar](1000) NULL,
				[SKAT_TXT20] [nvarchar](1000) NULL,
				[ZF_AP_CLEARING] [nvarchar](100) NULL
			)
		END
-- Step 2:
------------------------- Create list of AR account -------------------------------------

	-- Step 2.1: Get all lines for these journal entries where KOART = D on Credit. 
		EXEC SP_DROPTABLE 'A017_01_TT_CREDIT_CUSTOMER_DOCUMENT'
	
		SELECT DISTINCT BSEG_GJAHR,BSEG_BELNR,BSEG_BUKRS
		INTO A017_01_TT_CREDIT_CUSTOMER_DOCUMENT
		FROM A_BSEG
		WHERE BSEG_KOART='D' AND BSEG_SHKZG='H'

	-- Step 2.2: Get all lines where KOART = S on Debit that exists in B017_01_TT_CREDIT_CUSTOMER_DOCUMENT table
		EXEC SP_DROPTABLE 'A017_02_TT_AR_ACCOUNT'

		SELECT DISTINCT BSEG_HKONT,SKAT_TXT20,
			SKAT_TXT50
		INTO A017_02_TT_AR_ACCOUNT
		FROM A_BSEG
		LEFT JOIN A_T001 ON T001_BUKRS=BSEG_BUKRS
		LEFT JOIN A_SKAT
		ON T001_KTOPL = SKAT_KTOPL
		AND BSEG_HKONT = SKAT_SAKNR
		AND SKAT_SPRAS='EN'
		WHERE BSEG_KOART='S' AND BSEG_SHKZG='S'
		AND EXISTS
		(
			SELECT TOP 1 1
			FROM A017_01_TT_CREDIT_CUSTOMER_DOCUMENT
			WHERE A_BSEG.BSEG_BELNR = A017_01_TT_CREDIT_CUSTOMER_DOCUMENT.BSEG_BELNR
			AND A_BSEG.BSEG_GJAHR = A017_01_TT_CREDIT_CUSTOMER_DOCUMENT.BSEG_GJAHR
			AND A_BSEG.BSEG_BUKRS = A017_01_TT_CREDIT_CUSTOMER_DOCUMENT.BSEG_BUKRS
		)

	-- Step 2.3: Insert new value for AM table.

	INSERT INTO [dbo].[AM_AR_CLEARING] ([ZF_ACCOUNTS], [SKAT_TXT50],[SKAT_TXT20],[ZF_AR_CLEARING])
	SELECT DISTINCT BSEG_HKONT, SKAT_TXT50, SKAT_TXT20, NULL
	FROM A017_02_TT_AR_ACCOUNT
	WHERE NOT EXISTS 
	(
		SELECT TOP 1 1 
		FROM AM_AR_CLEARING
		WHERE AM_AR_CLEARING.ZF_ACCOUNTS = BSEG_HKONT 
	)

-- Step 3:
------------------------- Create list of AP account -------------------------------------

	-- Step 3.1: Get all lines for these journal entries where KOART = K on Debit. 
		EXEC SP_DROPTABLE 'A017_03_TT_CREDIT_SUPPLIER_DOCUMENT'

		SELECT DISTINCT BSEG_GJAHR,BSEG_BELNR,BSEG_BUKRS
		INTO A017_03_TT_CREDIT_SUPPLIER_DOCUMENT
		FROM A_BSEG
		WHERE BSEG_KOART='K' AND BSEG_SHKZG='S'

	-- Step 3.2:get all lines where KOART = S on Credit that exists in B017_01_TT_CREDIT_CUSTOMER_DOCUMENT table
		EXEC SP_DROPTABLE 'A017_04_TT_AP_ACCOUNT'

		SELECT DISTINCT BSEG_HKONT,SKAT_TXT20,
			SKAT_TXT50
		INTO A017_04_TT_AP_ACCOUNT
		FROM A_BSEG
		LEFT JOIN A_T001 ON T001_BUKRS=BSEG_BUKRS
		LEFT JOIN A_SKAT
		ON T001_KTOPL = SKAT_KTOPL
		AND BSEG_HKONT = SKAT_SAKNR
		AND SKAT_SPRAS='EN'
		WHERE BSEG_KOART='S' AND BSEG_SHKZG='H'
		AND EXISTS
		(
			SELECT TOP 1 1
			FROM A017_03_TT_CREDIT_SUPPLIER_DOCUMENT
			WHERE A_BSEG.BSEG_BELNR = A017_03_TT_CREDIT_SUPPLIER_DOCUMENT.BSEG_BELNR
			AND   A_BSEG.BSEG_GJAHR = A017_03_TT_CREDIT_SUPPLIER_DOCUMENT.BSEG_GJAHR
			AND   A_BSEG.BSEG_BUKRS =A017_03_TT_CREDIT_SUPPLIER_DOCUMENT.BSEG_BUKRS
		)

	-- Step 3.3: Insert new value for AM table.

	INSERT INTO [dbo].[AM_AP_CLEARING] ([ZF_ACCOUNTS], [SKAT_TXT50],[SKAT_TXT20] ,[ZF_AP_CLEARING])
	SELECT DISTINCT BSEG_HKONT, SKAT_TXT20, SKAT_TXT50, NULL
	FROM A017_04_TT_AP_ACCOUNT
	WHERE NOT EXISTS (
		SELECT TOP 1 1 
		FROM AM_AP_CLEARING
		WHERE AM_AP_CLEARING.ZF_ACCOUNTS = BSEG_HKONT 
			
	)	

--Step 4 Get the list of account that should be see as Others

	EXEC SP_DROPTABLE AM_OTHER_ACCOUTS

	SELECT DISTINCT SKAT_SAKNR,SKAT_TXT50
	INTO AM_OTHER_ACCOUTS
		FROM A_SKAT
	WHERE  SKAT_SAKNR LIKE 'A226%' OR SKAT_SAKNR LIKE 'A99%'

--Step 5 Get the list account type is S

	PRINT 'Creating AM_AR_ACCOUNT table.'
	IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE 'AM_AR_ACCOUNT')
		BEGIN
			CREATE TABLE [dbo].[AM_AR_ACCOUNT](
				[BSEG_HKONT] [nvarchar](100) NULL,
				[SKAT_TXT50] [nvarchar](1000) NULL,
				[SKAT_TXT20] [nvarchar](1000) NULL,
				[ZF_AR_ACCOUNT] [nvarchar](100) NULL
			)
		END
		
	-- Step 2.2  Get the list of GL account where account type is S

	EXEC SP_DROPTABLE A17_05_TT_GL_ACCOUNT_KOART_S
	SELECT DISTINCT BSEG_HKONT,SKAT_TXT50,SKAT_TXT20,'' AS ZF_AR_ACCOUNT
	INTO A17_05_TT_GL_ACCOUNT_KOART_S
	FROM A_BSEG
	LEFT JOIN A_T001 ON T001_BUKRS=BSEG_BUKRS
	LEFT JOIN A_SKAT
	ON BSEG_HKONT=SKAT_SAKNR AND T001_KTOPL=SKAT_KTOPL
	WHERE  BSEG_KOART='S'

	-- Step 2.3: Insert new value for AM table.

	INSERT INTO [dbo].[AM_AR_ACCOUNT] ([BSEG_HKONT], [SKAT_TXT50],[SKAT_TXT20],[ZF_AR_ACCOUNT])
	SELECT DISTINCT BSEG_HKONT, SKAT_TXT50, SKAT_TXT20, NULL
	FROM A17_05_TT_GL_ACCOUNT_KOART_S
	WHERE NOT EXISTS 
	(
		SELECT TOP 1 1 
		FROM [AM_AR_ACCOUNT]
		WHERE [AM_AR_ACCOUNT].BSEG_HKONT = A17_05_TT_GL_ACCOUNT_KOART_S.BSEG_HKONT 
	)
	EXEC SP_DROPTABLE '%_TT_%'
END






GO
