USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROCEDURE [dbo].[script_B31_GPW_BSAIK_ECC_SPEND_CAT_LEVEL3](@database_name NVARCHAR(1000))
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START

--declare @database_name NVARCHAR(1000) = 'USCULCAASQL03.DIVA_APAC'
	PRINT @database_name
	DECLARE @DATABASE NVARCHAR(100) = @database_name+'.DBO.';

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

-- Step 2: if database has required tables and fields, start importing data to B31_GPW_AP_INPUT table
	IF @RESULT = 1
	BEGIN 
	   /*
		SET @SQLCMD = 'SELECT TOP 1 @multiplier = -1 FROM  ' + @database_name + '.DBO.[_CUBE_PTP-06-APA-lines] ' +'
										INNER JOIN ' + @database_name + '.DBO.BSEG ON [Company code] = BUKRS AND [Fiscal year] = GJAHR AND [Document nr]  = BELNR AND CAST([Line item nr (new GL)] AS INT) = CAST(BUZEI AS INT)
										WHERE [D/C] = ''Credit'' and [Value (doc)] = DMBTR * -1 and [Value (doc)] <> 0'

		EXEC SP_EXECUTESQL @QUERY = @SQLCMD, @PARAMS = N'@multiplier FLOAT OUTPUT', @multiplier = @multiplier OUTPUT
		SET @multiplier = ISNULL(@multiplier, 1)
		
		EXEC SP_DROPTABLE 'B31_GPW_AP_INPUT'
		SET @SQLCMD = '
		SELECT 
			A.*, 
			CONVERT(money,B.DMBE2 * (CASE WHEN B.SHKZG = ''S'' THEN 1 ELSE -1 END) * ISNULL(TCURX_CC.factor,1))	AS DMBE2
			, C.HWAE2
		INTO B31_GPW_AP_INPUT
		FROM ' + @database_name + '.DBO.[_CUBE_PTP-06-APA-lines] AS A
		INNER JOIN ' + @database_name + '.DBO.BSEG AS B
		ON A.[Document nr] = B.BELNR AND A.[Company code] = B.BUKRS AND A.[Fiscal year] = B.GJAHR
		AND A.[Line item nr (old GL)] = B.BUZEI
		INNER JOIN '+ @database_name + '.DBO.BKPF AS C ON B.BELNR = C.BELNR AND B.GJAHR = C.GJAHR AND B.BUKRS = C.BUKRS
		LEFT JOIN ' + @database_name + '.DBO.xxTCURX TCURX_CC
		ON	C.MANDT = TCURX_CC.MANDT AND
			C.HWAE2 = TCURX_CC.CURRKEY
		WHERE  EXISTS   
				(
					(
						SELECT TOP 1 1
						FROM DIVA_MASTER_SCRIPT..AM_SPEND_LEVEL3_SUPPLIER
						WHERE 
							[Z_Spend category level 3] = SPCAT_SPEND_CAT_LEVEL_3			
					)     )'
		EXEC SP_EXECUTESQL @SQLCMD*/
		-- from B31_GPW_AP_INPUT, import to final result table
		INSERT INTO DIVA_MASTER_SCRIPT..B31_01_IT_AP_SPEND_LEVEL3
		(
			 ZF_REMOVE_DUP_AP_SIDE,
			 B11_T001_BUTXT,
			 B11_BSAIK_MANDT,
			 B11_BSAIK_BUKRS, 
			 B11_BSAIK_GJAHR,
			 B11_BSAIK_BELNR, 
			 B11_BSAIK_BUZEI, 
			 B11_BSAIK_LIFNR, 
			 LFA1_NAME1,
			 B11_BSAIK_BLART, 
			 B11_T003T_LTEXT,
			 B11_BSAIK_BSCHL, 
			 B11_TBSLT_LTEXT,
			 B11_BSAIK_SHKZG, 
			 T001_WAERS,
			 B11_ZF_BSAIK_DMBTR_S,
			 B11_GLOBALS_CURRENCY,
			 B11_ZF_BSAIK_DMBTR_S_CUC, 
			 B11_BSAIK_HKONT,
			 SKAT_TXT50, 
			 B11_BSAIK_BUDAT,
			 B11_ZF_FLAG_SUMMARY,
			 [LFA1_LAND1], 
			 B11_BSAIK_BLDAT, 
			 ZF_DATABASE_FLAG, 
			 ZF_COMMENT_LOG,
			 B11_ZF_BSAIK_DMBE2_S,
			 ZF_BKPF_HWAE2
			 )
		SELECT  	
		        [Document nr]+[Company code]+[Fiscal year]+[Line item nr (new GL)] as ZF_REMOVE_DUP_AP_SIDE,
				[Company name] B11_T001_BUTXT,
				[Mandant] B11_BSAIK_MANDT,
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
				[Supplier country] [LFA1_LAND1],
				[Posting date] B11_BSAIK_BLDAT,
				@database_name,
				IIF(@multiplier = -1, 'FLIPPED', 'NORMAL'),
				DMBE2,
				HWAE2
		FROM B31_GPW_AP_INPUT
			INNER JOIN 
			(
				-- List of BELNR from GL table have SPEND LEVEL 3 found in AM_LIST_SPEND_CAT_LEVEL3
				SELECT 
					DISTINCT 
						[Document nr] as B12_GL_BSEG_BELNR, 
						[Company code] as B12_GL_BSEG_BUKRS,
						[Fiscal year] as B12_GL_BSEG_GJAHR
				FROM B31_GPW_AP_INPUT 
				WHERE  EXISTS   
				(
					(
						SELECT TOP 1 1
						FROM DIVA_MASTER_SCRIPT..AM_SPEND_LEVEL3_SUPPLIER
						WHERE 
							dbo.REMOVE_LEADING_ZEROES([Z_Spend category level 3]) = dbo.REMOVE_LEADING_ZEROES(SPCAT_SPEND_CAT_LEVEL_3) AND 
							@DATABASE LIKE '%' + AM_SPEND_LEVEL3_SUPPLIER.ZF_DATABASE_NAME + '%'					
					)     
				)
			) AS B ON [Document nr] = B.B12_GL_BSEG_BELNR   
					AND [Company code] = B.B12_GL_BSEG_BUKRS  
					AND [Fiscal year] = B.B12_GL_BSEG_GJAHR
			-- Remove duplication same region.
			WHERE [Document nr]+[Company code]+[Fiscal year]+[Line item nr (new GL)] NOT IN 
			( 
				SELECT DISTINCT ZF_REMOVE_DUP_AP_SIDE
				FROM DIVA_MASTER_SCRIPT..B31_01_IT_AP_SPEND_LEVEL3
					-- Region inserted (same region).
				INNER JOIN DIVA_MASTER_SCRIPT..AM_SPEND_LEVEL3_SUPPLIER
				ON B31_01_IT_AP_SPEND_LEVEL3.ZF_DATABASE_FLAG = AM_SPEND_LEVEL3_SUPPLIER.ZF_DATABASE_NAME	
			)
			-- Some filter in PTP app from GPW database. (See in data load editor PTP present app).
			and [Z_Posted in period] = 'x'
			and [Z_Bucket - financial] = 'Normal'


