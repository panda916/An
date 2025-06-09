USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_BC24_TRANSPORT_SYSTEM]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START
EXEC SP_REMOVE_TABLES 'BC24_01_IT_E070_TRANSPORT_SYSTEM'

SELECT DISTINCT
	E070_TRKORR,
	E070_TRFUNCTION,
	E070_TRSTATUS,
	E070_TARSYSTEM,
	E070_KORRDEV,
	E070_AS4USER,
	E070_AS4DATE,
	E071_AS4POS,
	E071_PGMID,
	E071_OBJECT,
	E071_OBJ_NAME,
	E071_OBJFUNC,
	E071_LOCKFLAG,
	E071_GENNUM,
	E071_LANG,
	E071_ACTIVITY,
--	A_E07T.E07T_AS4TEXT,
	(
		CASE E071_OBJFUNC
			WHEN NULL THEN 'Normally: transport to the target system (see F1 help)'
			WHEN 'D' THEN 'The object was deleted (only functions with deleted objects)'
			WHEN 'M' THEN 'Delete and recreate on the database'
			WHEN 'K' THEN 'Object keys according to entries in the key list'
			WHEN 'A' THEN 'Key was archived using SARA'
		END
	) AS ZF_E071_OBJFUNC_DESCRIPTION,
	CASE E070_TRFUNCTION 
		WHEN  'K' THEN 'Workbench Request' 	
		WHEN  'W' THEN 'Customizing Request' 
		WHEN  'C' THEN 'Relocation of Objects Without Package Change'	
		WHEN  'O' THEN 'Relocation of Objects with Package Change'	
		WHEN  'E' THEN 'Relocation of Complete Package'	
		WHEN  'T' THEN 'Transport of Copies'	
		WHEN  'S' THEN 'Development/Correction'	
		WHEN  'R' THEN 'Repair'	
		WHEN  'X' THEN 'Unclassified Task'	
		WHEN  'Q' THEN 'Customizing Task'	
		WHEN  'G' THEN 'Piece List for CTS Project'	
		WHEN  'M' THEN 'Client Transport Request'	
		WHEN  'P' THEN 'Piece List for Upgrade'	
		WHEN  'D' THEN 'Piece List for Support Package'	
		WHEN  'F' THEN 'Piece List'	
		WHEN  'L' THEN 'Deletion transport' END AS ZF_E070_TRFUNCTION_DESCRIPTION,
	CASE E070_TRSTATUS 
		WHEN 'D' THEN 'Modifiable'
		WHEN 'L' THEN 'Modifiable, Protected'
		WHEN 'O' THEN 'Release Started'
		WHEN 'R' THEN 'Released'
		WHEN 'N' THEN 'Released (with Import Protection for Repaired Objects)' END AS ZF_E070_TRSTATUS_DESCRIPTION,
	CASE E070_KORRDEV
		WHEN 'CUST' THEN 'Client-specific Customizing'
		WHEN 'SYST' THEN 'Repository, cross-client objects' END AS ZF_E070_KORRDEV_DESCRIPTION
INTO BC24_01_IT_E070_TRANSPORT_SYSTEM
FROM A_E070
LEFT JOIN A_E071
ON E070_TRKORR = E071_TRKORR
--LEFT JOIN A_E07T
--ON E070_TRKORR = E07T_TRKORR AND A_E07T.E07T_LANGU IN ('E','EN')



GO
