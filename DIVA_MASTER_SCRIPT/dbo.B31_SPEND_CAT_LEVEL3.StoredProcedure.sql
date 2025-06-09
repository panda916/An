USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROC [dbo].[B31_SPEND_CAT_LEVEL3]
AS

-- Step 1/ Create table store some information for suppliers from BSAK, BSIK tables (ECC system) or ACDOCA table ( S4 system)
EXEC sp_droptable 'B30_01_IT_BSAK_BSIK_AP_ACC_SCH'

CREATE TABLE [B30_01_IT_BSAK_BSIK_AP_ACC_SCH](
	B11_T001_BUTXT [nvarchar](50),
	[B11_BSAIK_MANDT] [nvarchar](50) ,
	[B11_BSAIK_BUKRS] [nvarchar](60) ,
	[B11_BSAIK_GJAHR] [nvarchar](60) ,
	[B11_BSAIK_BELNR] [nvarchar](120) ,
	[B11_BSAIK_BUZEI] [nvarchar](50) ,
	[B11_BSAIK_BSCHL] [nvarchar](40) ,
	[B11_BSAIK_SHKZG] [nvarchar](30) ,
	[B11_BSAIK_BLART] [nvarchar](40) ,
	[B11_BSAIK_LIFNR] [nvarchar](120) ,
	[B11_BSAIK_WAERS] [nvarchar](70) ,
	[B11_BSAIK_DMBTR] [money] ,
	[B11_BSAIK_UMSKS] [nvarchar](30) ,
	[B11_BSAIK_UMSKZ] [nvarchar](30) ,
	[B11_BSAIK_AUGDT] [date] ,
	[B11_BSAIK_AUGBL] [nvarchar](120) ,
	[B11_BSAIK_ZUONR] [nvarchar](200) ,
	[B11_BSAIK_BUDAT] [date] ,
	[B11_BSAIK_BLDAT] [date] ,
	[B11_BSAIK_CPUDT] [date] ,
	[B11_BSAIK_XBLNR] [nvarchar](180) ,
	[B11_BSAIK_MONAT] [nvarchar](40) ,
	[B11_BSAIK_GSBER] [nvarchar](60) ,
	[B11_BSAIK_WRBTR] [money] ,
	[B11_BSAIK_MWSKZ] [nvarchar](40) ,
	[B11_BSAIK_MWSTS] [money] ,
	[B11_BSAIK_WMWST] [money] ,
	[B11_BSAIK_SGTXT] [nvarchar](520) ,
	[B11_BSAIK_AUFNR] [nvarchar](140) ,
	[B11_BSAIK_EBELN] [nvarchar](120) ,
	[B11_BSAIK_EBELP] [nvarchar](70) ,
	[B11_BSAIK_HKONT] [nvarchar](120) ,
	[B11_BSAIK_ZFBDT] [date] ,
	[B11_BSAIK_ZTERM] [nvarchar](60) ,
	[B11_BSAIK_ZBD1T] [decimal](3, 0) ,
	[B11_BSAIK_ZBD2T] [decimal](3, 0) ,
	[B11_BSAIK_ZBD3T] [decimal](3, 0) ,
	[B11_BSAIK_ZBD1P] [decimal](5, 3) ,
	[B11_BSAIK_ZBD2P] [decimal](5, 3) ,
	[B11_BSAIK_SKFBT] [money] ,
	[B11_BSAIK_WSKTO] [money] ,
	[B11_BSAIK_ZLSCH] [nvarchar](30) ,
	[B11_BSAIK_ZLSPR] [nvarchar](30) ,
	[B11_BSAIK_BSTAT] [nvarchar](30) ,
	[B11_BSAIK_KOSTL] [nvarchar](120) ,
	[B11_BSAIK_AUGGJ] [nvarchar](60) ,
	B11_T003T_LTEXT [nvarchar](60) ,
	B11_TBSLT_LTEXT [nvarchar](60) ,
	B11_GLOBALS_CURRENCY [nvarchar](60) ,
	[B11_ZF_BSAIK_CPUDT_AGE_DAYS] [int] ,
	[B11_ZF_BSAIK_OPEN_CLOSED] [varchar](60)  ,
	[B11_ZF_BSAIK_SHKZG_DESC] [varchar](60)  ,
	[B11_ZF_BSAIK_SHKZG_INTEGER] [int]  ,
	[B11_ZF_BSAK_AUGDT_YEAR_MNTH] [varchar](70) ,
	[B11_ZF_BSAIK_WSKTO_SKBFT] [money] ,
	[B11_ZF_BSAIK_DMBTR_S] [money] ,
	[B11_ZF_BSAIK_DMBTR_S_CUC] [money] ,
	[B11_ZF_FLAG_SUMMARY] [nvarchar](70),
	[SPCAT_SPEND_CAT_LEVEL_3] [nvarchar](100),
	[BKPF_AWTYP] [nvarchar](70) ,
	[T001_WAERS] [nvarchar](70) ,
    [T001_KTOPL] [nvarchar](70) ,
	[LFA1_KTOKK] [nvarchar](60) ,
	[LFA1_NAME1] [nvarchar](370) ,
	[LFA1_LAND1] [nvarchar](370) ,
	[LFA1_KUNNR] [nvarchar](120) ,
	[T077Y_TXT30] [nvarchar](320) ,
	[SKAT_TXT20] [nvarchar](220) ,
	[SKAT_TXT50] [nvarchar](520) ,
	ZF_DATABASE_FLAG NVARCHAR(100),
	ZF_COMMENT_LOG VARCHAR(100)
)

