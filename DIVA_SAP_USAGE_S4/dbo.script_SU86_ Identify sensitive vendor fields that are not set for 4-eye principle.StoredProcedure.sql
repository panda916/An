USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU86_ Identify sensitive vendor fields that are not set for 4-eye principle]
AS
--DYNAMIC_SCRIPT_START

--Script objective: Identify sensitive vendor fields have been defined for vendor-related business partners 
--Step 1 Get the list of field group fields

EXEC SP_DROPTABLE SU86_01_XT_T055F_KOART_EQ_K

SELECT * ,
IIF(T055F_KOART='K','Vendor','Customer') AS ZF_T055F_KOART_DESC
INTO  SU86_01_XT_T055F_KOART_EQ_K
FROM A_T055F
WHERE T055F_KOART='K'

--Rename the fields
EXEC SP_RENAME_FIELD 'SU86_01_','SU86_01_XT_T055F_KOART_EQ_K'


GO
