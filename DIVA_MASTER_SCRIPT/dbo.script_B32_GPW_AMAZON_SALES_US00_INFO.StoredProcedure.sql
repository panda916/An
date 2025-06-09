USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROCEDURE [dbo].[script_B32_GPW_AMAZON_SALES_US00_INFO](@database_name NVARCHAR(1000))
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START

--declare @database_name NVARCHAR(1000) = 'USCULCAASQL03.DIVA_APAC'
	PRINT @database_name

-- Step 1: check if target database has required field and tables.

	DECLARE @SQLCMD NVARCHAR(1000) ='SELECT TOP 1 @RESULT = 1 FROM ' + @database_name + '.DBO.[_CUBE_OTC-07-COPA-SNA-transactions]'
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
	
	EXEC SP_DROPTABLE 'B32_GPW_COPA_TRAN_SNA'
	SET @SQLCMD = 
	'
		SELECT  A.*, WAERS
			INTO B32_GPW_COPA_TRAN_SNA 
		FROM ' + @database_name + '.DBO.[_CUBE_OTC-07-COPA-SNA-transactions] A
		LEFT JOIN ' + @database_name + '.DBO.T001 ON [Company code] = BUKRS
		WHERE  	EXISTS (
						(
											SELECT  TOP 1 1 
											FROM DIVA_MASTER_SCRIPT..AM_AMAZON_SALE_DATA
											WHERE DBO.REMOVE_LEADING_ZEROES(A.Customer) = dbo.REMOVE_LEADING_ZEROES(DIVA_MASTER_SCRIPT..AM_AMAZON_SALE_DATA.Customer)
											
				
						)     
				)
		
	'
	EXEC SP_EXECUTESQL @SQLCMD
	
	INSERT INTO DIVA_MASTER_SCRIPT..B32_01_IT_COPA_CUBE
	SELECT 
		Mandant, -- Client
		[Company code], -- Company code.
		[Fiscal year], -- Fiscal year.
		[Document nr], -- Document number
		[Item nr], -- Line item.
		 WAERS, -- Company currency. 
		[Z_Currency (custom)], -- Custom currency.
		[Z_Posted in period], -- COPA_BUDAT between date1, date2.
		'',
		'', -- Value coc.
		'', -- Value cuc.
		[Sales organization], -- Sales organization.
		[Distribution channel], -- Distribution channel.
		[Sales order], -- Sale order number.
		[Billing type], -- Billing type.
		[Division], -- Division.
		[Customer], -- Customer.
		[Material], -- Product.
		[Z_Fiscal year-quarter] ,
		[Z_Calendar year-month],
		[Z_Tokyo 6 digit],
		[Z_Product hierarchy L1],
		[Z_Product hierarchy L2],
		[Z_Product hierarchy L3],
		[Z_Product hierarchy L4],
		[Z_Product hierarchy L5],
		[Posting date],
		[Profit center],
		[Controlling area],
		[Sender cost center],
		[Trading partner],
		[Trading partner name],
		[Record type],
		[Sales quantity],
		[Sales order item],
		[Reference document],
		[Reference item nr],
		-- Some amount fields only appear in S4.
		0,
		0,
		'' ,
		'',
		'',
		[Z_Gross sales],
		[Z_Sales reductions],
		[Z_Net sales],
		[Z_COGS],
		[Z_Marginal cost],
		[Z_GP],
		[Z_Gross sales (custom)],
		[Z_Sales reductions (custom)],
		[Z_Net sales (custom)],
		[Z_COGS (custom)],
		[Z_Marginal cost (custom)],
		[Z_GP (custom)],
		[Ship-to party name] + ' - ' + [Ship-to party],
		[Bill-to party name] + ' - ' + [Bill-to party],
		[Strategic account] + ' - ' + [Strategic account name],
		[Trading partner] + ' - ' + [Trading partner name],
		[Z_Tokyo 8 digit],
		[Tokyo 4 digit],
		[M_Sales region],
		'',
		'',
		'GPW' as ZF_ECC_S4_FLAG,
		 RIGHT(@database_name,LEN(@database_name) - 14)  as ZF_DATABASE_FLAG
	FROM B32_GPW_COPA_TRAN_SNA A
	-- Remove dup same region 
	LEFT JOIN DIVA_MASTER_SCRIPT..B32_01_IT_COPA_CUBE C ON A.[Company code] = C.B32_COPA_BUKRS
																							AND A.[Fiscal year] = C.B32_COPA_GJAHR 
																							AND A.[Document nr] = C.B32_COPA_BELNR
																						   AND A.[Item nr] = C.B32_COPA_POSNR

	WHERE C.B32_COPA_POSNR IS NULL
	AND 
    EXISTS ((
							SELECT TOP 1 1 
									FROM DIVA_MASTER_SCRIPT..AM_AMAZON_SALE_DATA
									WHERE DBO.REMOVE_LEADING_ZEROES(A.Customer) = dbo.REMOVE_LEADING_ZEROES(DIVA_MASTER_SCRIPT..AM_AMAZON_SALE_DATA.Customer)
									AND @database_name LIKE '%' + Entity + '%'
								--	AND DIVA_MASTER_SCRIPT..AM_AMAZON_SALE_DATA.Customer LIKE '%0600016750%'
				
				)     
			)


