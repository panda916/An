USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_BC38_REPOSRC_ADD_DESC]
AS
--DYNAMIC_SCRIPT_START

--Step 1 Get the information from Report Source Code table
--Add the description for Status and program type
EXEC SP_DROPTABLE BC38_01_IT_REPOSRC_ADD_DESC

SELECT 
	REPOSRC_PROGNAME,
	REPOSRC_R3STATE,
	REPOSRC_SQLX,
	REPOSRC_EDTX,
	REPOSRC_DBNA,
	REPOSRC_CLAS,
	REPOSRC_TYPE,
	REPOSRC_OCCURS,
	REPOSRC_SUBC,
	REPOSRC_APPL,
	REPOSRC_SECU,
	REPOSRC_CNAM,
	REPOSRC_CDAT,
	REPOSRC_VERN,
	REPOSRC_LEVL,
	REPOSRC_RSTAT,
	REPOSRC_RMAND,
	REPOSRC_RLOAD,
	REPOSRC_UNAM	,
	REPOSRC_UDAT	,
	REPOSRC_UTIME,
	REPOSRC_DATALG,
	REPOSRC_VARCL,
	REPOSRC_DBAPL,
	REPOSRC_FIXPT,
	REPOSRC_SSET	,
	REPOSRC_SDATE,
	REPOSRC_STIME,
	REPOSRC_IDATE,
	REPOSRC_ITIME,
	REPOSRC_LDBNAME,
	REPOSRC_UCCHECK,
	REPOSRC_MAXLINELN,
	CASE WHEN REPOSRC_R3STATE='A' THEN 'Active'
		WHEN REPOSRC_R3STATE='I' THEN 'Inactvie'
		END AS ZF_REPOSRC_R3STATE_DESC,
CASE 
	WHEN REPOSRC_SUBC ='1' THEN	'Executable program'
	WHEN REPOSRC_SUBC ='I' THEN	'INCLUDE program'
	WHEN REPOSRC_SUBC ='M' THEN	'Module Pool'
	WHEN REPOSRC_SUBC ='F' THEN	'Function group'
	WHEN REPOSRC_SUBC ='S' THEN	'Subroutine Pool'
	WHEN REPOSRC_SUBC ='J' THEN	'Interface pool'
	WHEN REPOSRC_SUBC ='K' THEN	'Class pool'
	WHEN REPOSRC_SUBC ='T' THEN	'Type Pool'
	WHEN REPOSRC_SUBC ='X' THEN	'Transformation (XSLT or ST Program)'
	WHEN REPOSRC_SUBC ='Q' THEN	'Database Procedure Proxy'
	ELSE 'Not found' END AS ZF_REPOSRC_SUBC_DESC,
CASE 
	WHEN REPOSRC_RSTAT='P' THEN 'SAP Standard Production Program'
	WHEN REPOSRC_RSTAT='K' THEN 'Customer Production Program'
	WHEN REPOSRC_RSTAT='S' THEN 'System Program'
	WHEN REPOSRC_RSTAT='T' THEN 'Test Program'
	ELSE 'Not found' END ZF_REPOSRC_RSTAT_DESC
INTO BC38_01_IT_REPOSRC_ADD_DESC
FROM A_REPOSRC


GO
