USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_B25_PTP_PURCHASE_REQUEST]
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


--Step 1/Create The Purchase request cubes from EBAN
--Add text description and other necessary fields
EXEC SP_DROPTABLE B25_01_IT_PURCHASE_REQUEST
SELECT DISTINCT
	A_EBAN.*,
	T161T_BATXT,
	T163Y_PSTYP ,
	T163Y_PTEXT,
	T16FT_FRGSX ,
	T024E_EKOTX ,
	T024_EKNAM  ,
	T001W_NAME1 ,
	B08_LFA1_NAME1 AS LFA1_NAME1,
	B08_LFA1_ERNAM AS LFA1_ERNAM,
	B08_LFA1_ERDAT AS LFA1_ERDAT,
	V_USERNAME_NAME_TEXT,
	CASE WHEN DBO.TRIM(EBAN_LOEKZ)='X' THEN 'Delete' ELSE '        'END AS 'ZF_EBAN_LOEKZF_DESC',
	CASE WHEN DBO.TRIM(EBAN_FRGZU)='' THEN 'Not validated or refused'
	WHEN DBO.TRIM(EBAN_FRGZU)='X' THEN 'One validation          '
	WHEN DBO.TRIM(EBAN_FRGZU)='XX' THEN 'Two validations         '
	WHEN DBO.TRIM(EBAN_FRGZU)='XXX' THEN 'Three validations         '
	ELSE 'Not defined' END AS 'ZF_EBAN_FRGZU_DESC',
	CASE WHEN DBO.TRIM(EBAN_LOEKZ)='X' THEN 'T' ELSE 'F' END AS 'ZF_PR_DELETED',
	CASE WHEN DBO.TRIM(EBAN_FRGZU)='X' THEN 'F' ELSE 'T' END AS 'ZF_PR_RELEASED',
	CONCAT(DBO.TRIM(EBAN_EBELN),DBO.TRIM(EBAN_EBELP)) AS 'ZF_KEY_JOIN_EBAN_TO_EKPO'
INTO B25_01_IT_PURCHASE_REQUEST
FROM A_EBAN
-- Add the item category description

LEFT JOIN A_T163Y 
	ON EBAN_PSTYP=T163Y_PSTYP

--Add the description of the purchasing document types

LEFT JOIN A_T161T 
	ON EBAN_BSART=T161T_BSART AND 
		EBAN_BSTYP=T161T_BSTYP

--Add the description of the release strategy

LEFT JOIN A_T16FT 
	ON EBAN_FRGGR=T16FT_FRGGR

--Add the description of the purchasing organisation

LEFT JOIN A_T024E 
	ON EBAN_EKORG=T024E_EKORG

-- Add the description of the purchasing group

LEFT JOIN A_T024 
	ON EBAN_EKGRP=T024_EKGRP



-- Add the account assignment category

LEFT JOIN A_T163I 
	ON EBAN_KNTTP=T163I_KNTTP

--Add supplier informations

LEFT JOIN B08_02_IT_PTP_SMD 
	ON B08_EKKO_LIFNR=EBAN_LIFNR

--Add name of the user who create the purchase requests

LEFT JOIN A_V_USERNAME 
	ON EBAN_ERNAM=V_USERNAME_BNAME


-- Add the description of the plant code
--Limit down PR by get only the plants which relate to the company code
 JOIN
 (
	SELECT A_T001W.*
	FROM A_T001W
	JOIN 
		(
			SELECT * FROM A_T001K
			INNER JOIN AM_COMPANY_CODE
			ON T001K_BUKRS=COMPANY_CODE
		) AS A
	ON T001W_BWKEY=A.T001K_BWKEY
)AS B	ON EBAN_WERKS=B.T001W_WERKS

--Step 2 Rename the fields of the tables
EXEC SP_RENAME_FIELD 'B25_','B25_01_IT_PURCHASE_REQUEST'







GO