-- Step 2 : Insert value for B32_02_IT_COMPANY_INFO table.

INSERT INTO DIVA_MASTER_SCRIPT..B32_02_IT_COMPANY_INFO
SELECT 
	DISTINCT 
	[Company code],
	[Company name],
	WAERS,
	[Company code]+' - '+[Company name] 	
	FROM B32_GPW_COPA_TRAN_SNA A
WHERE 
-- Remove dup same region
NOT EXISTS
	(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_02_IT_COMPANY_INFO B
		WHERE B.B32_T001_BUKRS = A.[Company code]
	)


-- Step 3/ Insert value for B32_03_IT_CUSTOMER_INFO table.  

INSERT INTO DIVA_MASTER_SCRIPT..B32_03_IT_CUSTOMER_INFO
SELECT 
	DISTINCT 
		[Customer],
		[Customer name],
		[Account group],
		[Industry code 1] + ' - ' + [Industry code text 1],
		[Industry code 2] + ' - ' + [Industry code text 2],
		[Industry code 3] + ' - ' + [Industry code text 3],
		[Industry code 4] + ' - ' + [Industry code text 4],
		[Industry code 5] + ' - ' + [Industry code text 5],
		[Customer] + ' - ' +  [Customer name],
		CASE 
			WHEN ( [Z_Intercompany] is null or [Z_Intercompany] = '') 
				THEN 'Unknown' 
			ELSE 
				[Z_Intercompany]
		END as [Z_Intercompany],
		[Account group text]
FROM    B32_GPW_COPA_TRAN_SNA A
WHERE 
-- Remove dup same region
NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_03_IT_CUSTOMER_INFO B
		WHERE B.B32_KNA1_KUNNR = A.[Customer]
)


-- Step 4 : Insert value for B32_04_IT_MATERIAL_INFO table.

INSERT INTO DIVA_MASTER_SCRIPT..B32_04_IT_MATERIAL_INFO
SELECT 
	DISTINCT 
		[Mandant],
		[Material], -- Material number
		[Material text], -- Material description.
		[Material group], -- Material Group.
		[Material group text], -- Material group description.
		[Material type], -- Material type,
		[Material type text], -- Material type description.
		[Material]+[Company code]+[Fiscal year]+[Document nr]+[Item nr]+RIGHT(@database_name,LEN(@database_name) - 14)

FROM  B32_GPW_COPA_TRAN_SNA A
-- Remove dup same region
WHERE NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_04_IT_MATERIAL_INFO B
		WHERE B.B32_MAKT_MATNR = A.[Material]
)

-- Step 5 : Insert value for B32_05_IT_SALE_ORG_INFO table.

