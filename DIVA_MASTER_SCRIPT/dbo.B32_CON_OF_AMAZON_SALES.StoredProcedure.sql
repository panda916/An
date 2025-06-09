USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[B32_CON_OF_AMAZON_SALES]
AS

-- Step 1 : Create table from COPA cube combine S4 and ECC systems.
-- And some related tables.
-- Step 1.1/ Create table from COPA cube combine S4 and ECC systems.

EXEC SP_REMOVE_TABLES 'B32_01_IT_COPA_CUBE'

CREATE TABLE [B32_01_IT_COPA_CUBE]
(
	B32_COPA_MANDT nvarchar(10), -- Client.
	B32_COPA_BUKRS nvarchar(10), -- Company code
	B32_COPA_GJAHR nvarchar(10), -- Fiscal year.
	B32_COPA_BELNR nvarchar(20), -- Document number.
	B32_COPA_POSNR nvarchar(20), -- Line items.
	B32_COPA_WAERS_COC nvarchar(10), -- Company currency.
	B32_COPA_WAERS_CUC nvarchar(10), -- Custom currency USD.
	B32_ZF_BUDAT_POSTED_IN_PER_FLAG varchar(1), -- Budat date between date1 and date 2.
	B32_COMA_M_Hierarchy_L1 nvarchar(255), -- Hierarchy l1.
	B32_ZF_COPA_FIELD_VALUE_COC float, -- Amount company currency.
	B32_ZF_COPA_FIELD_VALUE_CUC float, -- Amount USD.
	B32_COPA_VKORG nvarchar(10), -- Sale organization.
	B32_COPA_VTWEG nvarchar(10), -- Distribution channel.
	B32_COPA_KAUFN nvarchar(20), -- Sale order number.
	B32_COPA_FKART nvarchar(20), -- Bliing type.
	B32_COPA_SPART nvarchar(20), -- Divison.
	B32_COPA_KNDNR nvarchar(12), -- Customer.
	B32_COPA_ARTNR nvarchar(20), -- Product number.
	B32_ZF_GJAHR_PERDE_FISCAL_YQ nvarchar(10), -- Quarter.
	B32_ZF_BUDAT_CALENDAR_YM nvarchar(10), -- Filter calendar year month.
	B32_ZF_TOKYO_6_DIGIT nvarchar(100), 
	B32_ZF_COPA_PROD_L1 nvarchar(100), 
	B32_ZF_COPA_PROD_L2 nvarchar(100),  
	B32_ZF_COPA_PROD_L3 nvarchar(100),  
    B32_ZF_COPA_PROD_L4 nvarchar(100), 
    B32_ZF_COPA_PROD_L5 nvarchar(100), 
	B32_ZF_COPA_BUDAT date,
	B32_COPA_PRCTR nvarchar(12), -- Profit center.
	B32_COPA_KOKRS nvarchar(10), --	Controlling Area
	B32_COPA_SKOST nvarchar(20), -- Cost center
	B32_ZF_TRADING_PARTNER varchar(1), -- Trading partner.
	B32_ZF_TRADING_PARTNER_NAME  varchar(1), -- Trading partner name.
	B32_COPA_VRGAR nvarchar(3),  -- Record type.
	B32_COPA_ABSMG float, -- Quantity
	B32_COPA_KDPOS nvarchar(20), -- Sales order item nr
	B32_COPA_RBELN nvarchar(20), -- Billing document number
	B32_COPA_RPOSN nvarchar(100), -- Billing document item number.
	B32_ZF_ACDOCA_KSL_S float, -- KSL amount ( Only appear in S4 system)
	B32_ZF_ACDOCA_OSL_S float, -- OSL amount ( Only appear in S4 system).
	B32_COPA_LINE_FLAG nvarchar(2),
	B32_ACDOCA_RKCUR nvarchar(20),
	B32_ACDOCA_ROCUR nvarchar(20),
	B32_ZF_GROSS_SALES FLOAT,
	B32_ZF_SALE_REDUCTION FLOAT,
	B32_ZF_NET_SALE FLOAT,
	B32_ZF_COGS FLOAT,
	B32_ZF_MARGINAL_COST FLOAT,
	B32_ZF_GP FLOAT,
	B32_ZF_GROSS_SALE_CUC FLOAT,
	B32_ZF_SALES_REDUCTION_CUC FLOAT,
	B32_ZF_NET_SALE_CUC FLOAT,
	B32_ZF_COGS_CUC FLOAT,
	B32_ZF_MARGINAL_COST_CUC FLOAT,
	B32_ZF_GP_CUC FLOAT,
	B32_ZF_GPW_SHIP_PARTY nvarchar(1000),
	B32_ZF_GPW_BILL_PARTY nvarchar(1000),
	B32_ZF_GPW_STRA_ACC nvarchar(1000),
	B32_ZF_GPW_TRADING_PARNER  nvarchar(1000),
	B32_ZF_GPW_8_DIGIT nvarchar(100),
	B32_ZF_GPW_SALE_REGION nvarchar(100),
	B32_ACDOCA_CO_BELNR nvarchar(20), -- COPA Document number. S4
	B32_ACDOCA_CO_BUZEI nvarchar(20), -- COPA Line items.     S4
	B32_ZF_ECC_S4_FLAG nvarchar(10), -- ECC or S4 system.
	B32_ZF_DATABASE_FLAG nvarchar(50) -- Database name.


)

