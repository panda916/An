USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROCEDURE [dbo].[script_B30_GPW_BSAIK_ECC_SUPPLIER_INFO](@database_name NVARCHAR(1000))
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START

--declare @database_name NVARCHAR(1000) = 'USCULCAASQL03.DIVA_APAC'
	PRINT @database_name

-- Step 1: check if target database has required field and tables.
	DECLARE @SQLCMD NVARCHAR(1000) ='SELECT TOP 1 @RESULT = 1 FROM ' + @database_name + '.DBO.[_CUBE_PTP-06-APA-lines]'
	DECLARE @RESULT INT = 0
	DECLARE @multiplier AS FLOAT = 1
				
	BEGIN TRY
		EXEC SP_EXECUTESQL @QUERY = @SQLCMD, @PARAMS = N'@RESULT INT OUTPUT', @RESULT = @RESULT OUTPUT
	END TRY
	BEGIN CATCH
		PRINT 'TABLE NOT FOUND'
	END CATCH

-- Step 2: if database has required tables and fields, start importing data to B30_GPW_AP_INPUT table
	IF @RESULT = 1
	BEGIN 
		
		SET @SQLCMD = 'SELECT TOP 1 @multiplier = -1 FROM  ' + @database_name + '.DBO.[_CUBE_PTP-06-APA-lines] ' +'
										INNER JOIN ' + @database_name + '.DBO.BSEG ON [Company code] = BUKRS AND [Fiscal year] = GJAHR AND [Document nr]  = BELNR AND CAST([Line item nr (new GL)] AS INT) = CAST(BUZEI AS INT)
										WHERE [D/C] = ''Credit'' and [Value (doc)] = DMBTR * -1 and [Value (doc)] <> 0'

		EXEC SP_EXECUTESQL @QUERY = @SQLCMD, @PARAMS = N'@multiplier FLOAT OUTPUT', @multiplier = @multiplier OUTPUT
		SET @multiplier = ISNULL(@multiplier, 1)

		EXEC SP_DROPTABLE 'B30_GPW_AP_INPUT'
		SET @SQLCMD = '
		SELECT * 
		INTO B30_GPW_AP_INPUT
		FROM ' + @database_name + '.DBO.[_CUBE_PTP-06-APA-lines]'
		EXEC SP_EXECUTESQL @SQLCMD

		-- from B30_GPW_AP_INPUT, import to final result table
		INSERT INTO DIVA_MASTER_SCRIPT..B30_01_IT_BSAK_BSIK_AP_ACC_SCH(B11_T001_BUTXT,B11_BSAIK_BUKRS, B11_BSAIK_GJAHR,
		B11_BSAIK_BELNR, B11_BSAIK_BUZEI, B11_BSAIK_LIFNR, LFA1_NAME1,
		B11_BSAIK_BLART, B11_T003T_LTEXT,
		B11_BSAIK_BSCHL, B11_TBSLT_LTEXT,
		B11_BSAIK_SHKZG, T001_WAERS,
		B11_ZF_BSAIK_DMBTR_S, B11_GLOBALS_CURRENCY,
		B11_ZF_BSAIK_DMBTR_S_CUC, B11_BSAIK_HKONT,
		SKAT_TXT50, B11_BSAIK_BUDAT,
		B11_ZF_FLAG_SUMMARY, SPCAT_SPEND_CAT_LEVEL_1,
		SPCAT_SPEND_CAT_LEVEL_2,SPCAT_SPEND_CAT_LEVEL_3,
        SPCAT_SPEND_CAT_LEVEL_4, [LFA1_LAND1], B11_BSAIK_BLDAT, ZF_DATABASE_FLAG, ZF_COMMENT_LOG)
		SELECT  	
				[Company name] B11_T001_BUTXT,
				[Company code] B11_BSAIK_BUKRS,
				[Fiscal year] B11_BSAIK_GJAHR,
				[Document nr] B11_BSAIK_BELNR,
				[Line item nr (new GL)] B11_BSAIK_BUZEI,
				[Supplier nr] B11_BSAIK_LIFNR,
				[Supplier name] LFA1_NAME1,
				[Document type] B11_BSAIK_BLART,
				[Document type text] B11_T003T_LTEXT,
				[Posting key] B11_BSAIK_BSCHL,
				[Posting key text] B11_TBSLT_LTEXT,
				IIF(@multiplier = -1, IIF([D/C] = 'Credit', 'S', 'H'), IIF([D/C] = 'Debit', 'S', 'H')) B11_BSAIK_SHKZG,
				[Currency (cc)] T001_WAERS,
				[Value (cc)] * @multiplier B11_ZF_BSAIK_DMBTR_S,
				[Z_Currency (custom)] B11_GLOBALS_CURRENCY,
				[Z_Value (custom)] * @multiplier B11_ZF_BSAIK_DMBTR_S_CUC,
				[G/L account] B11_BSAIK_HKONT,
				[G/L account text] SKAT_TXT50,
				[Document date] B11_BSAIK_BUDAT,
				[Z_Bucket - invoice] B11_ZF_FLAG_SUMMARY,
				[Z_Spend category level 1] AS SPCAT_SPEND_CAT_LEVEL_1,
				[Z_Spend category level 2] AS SPCAT_SPEND_CAT_LEVEL_2,
				[Z_Spend category level 3] AS SPCAT_SPEND_CAT_LEVEL_3,
				'' AS SPCAT_SPEND_CAT_LEVEL_4,
				[Supplier country] [LFA1_LAND1],
				[Posting date] B11_BSAIK_BLDAT,
				@database_name,
				IIF(@multiplier = -1, 'FLIPPED', 'NORMAL')
		FROM B30_GPW_AP_INPUT
		
		LEFT JOIN DIVA_MASTER_SCRIPT..B30_01_IT_BSAK_BSIK_AP_ACC_SCH B ON [Company code] = B.B11_BSAIK_BUKRS
                                                                            AND [Fiscal year] = B.B11_BSAIK_GJAHR 
																			AND [Document nr] = B.B11_BSAIK_BELNR
                                                                            AND [Line item nr (new GL)] = B.B11_BSAIK_BUZEI
		WHERE  B.B11_BSAIK_BUZEI IS NULL -- only import if documents are not in result tables. (duplication removal)
		-- only get transactions that relevant to supplier list
				AND  EXISTS (SELECT *
					FROM DIVA_MASTER_SCRIPT..AM_LIST_SUPPLIER
					WHERE RIGHT(CONCAT('0000000000', LIFNR), 10) = RIGHT(CONCAT('0000000000', [Supplier nr]), 10)
					AND @database_name LIKE '%' + AM_LIST_SUPPLIER.Region + '%')
	END 
GO