INSERT INTO DIVA_MASTER_SCRIPT..B32_05_IT_SALE_ORG_INFO
SELECT 
	DISTINCT 
		[Sales organization], -- Sales Organization
		[Sales organization name] -- Sales Organization name.
		
FROM  B32_GPW_COPA_TRAN_SNA A
WHERE 
-- Remove dup same region
NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_05_IT_SALE_ORG_INFO B
		WHERE B.B32_TVKOT_VKORG = A.[Sales organization]
)


-- Step 6 : Insert value for B32_06_IT_DISTRIBUTION_INFO table.

INSERT INTO DIVA_MASTER_SCRIPT..B32_06_IT_DISTRIBUTION_INFO
SELECT 
	DISTINCT 
		[Distribution channel], -- Distribution Channel
		[Distribution channel text] -- Distribution Channel name.
		
FROM  B32_GPW_COPA_TRAN_SNA A
WHERE 
-- Remove dup same region
NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_06_IT_DISTRIBUTION_INFO B
		WHERE B.B32_TVTWT_VTWEG = A.[Distribution channel]
)

-- Step 7 : Insert value for B32_07_IT_DIVISION_INFO table.

INSERT INTO DIVA_MASTER_SCRIPT..B32_07_IT_DIVISION_INFO
SELECT 
	DISTINCT 
		[Division], -- Division
		[Division text] -- Division name.		
FROM  B32_GPW_COPA_TRAN_SNA A
WHERE 
-- Remove dup same region
NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_07_IT_DIVISION_INFO B
		WHERE B.B32_TSPAT_SPART = A.[Division]
)

-- Step 8 : Insert value for B32_08_IT_BILL_DOC_TYPE_INFO table.

INSERT INTO DIVA_MASTER_SCRIPT..B32_08_IT_BILL_DOC_TYPE_INFO
SELECT 
	DISTINCT 
		[Billing type] , -- Billing Type
		[Billing type text] -- Billing Type name.
		
FROM  B32_GPW_COPA_TRAN_SNA A
WHERE 
-- Remove dup same region
NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_08_IT_BILL_DOC_TYPE_INFO B
		WHERE B.B32_TVFKT_FKART = A.[Billing type]
)

-- Step 9 : Insert value for B32_09_IT_SALE_DOC_TYPE_INFO table.
INSERT INTO DIVA_MASTER_SCRIPT..B32_09_IT_SALE_DOC_TYPE_INFO
SELECT 
	DISTINCT 
		[Sales order] , -- Sale document number
		[Sales organization],  -- Sales Organization
		[Sales document type], -- Sale document type.
		[Order reason], -- Order reason. 
		[Sales document type text], -- Sale document type text.
		[Order reason text], -- Order reason text.
		[Sales order]+[Sales organization]+[Company code]+[Fiscal year]+[Document nr]+[Item nr]+RIGHT(@database_name,LEN(@database_name) - 14)
FROM  B32_GPW_COPA_TRAN_SNA A
WHERE 
-- Remove dup same region
NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_09_IT_SALE_DOC_TYPE_INFO B
		WHERE B.B32_VBAK_VBELN = A.[Sales order]
)

-- Step 10 : Insert value for B32_10_IT_PROFIT_CENTER_INFO table.
INSERT INTO DIVA_MASTER_SCRIPT..B32_10_IT_PROFIT_CENTER_INFO
SELECT 
	DISTINCT 
		[Profit center] , -- Profit center.
		[Profit center name],  -- Profit center desc.	
		[Controlling area]
FROM  B32_GPW_COPA_TRAN_SNA A
WHERE 
-- Remove dup same region
NOT EXISTS 
(
		SELECT TOP 1 1 FROM DIVA_MASTER_SCRIPT..B32_10_IT_PROFIT_CENTER_INFO B
		WHERE B.B32_CEPCT_PRCTR = A.[Profit center]
)

-- Step 11 : Insert value for B32_11_IT_COST_CENTER_INFO table.
-- GPW i can't find cost center field in SQL and Qliksense. 


drop table B32_GPW_COPA_TRAN_SNA

END

GO
