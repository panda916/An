USE [DIVA_ASAP_TEST_DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[A_005H_IMPORT_COUNTRY_MAPPING]
--ALTER PROCEDURE [dbo].[A_005H_CREATE_COUNTRY_MAPPING]
WITH EXEC AS CALLER
AS
-- BEGIN


/* Initiate the log */  
--Create database log table if it does not exist
IF OBJECT_ID('LOG_SP_EXECUTION', 'U') IS NULL BEGIN CREATE TABLE [DBO].[LOG_SP_EXECUTION] ([DATABASE] NVARCHAR(MAX) NULL,[OBJECT] NVARCHAR(MAX) NULL,[OBJECT_TYPE] NVARCHAR(MAX) NULL,[USER] NVARCHAR(MAX) NULL,[DATE] DATE NULL,[TIME] TIME NULL,[DESCRIPTION] NVARCHAR(MAX) NULL,[TABLE] NVARCHAR(MAX),[ROWS] INT) END

--Log start of procedure
INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Procedure started',NULL,NULL

/* Initialize parameters from globals table */

     DECLARE 	 
			 @CURRENCY NVARCHAR(MAX)			= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'currency')
			,@DATE1 NVARCHAR(MAX)				= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date1')
			,@DATE2 NVARCHAR(MAX)				= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date2')
			,@DOWNLOADDATE NVARCHAR(MAX)		= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'downloaddate')
			,@DATEFORMAT VARCHAR(3)             = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'dateformat')
			,@EXCHANGERATETYPE NVARCHAR(MAX)	= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'exchangeratetype')
			,@LANGUAGE1 NVARCHAR(MAX)			= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language1')
			,@LANGUAGE2 NVARCHAR(MAX)			= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language2')
			,@YEAR NVARCHAR(MAX)				= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'year')
			,@ID NVARCHAR(MAX)					= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'id')
			,@LIMIT_RECORDS INT		            = CAST((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS') AS INT)


/*Test mode*/

SET ROWCOUNT @LIMIT_RECORDS
BEGIN

	EXEC SP_REMOVE_TABLES 'AM_COUNTRY_MAPPING'
	CREATE TABLE AM_COUNTRY_MAPPING
	(
		[COUNTRY_MAPPING_CODE] [varchar](50) NULL,
		[COUNTRY_MAPPING_DESC] [varchar](50) NULL
	)

	INSERT INTO AM_COUNTRY_MAPPING VALUES 
	('AD','AND') , 
	('AE','ARE') , 
	('AG','ATG') , 
	('AI','AIA') , 
	('AL','ALB') , 
	('AM','ARM') , 
	('AN','ANT') , 
	('AO','AGO') , 
	('AQ','ATA') , 
	('AR','ARG') , 
	('AS','ASM') , 
	('AT','AUT') , 
	('AU','AUS') , 
	('AW','ABW') , 
	('AX','ALA') , 
	('AZ','AZE') , 
	('BA','BIH') , 
	('BB','BRB') , 
	('BD','BGD') , 
	('BE','BEL') , 
	('BF','BFA') , 
	('BG','BGR') , 
	('BH','BHR') , 
	('BI','BDI') , 
	('BJ','BEN') , 
	('BL','BLM') , 
	('BM','BMU') , 
	('BN','BRN') , 
	('BO','BOL') , 
	('BR','BRA') , 
	('BS','BHS') , 
	('BT','BTN') , 
	('BV','BVT') , 
	('BW','BWA') , 
	('BY','BLR') , 
	('BZ','BLZ') , 
	('CA','CAN') , 
	('CC','CCK') , 
	('CD','COD') , 
	('CF','CAF') , 
	('CG','COG') , 
	('CH','CHE') , 
	('CI','CIV') , 
	('CK','COK') , 
	('CL','CHL') , 
	('CM','CMR') , 
	('CN','CHN') , 
	('CO','COL') , 
	('CR','CRI') , 
	('CU','CUB') , 
	('CV','CPV') , 
	('CX','CXR') , 
	('CY','CYP') , 
	('CZ','CZE') , 
	('DE','DEU') , 
	('DJ','DJI') , 
	('DK','DNK') , 
	('DM','DMA') , 
	('DO','DOM') , 
	('DZ','DZA') , 
	('EC','ECU') , 
	('EE','EST') , 
	('EG','EGY') , 
	('EH','ESH') , 
	('ER','ERI') , 
	('ES','ESP') , 
	('ET','ETH') , 
	('FI','FIN') , 
	('FJ','FJI') , 
	('FK','FLK') , 
	('FM','FSM') , 
	('FO','FRO') , 
	('FR','FRA') , 
	('GA','GAB') , 
	('GB','GBR') , 
	('GD','GRD') , 
	('GE','GEO') , 
	('GF','GUF') , 
	('GG','GGY') , 
	('GH','GHA') , 
	('GI','GIB') , 
	('GL','GRL') , 
	('GM','GMB') , 
	('GN','GIN') , 
	('GP','GLP') , 
	('GQ','GNQ') , 
	('GR','GRC') , 
	('GS','SGS') , 
	('GT','GTM') , 
	('GU','GUM') , 
	('GW','GNB') , 
	('GY','GUY') , 
	('HK','HKG') , 
	('HM','HMD') , 
	('HN','HND') , 
	('HR','HRV') , 
	('HT','HTI') , 
	('HU','HUN') , 
	('ID','IDN') , 
	('IE','IRL') , 
	('IL','ISR') , 
	('IM','IMN') , 
	('IN','IND') , 
	('IO','IOT') , 
	('IQ','IRQ') , 
	('IR','IRN') , 
	('IS','ISL') , 
	('IT','ITA') , 
	('JE','JEY') , 
	('JM','JAM') , 
	('JO','JOR') , 
	('JP','JPN') , 
	('KE','KEN') , 
	('KG','KGZ') , 
	('KH','KHM') , 
	('KI','KIR') , 
	('KM','COM') , 
	('KN','KNA') , 
	('KP','PRK') , 
	('KR','KOR') , 
	('KW','KWT') , 
	('KY','CYM') , 
	('KZ','KAZ') , 
	('LA','LAO') , 
	('LB','LBN') , 
	('LC','LCA') , 
	('LI','LIE') , 
	('LK','LKA') , 
	('LR','LBR') , 
	('LS','LSO') , 
	('LT','LTU') , 
	('LU','LUX') , 
	('LV','LVA') , 
	('LY','LBY') , 
	('MA','MAR') , 
	('MC','MCO') , 
	('MD','MDA') , 
	('ME','MNE') , 
	('MF','MAF') , 
	('MG','MDG') , 
	('MH','MHL') , 
	('MK','MKD') , 
	('ML','MLI') , 
	('MM','MMR') , 
	('MN','MNG') , 
	('MO','MAC') , 
	('MP','MNP') , 
	('MQ','MTQ') , 
	('MR','MRT') , 
	('MS','MSR') , 
	('MT','MLT') , 
	('MU','MUS') , 
	('MV','MDV') , 
	('MW','MWI') , 
	('MX','MEX') , 
	('MY','MYS') , 
	('MZ','MOZ') , 
	('NA','NAM') , 
	('NC','NCL') , 
	('NE','NER') , 
	('NF','NFK') , 
	('NG','NGA') , 
	('NI','NIC') , 
	('NL','NLD') , 
	('NO','NOR') , 
	('NP','NPL') , 
	('NR','NRU') , 
	('NU','NIU') , 
	('NZ','NZL') , 
	('OM','OMN') , 
	('PA','PAN') , 
	('PE','PER') , 
	('PF','PYF') , 
	('PG','PNG') , 
	('PH','PHL') , 
	('PK','PAK') , 
	('PL','POL') , 
	('PM','SPM') , 
	('PN','PCN') , 
	('PR','PRI') , 
	('PS','PSE') , 
	('PT','PRT') , 
	('PW','PLW') , 
	('PY','PRY') , 
	('QA','QAT') , 
	('RE','REU') , 
	('RO','ROU') , 
	('RS','SRB') , 
	('RU','RUS') , 
	('RW','RWA') , 
	('SA','SAU') , 
	('SB','SLB') , 
	('SC','SYC') , 
	('SD','SDN') , 
	('SE','SWE') , 
	('SG','SGP') , 
	('SH','SHN') , 
	('SI','SVN') , 
	('SJ','SJM') , 
	('SK','SVK') , 
	('SL','SLE') , 
	('SM','SMR') , 
	('SN','SEN') , 
	('SO','SOM') , 
	('SR','SUR') , 
	('SS','SSD') , 
	('ST','STP') , 
	('SV','SLV') , 
	('SY','SYR') , 
	('SZ','SWZ') , 
	('TC','TCA') , 
	('TD','TCD') , 
	('TF','ATF') , 
	('TG','TGO') , 
	('TH','THA') , 
	('TJ','TJK') , 
	('TK','TKL') , 
	('TL','TLS') , 
	('TM','TKM') , 
	('TN','TUN') , 
	('TO','TON') , 
	('TR','TUR') , 
	('TT','TTO') , 
	('TV','TUV') , 
	('TW','TWN') , 
	('TZ','TZA') , 
	('UA','UKR') , 
	('UG','UGA') , 
	('UM','UMI') , 
	('US','USA') , 
	('UY','URY') , 
	('UZ','UZB') , 
	('VA','VAT') , 
	('VC','VCT') , 
	('VE','VEN') , 
	('VG','VGB') , 
	('VI','VIR') , 
	('VN','VNM') , 
	('VU','VUT') , 
	('WF','WLF') , 
	('WS','WSM') , 
	('YE','YEM') , 
	('YT','MYT') , 
	('ZA','ZAF') , 
	('ZM','ZMB') , 
	('ZW','ZWE')  
END








GO