-- Step 1.2/ Company code table for ECC and S4 systems.

EXEC SP_REMOVE_TABLES 'B32_02_IT_COMPANY_INFO'

CREATE TABLE [B32_02_IT_COMPANY_INFO]
(
	B32_T001_BUKRS nvarchar(10),
	B32_T001_BUTXT nvarchar(100),
	B32_T001_WAERS nvarchar(10),
	B32_ZF_T001_BUKRS_BUTXT nvarchar(100)

)

-- Step 1.3/ Customer table ( KNA1 and T077X tables).

EXEC SP_REMOVE_TABLES 'B32_03_IT_CUSTOMER_INFO'

CREATE TABLE [B32_03_IT_CUSTOMER_INFO]
(
	B32_KNA1_KUNNR nvarchar(20),
	B32_KNA1_NAME1 nvarchar(50),
    B32_KNA1_KTOKD nvarchar(50),
	B32_KNA1_BRAN1 nvarchar(50),
	B32_KNA1_BRAN2 nvarchar(50),
	B32_KNA1_BRAN3 nvarchar(50),
	B32_KNA1_BRAN4 nvarchar(50),
	B32_KNA1_BRAN5 nvarchar(50),
	B32_ZF_KNA1_KUNNR_NAME1 nvarchar(100),
	B32_ZF_T077X_INTERCO_TXT nvarchar(20),
	B32_ZF_T077X_TXT30 nvarchar(50)

)

-- 1.4 Material table.
EXEC SP_REMOVE_TABLES 'B32_04_IT_MATERIAL_INFO'

CREATE TABLE [B32_04_IT_MATERIAL_INFO]
(
		B32_MAKT_MANDT   nvarchar(100),
		B32_MAKT_MATNR  nvarchar(100), -- Material number
		B32_MAKT_MAKTX  nvarchar(100), -- Material description.
		B32_MARA_MATKL  nvarchar(100), -- Material Group.
		B32_T023T_WGBEZ nvarchar(100), -- Material group description.
		B32_MARA_MTART  nvarchar(100), -- Material type,
		B32_T134T_MTBEZ nvarchar(100), -- Material type description.
        B32_ZF_MATERIAL_KEY nvarchar(1000) -- Material key.
)

-- 1.5 Sale organization table.
EXEC SP_REMOVE_TABLES 'B32_05_IT_SALE_ORG_INFO'

CREATE TABLE [B32_05_IT_SALE_ORG_INFO]
(
		B32_TVKOT_VKORG   nvarchar(20), -- Sales Organization
		B32_TVKOT_VTEXT  nvarchar(100) -- Sales Organization name.
)

-- 1.6 Distribution table.

EXEC SP_REMOVE_TABLES 'B32_06_IT_DISTRIBUTION_INFO'

CREATE TABLE [B32_06_IT_DISTRIBUTION_INFO]
(
		B32_TVTWT_VTWEG   nvarchar(20), -- Distribution Channel
		B32_TVTWT_VTEXT  nvarchar(100) -- Distribution Channel name.
)

-- 1.7 Division table.

EXEC SP_REMOVE_TABLES 'B32_07_IT_DIVISION_INFO'

CREATE TABLE [B32_07_IT_DIVISION_INFO]
(
		B32_TSPAT_SPART   nvarchar(20), -- Division
		B32_TSPAT_VTEXT  nvarchar(100) -- Division name.
)

-- 1.8 Billing document type table.

EXEC SP_REMOVE_TABLES 'B32_08_IT_BILL_DOC_TYPE_INFO'

CREATE TABLE [B32_08_IT_BILL_DOC_TYPE_INFO]
(
		B32_TVFKT_FKART   nvarchar(20), -- Billing Type
		B32_TVFKT_VTEXT  nvarchar(100) -- Billing Type name.
)

--1.9 Sale document type table.

