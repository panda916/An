USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROCEDURE [dbo].[script_B09_SS01_SPE]
WITH EXECUTE AS CALLER
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
			,@ZV_LIMIT nvarchar(max)		    = (SELECT [GLOBALS_VALUE] FROM [AM_GLOBALS] WHERE [GLOBALS_PARAMETER] = 'ZV_LIMIT')
			,@errormsg NVARCHAR(MAX)
			
DECLARE @dateformat varchar(3)
SET @dateformat   = (SELECT dbo.get_param('dateformat'))
SET DATEFORMAT @dateformat;
/* STEP 1 
--rename finance GL cube to to temporary table
*/
EXEC SP_DROPTABLE'B09_14_IT_PTP_POS'
SELECT * INTO B09_14_IT_PTP_POS FROM B09_13_IT_PTP_POS

--EXEC SP_RENAME 'B09_13_IT_PTP_POS', 'B09_14_IT_PTP_POS'

/* STEP 2 join the temporary table to SPE manual mappin table: AM_PROFIT_CENTER, AM_BPC, AM_COST_CENTER
*/

EXEC SP_DROPTABLE'B09_15_IT_PTP_POS'
SELECT B09_14_IT_PTP_POS.*
--Cost Center information added for SPE
		,COALESCE(NULLIF(AM_COST_CENTER.[COST_CENTER_L1],''),'Not Assigned')					AS	 [B09_COST_CENTER_L1]
		,COALESCE(NULLIF(AM_COST_CENTER.[COST_CENTER_L2],''),'Not Assigned')					AS	 [B09_COST_CENTER_L2]
		,COALESCE(NULLIF(AM_COST_CENTER.[COST_CENTER_L3],''),'Not Assigned')					AS	 [B09_COST_CENTER_L3]
		,COALESCE(NULLIF(AM_COST_CENTER.[COST_CENTER_L4],''),'Not Assigned')					AS	 [B09_COST_CENTER_L4]
		,COALESCE(NULLIF(AM_COST_CENTER.[COST_CENTER_L5],''),'Not Assigned')					AS	 [B09_COST_CENTER_L5]
		,COALESCE(NULLIF(AM_COST_CENTER.[COST_CENTER_L6],''),'Not Assigned')					AS	 [B09_COST_CENTER_L6]
		,COALESCE(NULLIF(AM_COST_CENTER.[COST_CENTER_L7],''),'Not Assigned')					AS	 [B09_COST_CENTER_L7]
		,COALESCE(NULLIF(AM_COST_CENTER.[COST_CENTER_L8],''),'Not Assigned')					AS	 [B09_COST_CENTER_L8]
		,COALESCE(NULLIF(AM_COST_CENTER.[COST_CENTER_L9],''),'Not Assigned')					AS	 [B09_COST_CENTER_L9]
		,COALESCE(NULLIF(AM_COST_CENTER.[COST_CENTER_L10],''),'Not Assigned')				AS	 [B09_COST_CENTER_L10]
		,COALESCE(NULLIF(AM_COST_CENTER.[COST_CENTER_L11],''),'Not Assigned')				AS	 [B09_COST_CENTER_L11]
		,COALESCE(NULLIF(AM_COST_CENTER.[COST_CENTER_L12],''),'Not Assigned')				AS	 [B09_COST_CENTER_L12]
		,COALESCE(NULLIF(AM_COST_CENTER.[COST_CENTER_L13],''),'Not Assigned')				AS	 [B09_COST_CENTER_L13]

		,COALESCE(NULLIF(AM_PROFIT_CENTER.[PROFIT_CENTER_DESC],''),'Not Assigned')		AS	 [B09_PROFIT_CENTER_DESC]
	  --Profit Center information added for SPE
		,COALESCE(NULLIF(AM_PROFIT_CENTER.[PROFIT_CENTER_L1],''),'Not Assigned')				AS	 [B09_PROFIT_CENTER_L1]
		,COALESCE(NULLIF(AM_PROFIT_CENTER.[PROFIT_CENTER_L2],''),'Not Assigned')				AS	 [B09_PROFIT_CENTER_L2]
		,COALESCE(NULLIF(AM_PROFIT_CENTER.[PROFIT_CENTER_L3],''),'Not Assigned') 				AS	 [B09_PROFIT_CENTER_L3]
		,COALESCE(NULLIF(AM_PROFIT_CENTER.[PROFIT_CENTER_L4],''),'Not Assigned') 				AS	 [B09_PROFIT_CENTER_L4]
		,COALESCE(NULLIF(AM_PROFIT_CENTER.[PROFIT_CENTER_L5],''),'Not Assigned') 				AS	 [B09_PROFIT_CENTER_L5]
		,COALESCE(NULLIF(AM_PROFIT_CENTER.[PROFIT_CENTER_L6],''),'Not Assigned') 				AS	 [B09_PROFIT_CENTER_L6]
		,COALESCE(NULLIF(AM_PROFIT_CENTER.[PROFIT_CENTER_L7],''),'Not Assigned') 				AS	 [B09_PROFIT_CENTER_L7]
		,COALESCE(NULLIF(AM_PROFIT_CENTER.[PROFIT_CENTER_L8],''),'Not Assigned') 				AS	 [B09_PROFIT_CENTER_L8]
		,COALESCE(NULLIF(AM_PROFIT_CENTER.[PROFIT_CENTER_L9],''),'Not Assigned') 				AS	 [B09_PROFIT_CENTER_L9]
		,COALESCE(NULLIF(AM_PROFIT_CENTER.[PROFIT_CENTER_L10],''),'Not Assigned') 				AS	 [B09_PROFIT_CENTER_L10]
		,COALESCE(NULLIF(AM_PROFIT_CENTER.[PROFIT_CENTER_L11],''),'Not Assigned') 				AS	 [B09_PROFIT_CENTER_L11]
		,COALESCE(NULLIF(AM_PROFIT_CENTER.[PROFIT_CENTER_L12],''),'Not Assigned') 				AS	 [B09_PROFIT_CENTER_L12]
		,COALESCE(NULLIF(AM_PROFIT_CENTER.[PROFIT_CENTER_L13],''),'Not Assigned') 				AS	 [B09_PROFIT_CENTER_L13]
		,COALESCE(NULLIF(AM_PROFIT_CENTER.[PROFIT_CENTER_L14],''),'Not Assigned') 				AS	 [B09_PROFIT_CENTER_L14]

		--Profit Center BPC information added for SPE
		,COALESCE(NULLIF(AM_BPC.[BPC_DESC],''),'Not Assigned')					AS	 [B09_BPC_TEXT]
		,COALESCE(NULLIF(AM_BPC.[BPC_L1],''),'Not Assigned')							AS	 [B09_BPC_L1]
		,COALESCE(NULLIF(AM_BPC.[BPC_L2],''),'Not Assigned')							AS	 [B09_BPC_L2]
		,COALESCE(NULLIF(AM_BPC.[BPC_L3],''),'Not Assigned')							AS	 [B09_BPC_L3]
		,COALESCE(NULLIF(AM_BPC.[BPC_L4],''),'Not Assigned')							AS	 [B09_BPC_L4]
		,COALESCE(NULLIF(AM_BPC.[BPC_L5],''),'Not Assigned')							AS	 [B09_BPC_L5]
		,COALESCE(NULLIF(AM_BPC.[BPC_L6],''),'Not Assigned')							AS	 [B09_BPC_L6]
		,COALESCE(NULLIF(AM_BPC.[BPC_L7],''),'Not Assigned')							AS	 [B09_BPC_L7]
		,COALESCE(NULLIF(AM_BPC.[BPC_L8],''),'Not Assigned')							AS	 [B09_BPC_L8]
		,COALESCE(NULLIF(AM_BPC.[BPC_L9],''),'Not Assigned')							AS	 [B09_BPC_L9]
		,COALESCE(NULLIF(AM_BPC.[BPC_L10],''),'Not Assigned')							AS	 [B09_BPC_L10]
		,COALESCE(NULLIF(AM_BPC.[BPC_L11],''),'Not Assigned')							AS	 [B09_BPC_L11]
		,COALESCE(NULLIF(AM_BPC.[BPC_L12],''),'Not Assigned')							AS	 [B09_BPC_L12]

INTO B09_15_IT_PTP_POS
FROM B09_14_IT_PTP_POS
   --Add information about the Profit Center ECC version
	LEFT JOIN AM_PROFIT_CENTER			
	ON  B09_ZF_EKKN_PRCTR_1ST_PROF_CENT = AM_PROFIT_CENTER.[PROFIT_CENTER_Consolidated]

   	--Add information about the Profit Center BPC version
    LEFT JOIN AM_BPC
    ON B09_ZF_EKKN_PRCTR_1ST_PROF_CENT = AM_BPC.[BPC_Consolidated]	
			  
    --Add information about the Cost Center 
    LEFT JOIN AM_COST_CENTER
    ON B09_ZF_EKKN_KOKRS_1ST_COST_CENT = AM_COST_CENTER.COST_CENTER_Consolidated
	AND B09_EKPO_BUKRS = AM_COST_CENTER.COST_CENTER_BUKRS
	AND B09_ZF_EKKN_PRCTR_1ST_PROF_CENT = AM_COST_CENTER.COST_CENTER_PRCTR   

EXEC SP_DROPTABLE'B09_13_IT_PTP_POS'
EXEC sp_rename 'B09_15_IT_PTP_POS', 'B09_13_IT_PTP_POS'
GO