-- Step 2/ Retrieve all databases in the system related to suppliers (Tomaz excel file).

-- Step 2.1 get a list of current database within current server
EXEC sp_droptable 'z_databases'

SELECT DISTINCT db.[name] database_name 
into z_databases
	FROM master.dbo.sysdatabases db
	INNER JOIN DIVA_MASTER_SCRIPT..AM_SPEND_CAT_LEVEL3 on db.name = DIVA_MASTER_SCRIPT..AM_SPEND_CAT_LEVEL3.[Database]
where sid <> 0x01 AND  
	-- Put some hard code to get database in SONY server.
	-- (db.name IN ('DIVA_SPNI_FY17_18_19_20Q3','DIVA_RUSSIA_FY19_20_FULL','DIVA_TURKEY_FY19_20Q3','DIVA_SOLA_FY19_20Q3', 'DIVA_SPE_FY21Q3') or db.name like '%SIE%' OR db.name LIKE '$SEV')
(db.name like '%SIE%' OR db.name LIKE '$SEV' or db.name like '%SCIS%' or db.name like '%SPE%' or db.name like '%SPNI%')
AND db.name NOT LIKE '%PROCESS%'
UNION
-- Get GPW database in SONY SERVER.
SELECT DISTINCT  'USCULCAASQL03.' + database_name z_databases FROM 
	(
			SELECT database_name 
			FROM 
			(
				SELECT DISTINCT db.[name] database_name
					FROM master.dbo.sysdatabases db
			) as a
	) AS A


-- Step 2.2 scan through the list of databases and extract required data
DECLARE @database_name NVARCHAR(1000) = '';
DECLARE @SQL NVARCHAR(1000);

WHILE EXISTS(SELECT  * FROM z_databases  )
BEGIN
	SET @database_name = (SELECT TOP 1  database_name FROM z_databases  ORDER BY database_name DESC)
	DELETE z_databases WHERE database_name = @database_name

	IF object_id (@database_name + '..B12_02_IT_PTP_AP') IS NOT NULL 
	OR @database_name LIKE 'USCULCAASQL03%'
	PRINT @database_name
	BEGIN
		
		
		IF (@database_name LIKE 'USCULCAASQL03%')
			BEGIN
				EXEC script_B31_GPW_BSAIK_ECC_SPEND_CAT_LV3_INFO @database_name
			END
		ELSE IF (not @database_name LIKE '%SIE%') AND (not @database_name LIKE '%SEV%')
			BEGIN
				EXEC SP_REMOVE_TABLES_MASTER @database_name, 'B31_%'
				EXEC SP_EXEC_DYNAMIC @database_name, 'script_B31_BSAIK_ECC_SPEND_CAT_LV3_INFO'
			END
		ELSE
			BEGIN
				EXEC SP_REMOVE_TABLES_MASTER @database_name, 'B31_%'
				EXEC SP_EXEC_DYNAMIC @database_name, 'script_B31_ACDOCA_SPEND_CAT_LV3_INFO'
			END
	END

END

GO
