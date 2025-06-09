USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[script_SU66_Identify authorization objects that have been switched off]
AS
--DYNAMIC_SCRIPT_START

--Script objective :Identify authorization objects that have been switched off

--Step 1 Get the data disabled authorization objects
EXEC SP_DROPTABLE SU66_01_RT_TOBJ_OFF_DISABLE_AUTH_OBJECT
SELECT *
INTO SU66_01_RT_TOBJ_OFF_DISABLE_AUTH_OBJECT
FROM A_TOBJ_OFF

--Rename the fields

EXEC SP_RENAME_FIELD 'SU66_01_','SU66_01_RT_TOBJ_OFF_DISABLE_AUTH_OBJECT'

GO