EXEC SP_REMOVE_TABLES 'B32_09_IT_SALE_DOC_TYPE_INFO'

CREATE TABLE [B32_09_IT_SALE_DOC_TYPE_INFO]
(
		B32_VBAK_VBELN  nvarchar(20), -- Sale document.
		B32_VBAK_VKORG  nvarchar(20), -- Sales Organization
		B32_VBAK_AUART  nvarchar(20), -- Sale document type.
		B32_VBAK_AUGRU  nvarchar(50) , -- Order reason.
		B32_TVAKT_BEZEI nvarchar(50) ,-- Sale document type text.
		B32_TVAUT_BEZEI nvarchar(50), -- Order reason text.
		B32_ZF_SALE_DOC_KEY nvarchar(1000) -- SALE_DOC_KEY.

)

--1.10 Profit center text.

EXEC SP_REMOVE_TABLES 'B32_10_IT_PROFIT_CENTER_INFO'

CREATE TABLE [B32_10_IT_PROFIT_CENTER_INFO]
(
		B32_CEPCT_PRCTR  nvarchar(20), -- Profit center.
		B32_CEPCT_LTEXT  nvarchar(100), -- Profit center desc.
		B32_CEPCT_KOKRS  nvarchar(100)
		
)


--1.11 Cost center text.

EXEC SP_REMOVE_TABLES 'B32_11_IT_COST_CENTER_INFO'

CREATE TABLE [B32_11_IT_COST_CENTER_INFO]
(
		B32_CSKT_KOSTL  nvarchar(20), -- Cost center.
		B32_CSKT_LTEXT  nvarchar(100), -- Cost center desc.
		B32_CSKT_KOKRS  nvarchar(100), --
		
)



-- Step 2/ Retrieve all databases in the system related to suppliers (Tomaz excel file).

-- Step 2.1 get a list of current database within current server and exist in AM_AMAZON_SALE_DATA table.
EXEC SP_REMOVE_TABLES 'z_databases'
--SELECT  DISTINCT database_name, crdate, AM_AMAZON_SALE_DATA.Entity
--into z_databases
--FROM
--(
--	SELECT DISTINCT db.[name] database_name,  crdate
--	--into z_databases
--		FROM master.dbo.sysdatabases db 
--	where sid <> 0x01 and  db.[name]  NOT LIKE '%PROCESS%'
--	UNION
--	SELECT DISTINCT  'USCULCAASQL03.' + database_name z_databases, crdate FROM 
--		(
--				SELECT database_name , crdate
--				FROM 
--				(
--					SELECT DISTINCT db.[name] database_name, *
--						FROM  USCULCAASQL03.master.dbo.sysdatabases db
--				) as A
--		) AS A
--) AS A, AM_AMAZON_SALE_DATA
--WHERE database_name LIKE CONCAT('%',AM_AMAZON_SALE_DATA.Entity, '%')  collate SQL_Latin1_General_CP1_CI_AS
--AND
--(
--    object_id (database_name + '..B18B_08_IT_COPA_HIERARCHY_VALUE') IS NOT NULL  -- COPA table in ECC system.
--	OR object_id (database_name + '..B18_04_IT_COPA_ACCOUNT_BASED') IS NOT NULL   -- COPA table in S4 system.
--	OR database_name LIKE 'USCULCAASQL03%'
--)



-- Step 2.2 scan through the list of databases and extract required data
DECLARE @database_name NVARCHAR(1000) = '';
DECLARE @SQL NVARCHAR(1000);

WHILE EXISTS(SELECT * FROM z_databases)
BEGIN
	SET @database_name = (SELECT TOP 1  database_name FROM z_databases ORDER BY Entity, crdate DESC)
	DELETE z_databases WHERE database_name = @database_name

		IF (@database_name LIKE 'USCULCAASQL03%')
			BEGIN
				EXEC script_B32_GPW_AMAZON_SALES_GB00_INFO @database_name
				EXEC script_B32_GPW_AMAZON_SALES_US00_INFO @database_name
				PRINT 'OK'
				
			END
		ELSE IF (not @database_name LIKE '%SIE%') AND (not @database_name LIKE '%SEV%')
			BEGIN
				EXEC SP_REMOVE_TABLES_MASTER @database_name, 'B32_%'
				EXEC SP_EXEC_DYNAMIC @database_name, 'script_B32_ECC_AMAZON_SALES_INFO'
			END
		ELSE
			BEGIN
				EXEC SP_REMOVE_TABLES_MASTER @database_name, 'B32_%'
				EXEC SP_EXEC_DYNAMIC @database_name, 'script_B32_S4_AMAZON_SALES_INFO'
			END
	

END


GO
