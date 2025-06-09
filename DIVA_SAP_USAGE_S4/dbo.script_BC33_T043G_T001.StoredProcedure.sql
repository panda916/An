USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_BC33_T043G_T001]
AS
--DYNAMIC_SCRIPT_START

--Script objective: Create cube for Tolerances for Groups of Customers/Vendors 

--Get the information about Tolerances for Groups of Customers/Vendors 
--Add the name of company code

EXEC SP_DROPTABLE 'BC33_01_IT_T043G_T001'

SELECT A_T043G.*,T001_BUKRS,
	T001_BUTXT
INTO BC33_01_IT_T043G_T001
FROM A_T043G
RIGHT JOIN A_T001 
	ON T043G_BUKRS=T001_BUKRS
--Rename the fields
EXEC SP_RENAME_FIELD 'BC33_01_','BC33_01_IT_T043G_T001'


GO