-- Step 2 :  Insert value to GL  table. (AP in GPW).
-- For GPW database pie chart from AP side.
	INSERT INTO DIVA_MASTER_SCRIPT..B31_02_IT_GL_SPEND_LEVEL3
	(
		ZF_REMOVE_DUP_GL_SIDE,
		B12_GL_BSEG_BUKRS,
		B12_GL_BSEG_GJAHR ,
		B12_GL_BSEG_BELNR ,
		B12_GL_BSEG_BUZEI,
		B12_GL_BSEG_KOART ,
		B12_GL_ZF_BSEG_DMBTR_S  ,
		B12_GL_ZF_BSEG_DMBE2_S  ,
		B12_GL_ZF_BSEG_DMBE3_S  ,
		B12_GL_ZF_BSEG_DMBTR_S_CUC ,
		B12_GL_SPCAT_SPEND_CAT_LEVEL_1 ,
		B12_GL_SPCAT_SPEND_CAT_LEVEL_2 ,
		B12_GL_SPCAT_SPEND_CAT_LEVEL_3 ,
		B12_GL_SPCAT_SPEND_CAT_LEVEL_4 ,
		B12_GL_BSEG_SHKZG,
		B12_GL_BSEG_HKONT  ,
		B12_GL_SKAT_TXT50 ,
		B12_GL_AM_GLOBALS_CURRENCY,
		GL_ZF_DATABASE_FLAG
	)
	SELECT  	
		    [Document nr]+[Company code]+[Fiscal year]+[Line item nr (new GL)] ,
			[Company code],
			[Fiscal year] ,
			[Document nr] ,
			[Line item nr (new GL)] ,
			'S' ,
			[Value (cc)] * @multiplier ,
			0,
			0,
			[Z_Value (custom)] * @multiplier,
			[Z_Spend category level 1] ,
			[Z_Spend category level 2] ,
			[Z_Spend category level 3] ,
			'' ,
			IIF(@multiplier = -1, IIF([D/C] = 'Credit', 'S', 'H'), IIF([D/C] = 'Debit', 'S', 'H')) B11_BSAIK_SHKZG,
			[G/L account] B11_BSAIK_HKONT,
			[G/L account text] SKAT_TXT50,
			[Z_Currency (custom)] as B12_GL_AM_GLOBALS_CURRENCY,
			@database_name
	FROM B31_GPW_AP_INPUT
	INNER JOIN DIVA_MASTER_SCRIPT..AM_SPEND_LEVEL3_SUPPLIER AS C
	ON dbo.REMOVE_LEADING_ZEROES([Z_Spend category level 3]) = dbo.REMOVE_LEADING_ZEROES(C.SPCAT_SPEND_CAT_LEVEL_3) AND
		@DATABASE LIKE '%' + C.ZF_DATABASE_NAME + '%'


		--(
		--	-- List of BELNR from GL table have SPEND LEVEL 3 found in AM_LIST_SPEND_CAT_LEVEL3
		--	SELECT 
		--		DISTINCT 
		--			[Document nr] as B12_GL_BSEG_BELNR, 
		--			[Company code] as B12_GL_BSEG_BUKRS,
		--			[Fiscal year] as B12_GL_BSEG_GJAHR,
		--			[Line item nr (new GL)] as B12_GL_BSEG_BUZEI
		--	FROM B31_GPW_AP_INPUT 
		--	WHERE  EXISTS   
		--	(
		--		(
		--			SELECT TOP 1 1
		--			FROM DIVA_MASTER_SCRIPT..AM_LIST_SPEND_CAT_LEVEL3
		--			WHERE 
		--			B31_GPW_AP_INPUT.[Z_Spend category level 3]  LIKE '%' +  AM_LIST_SPEND_CAT_LEVEL3.SPEND_CAT_LEVEL3 + '%'
		--			AND @database_name LIKE '%' + AM_LIST_SPEND_CAT_LEVEL3.[Database] + '%'							
		--		)     
		--	)
		--)  AS B ON [Document nr] = B.B12_GL_BSEG_BELNR   
		--			AND [Company code] = B.B12_GL_BSEG_BUKRS  
		--			AND [Fiscal year] = B.B12_GL_BSEG_GJAHR
		--			AND [Line item nr (new GL)] =  B.B12_GL_BSEG_BUZEI

		-- Remove duplication same region.
		WHERE [Document nr]+[Company code]+[Fiscal year]+[Line item nr (new GL)] NOT IN 
		( 
				SELECT DISTINCT ZF_REMOVE_DUP_GL_SIDE
				FROM DIVA_MASTER_SCRIPT..B31_02_IT_GL_SPEND_LEVEL3
					-- Region inserted (same region).
				INNER JOIN DIVA_MASTER_SCRIPT..AM_SPEND_LEVEL3_SUPPLIER
				ON B31_02_IT_GL_SPEND_LEVEL3.GL_ZF_DATABASE_FLAG = AM_SPEND_LEVEL3_SUPPLIER.ZF_DATABASE_NAME	
		)
		-- Some filter in PTP app from GPW database. (See in data load editor PTP present app).
		and [Z_Posted in period] = 'x'
		and [Z_Bucket - financial] = 'Normal'









END 
GO
