USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PM_PROCESS_MINING] @DBNAME NVARCHAR(MAX)
AS
--This script used to run both PTP then OTC,

--Final step is flag the SOD user in PTP and OTC
-- Thuan check if database exist MATDOC table or not
DECLARE @ZF_MATDOC_FLAG BIT;
DECLARE @sql NVARCHAR(MAX);

SET @sql = 'IF EXISTS (SELECT * FROM ' + @DBNAME + '.sys.tables WHERE name = ''A_MATDOC'')
            SET @ZF_MATDOC_FLAG = 1;
        ELSE
            SET @ZF_MATDOC_FLAG = 0;';

EXEC sp_executesql @sql, N'@ZF_MATDOC_FLAG BIT OUTPUT', @ZF_MATDOC_FLAG OUTPUT;


	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'PM%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'B26_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'B24_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME,  'B11_SS02_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME,   'TEMP%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME,   '%_TT_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME,  'TT_%'
----Material movement cube(Good receipt and Good issue)
	IF @ZF_MATDOC_FLAG=1
		EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B26_MATERIAL_MOVEMENT_CUBE_MATDOC'
	ELSE
		EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B26_MATERIAL_MOVEMENT_CUBE'

	EXEC SP_REMOVE_TABLES_MASTER @DBNAME,   'TEMP%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME,   '%_TT_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME,  'TT_%'

----Script for PTP
	EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B24_CHANGE_CUBE_V2'
	EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B25_PTP_PURCHASE_REQUEST'
	EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B09_SS02_ADD_USER_PO'
	EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B11_SS02_ADD_USER_INV_PAY'
	EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B27A_BSEG_BKPF_INVOICES'

	IF @ZF_MATDOC_FLAG=1
		BEGIN
			EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B27_PTP_GLOBAL_CUBES_MATDOC'
			EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_PM01_PROCESS_MINING_NEW_MATDOC'
		END
	ELSE
		BEGIN
			EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B27_PTP_GLOBAL_CUBES'
			EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_PM01_PROCESS_MINING_NEW'
		END

--Script for OTC
	EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B00_SS02_OTC_INFO_TABLE'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME,   'B14_SS01_%' -- Need to remove B14_SS01 before we run B14_SS01 cube. Thuan updated 2024-01-30
	EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B14_SS01_INVOICE_PAYMENT_CUBE'
	EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B24_SS01_OTC_PROCESS_MINING_CHANGE'

	EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B30_INVOICE_DOCS'

	EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B28_SALE_ORDER_CUBE'

	EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B29_DELIVERY_CUBE'

	EXEC SP_REMOVE_TABLES_MASTER @DBNAME,   'TEMP%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME,   '%_TT_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME,  'TT_%'
	IF @ZF_MATDOC_FLAG=1
		BEGIN
			EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B31_OTC_GLOBAL_TABLE_MATDOC'
			EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_PM02_OTC_PROCESS_MINING_MATDOC'
		END
	ELSE
		BEGIN
			EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_B31_OTC_GLOBAL_TABLE'
			EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_PM02_OTC_PROCESS_MINING'
		END


--SOD user flag script (Flag the user who did SOD in both PTP and OTC)
EXEC SP_EXEC_DYNAMIC @DBNAME, 'script_PM03_FLAG_USER_PTP_OTC'



GO
