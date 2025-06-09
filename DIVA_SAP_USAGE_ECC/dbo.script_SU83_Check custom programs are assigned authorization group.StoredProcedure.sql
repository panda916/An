USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU83_Check custom programs are assigned authorization group]
AS
--DYNAMIC_SCRIPT_START

--Script objective: Check custom programs are assigned authorization group

--Step 1 Get the list of custom program
--Only get the active program and custom program

EXEC SP_DROPTABLE SU83_01_RT_REPOSRC_CUSTOM_PROGRAM

SELECT 
*
INTO SU83_01_RT_REPOSRC_CUSTOM_PROGRAM
FROM BC38_01_IT_REPOSRC_ADD_DESC
WHERE REPOSRC_R3STATE='A' AND REPOSRC_RSTAT='K'


--Rename the fields
EXEC SP_RENAME_FIELD 'SU83_01_','SU83_01_RT_REPOSRC_CUSTOM_PROGRAM'

GO
