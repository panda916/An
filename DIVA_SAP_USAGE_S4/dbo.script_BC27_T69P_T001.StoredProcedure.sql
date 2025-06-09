USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_BC27_T69P_T001]
AS
--DYNAMIC_SCRIPT_START
--Script objective:  Create the cube for Parameters, Invoice Verification information

--Step 1 Create the cube for Parameters, Invoice Verification information
--Add company information

EXEC SP_DROPTABLE BC27_01_IT_T69P_T001

SELECT A_T169P.*,
T001_BUTXT,
T001_LAND1,
T001_WAERS
INTO BC27_01_IT_T69P_T001
FROM A_T169P
--Add company information
LEFT JOIN A_T001 ON T169P_BUKRS=T001_BUKRS

--Rename the fields
EXEC SP_RENAME_FIELD 'BC27_01_','BC27_01_IT_T69P_T001'

GO
